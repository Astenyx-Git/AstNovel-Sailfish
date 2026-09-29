# ASTN v2.0 容器格式规范

> 本文档描述 AstNovel 使用的 `.astn` 加密容器格式，以及本 Sailfish OS 移植版（`harbour-astnovel`）的实现方式。
> **以 `sfdk/harbour-astnovel/src/astnovel.cpp` 为实现准绳**；与原版 HarmonyOS 应用（ArkTS）共享容器结构。
> 最近核对：两代密钥方案落地后（见 §4）。

---

## 1. 适用范围与版本

| 项目 | 值 |
|---|---|
| 格式版本（索引内 `version` 字段） | `"2.0"` |
| 容器类型 | 单文件、全量、加密二进制包（整本书） |
| 加密 | 每区块 AES-256-GCM；密钥由 PBKDF2-HMAC-SHA256 派生 |
| 字符编码 | 全部 JSON 资产为 UTF-8（紧凑格式，无多余空白） |
| 字节序 | 所有整数字段为**大端序（Big-Endian）** |
| 最小合法文件 | 28 字节（头 4 + 盐 16 + 索引长度 4 + 页脚 4，索引长度可为 0） |

`.astn` 只用于**导出与导入**。设备本地存储是**未加密的 JSON**（见 §13）。

---

## 2. 容器二进制布局

整个文件是一段连续字节流：

```
偏移      长度        字段
──────────────────────────────────────────────────────────────
0         4 字节      头魔数      UInt32 BE  0x4153544E  ("ASTN")
4         16 字节     盐          PBKDF2 盐（随机）
20        4 字节      索引区块长度 UInt32 BE  加密索引 chunk 的字节数
24        IL 字节     加密索引区块  见 §6
24+IL     变长        资产区块 1 … N   顺序由索引表给出
末-4      4 字节      页脚魔数    UInt32 BE  0x4F56454C  ("OVEL")
```

- 索引区块长度 `IL` 必须为正，且 `24 + IL + 4 ≤ 文件长度`
- 头/页脚魔数任一不匹配即拒绝导入（实现中页脚校验见 §12）
- 资产区块的实际顺序**不保证**与索引表顺序一致；实现须按索引表中的 `offset` / `length` 定位

### 常量表

| 常量 | 值 | 说明 |
|---|---|---|
| `ASTN_MAGIC_HEADER` | `0x4153544E` | "ASTN" BE |
| `ASTN_MAGIC_FOOTER` | `0x4F56454C` | "OVEL" BE |
| `ASTN_SALT_SIZE` | 16 | PBKDF2 盐字节数 |
| `ASTN_NONCE_SIZE` | 12 | AES-GCM IV 字节数 |
| `ASTN_AUTH_TAG_SIZE` | 16 | GCM 认证标签字节数（128 位） |
| `ASTN_KDF_ITERATIONS` | 10000 | PBKDF2 迭代数（**由原版锁定，两代相同**） |
| 密钥长度 | 32 字节 | PBKDF2 输出，AES-256 |

---

## 3. 区块（chunk）格式

每个加密区块（索引与每个资产）内部布局相同：

```
[12 字节: Nonce/IV][N 字节: 密文][16 字节: 认证标签]
```

**加密**：
1. `RAND_bytes` 生成 12 字节随机 nonce（每区块独立）
2. AES-256-GCM 加密，标签长度 16
3. 输出顺序：`nonce || ciphertext || tag`

**解密**：
1. 从区块尾部取 16 字节作为 tag，头部取 12 字节作为 nonce
2. 传入 OpenSSL 前需拼成 `ciphertext || tag`
3. `EVP_DecryptFinal_ex` 校验 tag；失败即数据损坏或被篡改 → 拒绝

> 跨语言注意：Web Crypto API 返回的是 `ciphertext || authTag`（需在 `length-16` 处切分）；C/OpenSSL 需在解密前手动拼接。Qt 代码中此转换位于 `astnDecryptChunk`。

---

## 4. 密钥派生与两代方案 ★

### 4.1 派生函数

```
Key = PBKDF2-HMAC-SHA256(
    password   = 主密钥（字节串，见下表）
    salt       = 文件偏移 4 处的 16 字节
    iterations = 10000
    keyLength  = 32 字节
)
```

两代使用**完全相同的派生结构**，仅 `password` 不同。

### 4.2 两代主密钥

| 代 | 标识 | 来源 | 用途 |
|---|---|---|---|
| **GEN1（legacy）** | `ASTN_MASTER_SECRET` | 原版 HarmonyOS 应用内嵌的旧密钥 | **仅读取**旧容器（原版应用导出、本移植版历史版本导出） |
| **GEN2** | `ASTN_GEN2_SECRET` | 十六进制摘要，由仓库外的构建配置注入 | **本移植版写入**新容器；也可读取本代容器 |

### 4.3 注入机制（仓库不含任何密钥）

两代密钥均不进入版本库，通过以下方式之一在**构建期**注入（宏 `ASTN_MASTER_SECRET` / `ASTN_GEN2_SECRET`）：

- 推荐：本地 `sfdk/harbour-astnovel/mastersecret.pri`（已 gitignore），内容形如
  ```qmake
  DEFINES += ASTN_MASTER_SECRET=\"<legacy secret>\"
  DEFINES += ASTN_GEN2_SECRET=\"<gen2 hex digest>\"
  ```
- 或在能传递到 qmake 的环境中导出 `ASTN_MASTER_SECRET` / `ASTN_GEN2_SECRET`（`.pro` 优先读环境变量，缺省时才包含 `.pri`）

**运行期覆盖**：同名的 `ASTN_MASTER_SECRET` / `ASTN_GEN2_SECRET` 环境变量优先于编译期内建值。

**失败关闭语义**：

| 缺失 | 后果 |
|---|---|
| GEN2 密钥 | 导出失败（不产出文件）；GEN2 容器读正常 |
| GEN1 密钥 | 旧容器读失败；GEN2 容器读写正常 |

### 4.4 世代自动判定（读取流程核心）

容器内**没有**世代标识字段；判定依赖 GCM 认证——错误密钥必然 tag 校验失败：

```
读取文件:
  解析头 → 取 salt 与索引区块
  ① key1 = PBKDF2(GEN1, salt); 若非空且索引区块解密通过 tag 校验 → 使用 key1
  ② 否则 key2 = PBKDF2(GEN2, salt); 若非空且通过 → 使用 key2
  ③ 否则 → 拒绝（损坏 / 非本格式文件）
```

- 每打开一个文件最多两次 PBKDF2（各 10,000 迭代），毫秒级开销
- 命中任一代后，**该文件内所有资产区块**均使用同一把密钥解密
- 导入时若后续需要重写文件（修改并保存），将使用 **GEN2 + 新盐** 全量重加密

### 4.5 安全边界声明（务必如实理解）

- 两代主密钥都会被编译进客户端二进制，可被提取（实测：`rpm2cpio | cpio | strings` 一秒可得）。本方案**不是**面向持有者的保密边界
- 实际提供的保护：①无本应用则文件不可读 ②GCM 认证防篡改/防损坏 ③每文件随机盐使文件间不共享密钥、相同内容两次导出密文不同
- 真实的保密性提升需要每用户口令 + Argon2id 或平台密钥库，代价是破坏互通与体验——本项目不采用
- 旧容器（GEN1）的密钥已随原版应用公开，无法追溯加固；GEN2 的收益仅是**与原版生态解耦**

---

## 5. 索引表（解密后的 JSON）

```json
{
  "version": "2.0",
  "metadata": {
    "title": "书名",
    "description": "简介",
    "cover_asset_id": "asset_img_cover_book_1700000000000_1234"
  },
  "assets": [
    { "id": "asset_chap_ch_1700000000000_5678",
      "type": "chapter",
      "name": "第一章",
      "offset": 1234,
      "length": 567 }
  ]
}
```

- `assets[].id` 为**资产 ID**（`asset_{type_abbrev}_{内部 id}`）
- `offset` / `length` 为文件内绝对字节位置 / 长度
- `metadata.cover_asset_id` 指向封面 `image` 资产（无封面为空串）
- JSON 资产统一使用紧凑格式（`QJsonDocument::Compact`）

---

## 6. 资产类型与数据结构

除 `image` 外，全部资产为 UTF-8 JSON；`image` 为原始图片字节。

### 6.1 资产 ID 约定

| 类型 | 类型码 | 资产 ID 模式 | 示例 |
|---|---|---|---|
| 章节 | `chapter` | `asset_chap_{章节 id}` | `asset_chap_ch_1700000000000_5678` |
| 大纲 | `outline` | `asset_ot_{大纲 id}` | `asset_ot_ot_1700000000000_1234` |
| 世界观 | `worldview` | `asset_ws_{条目 id}` | `asset_ws_ws_1700000000000_3456` |
| 角色 | `character` | `asset_char_{角色 id}` | `asset_char_char_1700000000000_9012` |
| 封面 | `image` | `asset_img_cover_{书籍 id}` | — |
| 角色头像 | `image` | `asset_img_avatar_{角色 id}` | — |
| 角色图集 | `image` | `asset_img_{角色 id}_{序号}` | `asset_img_char_…_0` |

### 6.2 章节（`chapter`）

```json
{ "id": "ch_…", "bookId": "…", "title": "…", "content": "…",
  "order": 0, "wordCount": 1234, "createdAt": 1700000000000, "updatedAt": 1700000000000 }
```

`content` 为正文，可含 Markdown（粗体/斜体/标题/列表）。

### 6.3 大纲（`outline`）

```json
{ "id": "ot_…", "bookId": "…", "parentId": "", "level": 0,
  "title": "…", "content": "…", "notes": "…",
  "linkedChapterIds": [], "linkedCharacterIds": [], "linkedWorldEntryIds": [],
  "order": 0, "createdAt": …, "updatedAt": … }
```

- `parentId` 为**空串**= 根节点；否则为**内部 id**（`obj.id`，非 `asset.id`）
- `level`：`0`=卷 `1`=章 `2`=节，最深 3 级
- 重建树：先建 `obj.id → asset.id` 映射，再按 `parentId` 连接；孤儿节点挂到最近前序同级节点或提升为根

### 6.4 世界观（`worldview`）

```json
{ "id": "ws_…", "bookId": "…", "category": "GEOGRAPHY",
  "title": "…", "fields": { "地区名称": "…", "地形地貌": "…" }, "notes": "",
  "createdAt": …, "updatedAt": … }
```

**分类与字段模板**（`fields` 的键为中文字符串，与原版一致；实现见 `AstnStore::worldFields()`）：

| `category` | 显示名 | 字段模板 |
|---|---|---|
| `GEOGRAPHY` | 地理 | 地区名称、地形地貌、气候特征、自然资源、居民分布、与相邻地区关系、备注 |
| `HISTORY` | 历史 | 事件名称、发生时间、关键人物、事件经过、影响与后果、与其他事件关联、备注 |
| `MAGIC_SYSTEM` | 力量体系 | 体系名称、能量来源、施法规则、限制条件、与其他体系的关系、备注 |
| `SOCIAL_STRUCTURE` | 社会结构 | 组织名称、组织类型、层级结构、权力分布、核心价值观、与其他组织关系、备注 |
| `OTHER` | 其他 | 条目标题、详细描述、备注 |

> 显示本地化：`fields` 的键恒为中文（数据兼容），UI 渲染时经 `AstnStyle.worldFieldLabel(key)` 映射为当前界面语言。

### 6.5 角色（`character`）

```json
{ "id": "char_…", "bookId": "…", "name": "…", "age": "25", "gender": "男",
  "height": "180cm", "weight": "75kg", "race": "人类",
  "appearance": "…", "personality": "…", "background": "…", "notes": "…",
  "avatarImageCount": 1, "extraImageCount": 2,
  "createdAt": …, "updatedAt": … }
```

- 十个人物字段均为字符串（不限定数值/单位）
- 头像与图集**不在**本 JSON 内，而是独立的 `image` 资产；角色 JSON 仅记录数量。导入时实现按 `avatar_{角色id}` / `image_{角色id}_{序号}` 的资产 `name` 匹配回填

### 6.6 图片（`image`）

原始二进制，按文件头判定 MIME：

| 字节签名 | MIME |
|---|---|
| `89 50 4E 47` | `image/png` |
| `FF D8` | `image/jpeg` |
| `47 49 46` | `image/gif` |
| `52 49 46 46` | `image/webp` |
| （兜底） | `image/jpeg` |

---

## 7. 内部 ID 生成约定

```
{idPrefix}{Unix 毫秒时间戳}_{0..9999 随机数}
```

前缀：`book_`、`ch_`、`ot_`、`char_`、`ws_`

> 本移植版用 `qsrand(毫秒时间戳)` 播种的 `qrand() % 10000` 取随机段（与原版 `Math.random()` 同量级，仅防碰撞用，**非安全随机数**）。若需强唯一性应改用 `QUuid`/`QRandomGenerator`——尚未实施。

---

## 8. 字数统计

与原版一致：

- CJK 统一表意文字（U+4E00–U+9FFF）：每字计 1
- 连续 ASCII 字母（A–Z、a–z）：整段计 1
- 其他字符：仅中断英文单词状态，不计数
- 已知边界：假名、扩展 B 区汉字、标点均不计数（与原版行为一致）

---

## 9. 写入（导出）流程

```
1. 收集资产（按 §6 顺序）：封面 → 章节 → 大纲 → 世界观(5 类) → 角色(+头像/图集 image)
2. RAND_bytes 生成 16 字节新盐
3. key = PBKDF2(GEN2, 盐)                ← 只写 GEN2
4. 逐资产加密：nonce||密文||tag
5. 迭代构建索引（至多 4 轮）：
     偏移 = 24 + len(加密索引) + Σ 已确定资产块长
     写 JSON → 加密 → 若首资产偏移稳定则停止，否则以新偏移重算
6. 组装：头 || 盐 || 索引长度(BE) || 加密索引 || 各资产块 || 页脚
7. 落盘：<输出目录>/<书名净化>.astn（输出目录为空时取 DocumentsLocation）
```

- 索引迭代上限 4 轮（原版为 5 轮；实践中 1–2 轮即收敛）
- 每区块 nonce 独立随机；同一密钥下随机 96 位 nonce 在 ~2³² 区块内无碰撞风险
- 修改旧容器后重写：生成**新盐**并用 GEN2 全量重加密（不得复用旧盐或旧 nonce）

---

## 10. 读取（导入）流程

```
1. 读全文件；长度 < 28 → 拒绝
2. 校验头魔数、页脚魔数
3. 取盐与索引长度，边界检查
4. 世代判定（§4.4）得到密钥；两代皆失败 → 拒绝
5. 解密索引 → 解析 JSON
6. 创建新书籍（"copy" 模式在书名后加 " (导入)" 后缀）
7. 预扫描 image 资产：按 name 归入 avatar_{角色id} / image_{角色id}_{序号}
   （图片资产可能排在角色之前，故需预扫描）
8. 主循环按类型还原：
     image   且 id == metadata.cover_asset_id → 写入书籍封面
     chapter / worldview / character / outline → 写入对应 JSON 文件
     未知 type → 跳过
```

实现约定：

- 导入后**沿用资产内部 id**（`obj.id`），但 `bookId` 一律指向新建书籍
- 原始 `parentId`、关联 id 数组原样保留
- 世界观 `category` 非法值回退为 `OTHER`
- 现有实现导入时**不校验**文件名标题与索引 metadata 的一致性（`importConflictBookId` 单独用于同名冲突检测）

---

## 11. 同名冲突处理

`.astn` 导入前按书名检测冲突，三种选择：

| 选择 | 行为 |
|---|---|
| 创建副本 | 书名追加 ` (导入)` 后缀，导入为新书 |
| 覆盖 | 替换既有书籍内容 |
| 跳过 | 放弃本次导入 |

---

## 12. 校验规则汇总

| 检查 | 失败处理 |
|---|---|
| 文件长度 ≥ 28 | 拒绝 |
| 头魔数 = "ASTN" | 拒绝 |
| 页脚魔数 = "OVEL"（导入路径校验） | 拒绝 |
| `24 + IL + 4 ≤ 文件长度`，`IL > 0` | 拒绝 |
| 索引区块 GCM tag 校验（两代各试一次） | 拒绝 |
| 索引 JSON 可解析且为对象 | 拒绝 |
| 资产 JSON 可解析且为对象 | 跳过该资产 |
| 资产 `offset`/`length` 越界 | 跳过该资产 |
| 资产 `id` 为空 | 跳过该资产 |
| 未知资产 `type` | 跳过 |

---

## 13. 设备端存储布局（未加密）

`.astn` 的加密只作用于导出文件；**设备本地数据是明文 JSON**：

```
~/.local/share/harbour-astnovel/        (QStandardPaths::AppDataLocation)
└── books/
    └── {bookId}/
        ├── meta.json                   书籍元信息（含 coverDataUri: data:image/png;base64,…）
        ├── chapters/{chapterId}.json
        ├── characters/{characterId}.json   （头像/图集以 base64 data URI 内嵌）
        ├── outlines/{outlineId}.json
        ├── world/{CATEGORY}/{entryId}.json
        └── autosave/{chapterId}.txt        30 秒自动保存的崩溃恢复副本
```

界面偏好另存于 `~/.config/harbour-astnovel/harbour-astnovel.conf`（QSettings：`ui/language`、`ui/darkMode`）。

> 如需本地也加密，属于与本规范正交的改动（需增加设备级密钥管理），当前未实施。

---

## 14. 其他导出格式

| 格式 | 说明 |
|---|---|
| `.txt` | 去除 Markdown 标记的纯文本 |
| `.md` | 保留 Markdown 原文 |
| `.astn` | 本规范容器（GEN2） |

---

## 15. 兼容矩阵

| 容器来源 | 本移植版读取 | 本移植版写出 | 原版应用读取 |
|---|---|---|---|
| 原版应用（GEN1） | ✅ | — | ✅ |
| 本移植版历史版本（GEN1） | ✅ | — | ✅ |
| 本移植版新版（GEN2） | ✅ | ✅ | ❌（只认 GEN1） |

> 旧容器一旦在本应用中被修改保存，即以 GEN2 + 新盐重写，此后仅本应用可读。

---

## 16. 与原版实现的已知差异

| 项 | 原版（ArkTS） | 本移植版（C++/Qt） |
|---|---|---|
| 写入密钥 | GEN1 | **GEN2**（GEN1 仅读） |
| 索引迭代上限 | 5 轮 | 4 轮 |
| 随机数源 | `Math.random()` | `qrand()`（毫秒播种） |
| 世代判定 | 单一密钥 | 双代试解（GCM 判定） |
| 本地存储 | — | 明文 JSON（见 §13） |

---

## 17. English summary of the two-generation scheme

`.astn` keeps its original container layout, chunk format (nonce‖ciphertext‖tag, AES-256-GCM) and PBKDF2-HMAC-SHA256 (10,000 iterations) derivation. The only change in this port is the **PBKDF2 password**:

- **GEN1** — the legacy secret embedded in the original HarmonyOS app. Used **only for reading** old containers.
- **GEN2** — a hex digest chosen out-of-band, **never stored in the repository**; the port writes only GEN2 containers.

Neither secret is committed: both are injected at build time via a gitignored `mastersecret.pri` (`DEFINES += ASTN_MASTER_SECRET=…` / `ASTN_GEN2_SECRET=…`) or via the same-named environment variables, and can be overridden at runtime. A missing secret fails closed for that generation only.

Containers carry no generation marker, so readers try GEN1 first and then GEN2; AES-GCM tag verification decides which one authenticates. Practical consequences: files exported by the original app (and by older builds of this port) still import; new exports do **not** open in the original app. Both secrets are extractable from the client binary — treat them as interop configuration, not a confidentiality boundary; the per-file random salt and GCM authentication provide the actual protection.

---

Copyright (c) 2026 Astenyx. 本文档随 `harbour-astnovel` 源码分发。
