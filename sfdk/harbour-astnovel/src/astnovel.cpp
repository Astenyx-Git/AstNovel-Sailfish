// astnovel.cpp — AstnStore: data layer exposed to QML (Qt 5.6, UTF-8 only)
#include "astnovel.h"

#include <QBuffer>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QImage>
#include <QJsonDocument>
#include <QJsonObject>
#include <QBuffer>
#include <QLinearGradient>
#include <QPainter>
#include <QPainterPath>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QTime>
#include <QUrl>
#include <QtGlobal>

#include <openssl/evp.h>
#include <openssl/rand.h>

// ---------------------------------------------------------------------------
// .astn format constants (see AstNovel ASTN v2.0 specification)
// ---------------------------------------------------------------------------
static const char *ASTN_MASTER_SECRET = "REDACTED_MASTER_SECRET";
static const quint32 ASTN_MAGIC_HEADER = 0x4153544EU;  // "ASTN" big-endian
static const quint32 ASTN_MAGIC_FOOTER = 0x4F56454CU;  // "OVEL" big-endian
static const int ASTN_SALT_SIZE = 16;
static const int ASTN_NONCE_SIZE = 12;
static const int ASTN_TAG_SIZE = 16;
static const int ASTN_KDF_ITERATIONS = 10000;

// World categories (original AstNovel categories)
static const char *ASTN_WORLD_CATS[] = {
    "GEOGRAPHY", "HISTORY", "MAGIC_SYSTEM", "SOCIAL_STRUCTURE", "OTHER"
};

static quint32 readUInt32BE(const QByteArray &data, int offset)
{
    if (offset < 0 || offset + 4 > data.size())
        return 0;
    const unsigned char *p = (const unsigned char *)data.constData() + offset;
    return (quint32(p[0]) << 24) | (quint32(p[1]) << 16) | (quint32(p[2]) << 8) | quint32(p[3]);
}

static void appendUInt32BE(QByteArray &out, quint32 value)
{
    out.append(char((value >> 24) & 0xFF));
    out.append(char((value >> 16) & 0xFF));
    out.append(char((value >> 8) & 0xFF));
    out.append(char(value & 0xFF));
}

static QByteArray astnDeriveKey(const QByteArray &salt)
{
    unsigned char key[32];
    if (PKCS5_PBKDF2_HMAC(ASTN_MASTER_SECRET, (int)qstrlen(ASTN_MASTER_SECRET),
                          (const unsigned char *)salt.constData(), salt.size(),
                          ASTN_KDF_ITERATIONS, EVP_sha256(), 32, key) != 1)
        return QByteArray();
    return QByteArray((const char *)key, 32);
}

// chunk = nonce(12) || ciphertext(N) || tag(16)
static QByteArray astnEncryptChunk(const QByteArray &key, const QByteArray &plain)
{
    if (key.isEmpty())
        return QByteArray();

    unsigned char nonce[ASTN_NONCE_SIZE];
    if (RAND_bytes(nonce, ASTN_NONCE_SIZE) != 1)
        return QByteArray();

    QByteArray out;
    out.reserve(ASTN_NONCE_SIZE + plain.size() + ASTN_TAG_SIZE);
    out.append((const char *)nonce, ASTN_NONCE_SIZE);
    out.resize(ASTN_NONCE_SIZE + plain.size() + ASTN_TAG_SIZE);

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx)
        return QByteArray();

    int len = 0, total = 0;
    bool ok = true;
    ok = ok && EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL) == 1;
    ok = ok && EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, ASTN_NONCE_SIZE, NULL) == 1;
    ok = ok && EVP_EncryptInit_ex(ctx, NULL, NULL,
                                  (const unsigned char *)key.constData(),
                                  (const unsigned char *)out.constData()) == 1;
    ok = ok && EVP_EncryptUpdate(ctx,
                                 (unsigned char *)out.data() + ASTN_NONCE_SIZE, &len,
                                 (const unsigned char *)plain.constData(), plain.size()) == 1;
    total = len;
    ok = ok && EVP_EncryptFinal_ex(ctx,
                                   (unsigned char *)out.data() + ASTN_NONCE_SIZE + total, &len) == 1;
    total += len;
    ok = ok && EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, ASTN_TAG_SIZE,
                                   out.data() + ASTN_NONCE_SIZE + total) == 1;
    EVP_CIPHER_CTX_free(ctx);
    if (!ok || total != plain.size())
        return QByteArray();
    return out;
}

static QByteArray astnDecryptChunk(const QByteArray &key, const QByteArray &chunk)
{
    if (key.isEmpty() || chunk.size() < ASTN_NONCE_SIZE + ASTN_TAG_SIZE)
        return QByteArray();

    QByteArray tag = chunk.right(ASTN_TAG_SIZE);
    int cipherLen = chunk.size() - ASTN_NONCE_SIZE - ASTN_TAG_SIZE;

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx)
        return QByteArray();

    QByteArray out(cipherLen, 0);
    int len = 0, total = 0;
    bool ok = true;
    ok = ok && EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL) == 1;
    ok = ok && EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, ASTN_NONCE_SIZE, NULL) == 1;
    ok = ok && EVP_DecryptInit_ex(ctx, NULL, NULL,
                                  (const unsigned char *)key.constData(),
                                  (const unsigned char *)chunk.constData()) == 1;
    ok = ok && EVP_DecryptUpdate(ctx,
                                 (unsigned char *)out.data(), &len,
                                 (const unsigned char *)chunk.constData() + ASTN_NONCE_SIZE,
                                 cipherLen) == 1;
    total = len;
    ok = ok && EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, ASTN_TAG_SIZE, tag.data()) == 1;
    ok = ok && EVP_DecryptFinal_ex(ctx, (unsigned char *)out.data() + total, &len) == 1;
    total += len;
    EVP_CIPHER_CTX_free(ctx);
    if (!ok)
        return QByteArray();
    out.resize(total);
    return out;
}

// Word counting per original AstNovel: CJK chars count 1 each,
// consecutive ASCII letters count as one word.
static int astnCountWords(const QString &text)
{
    int count = 0;
    bool inEnglishWord = false;
    for (int i = 0; i < text.length(); ++i) {
        const uint c = text.at(i).unicode();
        if (c >= 0x4E00 && c <= 0x9FFF) {
            count++;
            inEnglishWord = false;
        } else if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122)) {
            if (!inEnglishWord) {
                count++;
                inEnglishWord = true;
            }
        } else {
            inEnglishWord = false;
        }
    }
    return count;
}

// ---------------------------------------------------------------------------
// AstnStore
// ---------------------------------------------------------------------------
AstnStore::AstnStore(QObject *parent)
    : QObject(parent)
{
    qsrand((uint)QDateTime::currentMSecsSinceEpoch());
    m_baseDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(m_baseDir + "/books");
}

QString AstnStore::newId(const QString &prefix) const
{
    return prefix + QString::number(QDateTime::currentMSecsSinceEpoch())
            + "_" + QString::number(qrand() % 10000);
}

QVariantMap AstnStore::readJson(const QString &path) const
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return QVariantMap();
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject())
        return QVariantMap();
    return doc.object().toVariantMap();
}

bool AstnStore::writeJson(const QString &path, const QVariantMap &data) const
{
    QJsonDocument doc = QJsonDocument::fromVariant(data);
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    file.write(doc.toJson(QJsonDocument::Compact));
    return true;
}

QVariantList AstnStore::listJsonDir(const QString &dirPath, const QString &sortKey,
                                    bool newestFirst) const
{
    QVariantList result;
    QDir dir(dirPath);
    QStringList nameFilters;
    nameFilters << "*.json";
    QFileInfoList entries = dir.entryInfoList(nameFilters, QDir::Files, QDir::Name);
    for (int i = 0; i < entries.size(); ++i) {
        QVariantMap item = readJson(entries.at(i).absoluteFilePath());
        if (item.isEmpty())
            continue;
        result.append(item);
    }
    if (!sortKey.isEmpty()) {
        // insertion sort by numeric key (stable)
        for (int a = 1; a < result.size(); ++a) {
            const QVariant cur = result.at(a);
            const qint64 curKey = cur.toMap().value(sortKey).toLongLong();
            int b = a - 1;
            while (b >= 0) {
                const qint64 other = result.at(b).toMap().value(sortKey).toLongLong();
                if (newestFirst ? (other >= curKey) : (other <= curKey))
                    break;
                result[b + 1] = result.at(b);
                --b;
            }
            result[b + 1] = cur;
        }
    }
    return result;
}

QVariantMap AstnStore::touch(const QVariantMap &data) const
{
    QVariantMap out = data;
    out["updatedAt"] = QDateTime::currentMSecsSinceEpoch();
    return out;
}

QString AstnStore::bookDir(const QString &bookId) const
{
    return m_baseDir + "/books/" + bookId;
}

int AstnStore::chapterCount(const QString &bookId)
{
    QDir dir(bookDir(bookId) + "/chapters");
    return dir.entryList(QStringList() << "*.json", QDir::Files).size();
}

// ---------------------------------------------------------------------------
// Books
// ---------------------------------------------------------------------------
QVariantList AstnStore::books()
{
    // Books live in books/<id>/meta.json — iterate book directories
    QVariantList result;
    QDir booksDir(m_baseDir + "/books");
    const QStringList ids = booksDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
    for (int i = 0; i < ids.size(); ++i) {
        QVariantMap meta = readJson(m_baseDir + "/books/" + ids.at(i) + "/meta.json");
        if (meta.isEmpty())
            continue;
        meta["chapterCount"] = chapterCount(ids.at(i));
        result.append(meta);
    }
    // newest book first (stable insertion sort by updatedAt, descending)
    for (int a = 1; a < result.size(); ++a) {
        const QVariant cur = result.at(a);
        const qint64 curKey = cur.toMap().value("updatedAt").toLongLong();
        int b = a - 1;
        while (b >= 0 && result.at(b).toMap().value("updatedAt").toLongLong() < curKey) {
            result[b + 1] = result.at(b);
            --b;
        }
        result[b + 1] = cur;
    }
    return result;
}

QVariantMap AstnStore::book(const QString &bookId)
{
    QVariantMap meta = readJson(bookDir(bookId) + "/meta.json");
    if (meta.isEmpty())
        return QVariantMap();
    meta["chapterCount"] = chapterCount(bookId);
    return meta;
}

QString AstnStore::createBook(const QString &title, const QString &description)
{
    const QString id = newId("book_");
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    QVariantMap meta;
    meta["id"] = id;
    meta["title"] = title;
    meta["description"] = description;
    meta["coverDataUri"] = QString();
    meta["createdAt"] = now;
    meta["updatedAt"] = now;
    QDir().mkpath(bookDir(id) + "/chapters");
    QDir().mkpath(bookDir(id) + "/characters");
    for (int i = 0; i < 5; ++i)
        QDir().mkpath(bookDir(id) + "/world/" + QString::fromLatin1(ASTN_WORLD_CATS[i]));
    if (!writeJson(bookDir(id) + "/meta.json", meta))
        return QString();
    return id;
}

bool AstnStore::updateBook(const QString &bookId, const QString &title, const QString &description)
{
    QVariantMap meta = readJson(bookDir(bookId) + "/meta.json");
    if (meta.isEmpty())
        return false;
    meta["title"] = title;
    meta["description"] = description;
    return writeJson(bookDir(bookId) + "/meta.json", touch(meta));
}

bool AstnStore::deleteBook(const QString &bookId)
{
    QDir dir(bookDir(bookId));
    if (!dir.exists())
        return true;
    return dir.removeRecursively();
}

// ---------------------------------------------------------------------------
// Chapters
// ---------------------------------------------------------------------------
QVariantList AstnStore::chapters(const QString &bookId)
{
    return listJsonDir(bookDir(bookId) + "/chapters", "createdAt", false);
}

QVariantMap AstnStore::chapter(const QString &bookId, const QString &chapterId)
{
    return readJson(bookDir(bookId) + "/chapters/" + chapterId + ".json");
}

QString AstnStore::createChapter(const QString &bookId, const QString &title)
{
    const QString id = newId("ch_");
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    QVariantMap data;
    data["id"] = id;
    data["bookId"] = bookId;
    data["title"] = title;
    data["content"] = QString();
    data["wordCount"] = 0;
    data["createdAt"] = now;
    data["updatedAt"] = now;
    QDir().mkpath(bookDir(bookId) + "/chapters");
    if (!writeJson(bookDir(bookId) + "/chapters/" + id + ".json", data))
        return QString();
    return id;
}

bool AstnStore::saveChapter(const QString &bookId, const QString &chapterId, const QString &content)
{
    QVariantMap data = chapter(bookId, chapterId);
    if (data.isEmpty())
        return false;
    data["content"] = content;
    data["wordCount"] = astnCountWords(content);
    return writeJson(bookDir(bookId) + "/chapters/" + chapterId + ".json", touch(data));
}

bool AstnStore::deleteChapter(const QString &bookId, const QString &chapterId)
{
    return QFile::remove(bookDir(bookId) + "/chapters/" + chapterId + ".json");
}

// ---------------------------------------------------------------------------
// Characters (field set mirrors CharacterCard.ets)
// ---------------------------------------------------------------------------
static const char *kCharacterFields[] = {
    "name", "age", "gender", "height", "weight", "race",
    "appearance", "personality", "background", "notes"
};

static QVariantMap normalizedCharacter(const QVariantMap &data)
{
    QVariantMap out = data;
    // migrate legacy single-description entries
    if (!out.contains("personality") && out.contains("description"))
        out["personality"] = out.value("description").toString();
    for (unsigned i = 0; i < sizeof(kCharacterFields) / sizeof(kCharacterFields[0]); ++i) {
        const QString key = QString::fromLatin1(kCharacterFields[i]);
        if (!out.contains(key))
            out[key] = QString();
    }
    if (!out.contains("avatarDataUri"))
        out["avatarDataUri"] = QString();
    if (!out.contains("imageDataUris"))
        out["imageDataUris"] = QVariantList();
    return out;
}

// Scale an image file to a bounded width and encode as PNG data URI
static QString imageToDataUri(const QString &imagePath, int maxWidth)
{
    QString path = imagePath;
    if (path.startsWith("file://"))
        path = QUrl(path).toLocalFile();
    QImage img(path);
    if (img.isNull())
        return QString();
    if (img.width() > maxWidth)
        img = img.scaledToWidth(maxWidth, Qt::SmoothTransformation);
    QByteArray bytes;
    QBuffer buffer(&bytes);
    buffer.open(QIODevice::WriteOnly);
    img.save(&buffer, "PNG");
    return "data:image/png;base64," + bytes.toBase64();
}

QVariantList AstnStore::characters(const QString &bookId)
{
    QVariantList items = listJsonDir(bookDir(bookId) + "/characters", "createdAt", false);
    for (int i = 0; i < items.size(); ++i)
        items[i] = normalizedCharacter(items.at(i).toMap());
    return items;
}

QString AstnStore::createCharacter(const QString &bookId, const QVariantMap &fields)
{
    const QString id = newId("char_");
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    QVariantMap data;
    data["id"] = id;
    data["bookId"] = bookId;
    for (unsigned i = 0; i < sizeof(kCharacterFields) / sizeof(kCharacterFields[0]); ++i) {
        const QString key = QString::fromLatin1(kCharacterFields[i]);
        data[key] = fields.value(key).toString();
    }
    data["createdAt"] = now;
    data["updatedAt"] = now;
    QDir().mkpath(bookDir(bookId) + "/characters");
    if (!writeJson(bookDir(bookId) + "/characters/" + id + ".json", data))
        return QString();
    return id;
}

bool AstnStore::updateCharacter(const QString &bookId, const QString &characterId,
                                const QVariantMap &fields)
{
    QVariantMap data = readJson(bookDir(bookId) + "/characters/" + characterId + ".json");
    if (data.isEmpty())
        return false;
    for (unsigned i = 0; i < sizeof(kCharacterFields) / sizeof(kCharacterFields[0]); ++i) {
        const QString key = QString::fromLatin1(kCharacterFields[i]);
        data[key] = fields.value(key).toString();
    }
    return writeJson(bookDir(bookId) + "/characters/" + characterId + ".json", touch(data));
}

bool AstnStore::deleteCharacter(const QString &bookId, const QString &characterId)
{
    return QFile::remove(bookDir(bookId) + "/characters/" + characterId + ".json");
}

bool AstnStore::setCharacterAvatar(const QString &bookId, const QString &characterId,
                                   const QString &imagePath)
{
    const QString uri = imageToDataUri(imagePath, 512);
    if (uri.isEmpty())
        return false;
    QVariantMap data = readJson(bookDir(bookId) + "/characters/" + characterId + ".json");
    if (data.isEmpty())
        return false;
    data["avatarDataUri"] = uri;
    return writeJson(bookDir(bookId) + "/characters/" + characterId + ".json", touch(data));
}

bool AstnStore::clearCharacterAvatar(const QString &bookId, const QString &characterId)
{
    QVariantMap data = readJson(bookDir(bookId) + "/characters/" + characterId + ".json");
    if (data.isEmpty())
        return false;
    data["avatarDataUri"] = QString();
    return writeJson(bookDir(bookId) + "/characters/" + characterId + ".json", touch(data));
}

bool AstnStore::addCharacterImage(const QString &bookId, const QString &characterId,
                                  const QString &imagePath)
{
    const QString uri = imageToDataUri(imagePath, 720);
    if (uri.isEmpty())
        return false;
    QVariantMap data = readJson(bookDir(bookId) + "/characters/" + characterId + ".json");
    if (data.isEmpty())
        return false;
    QVariantList images = data.value("imageDataUris").toList();
    images.append(uri);
    data["imageDataUris"] = images;
    return writeJson(bookDir(bookId) + "/characters/" + characterId + ".json", touch(data));
}

bool AstnStore::removeCharacterImage(const QString &bookId, const QString &characterId, int index)
{
    QVariantMap data = readJson(bookDir(bookId) + "/characters/" + characterId + ".json");
    if (data.isEmpty())
        return false;
    QVariantList images = data.value("imageDataUris").toList();
    if (index < 0 || index >= images.size())
        return false;
    images.removeAt(index);
    data["imageDataUris"] = images;
    return writeJson(bookDir(bookId) + "/characters/" + characterId + ".json", touch(data));
}

// Rounded square thumbnail baked into the cache (fast texture on software GL)
QString AstnStore::avatarThumbPath(const QString &bookId, const QString &characterId, int size)
{
    QVariantMap data = readJson(bookDir(bookId) + "/characters/" + characterId + ".json");
    if (data.isEmpty() || size <= 0)
        return QString();
    const QString uri = data.value("avatarDataUri").toString();
    if (!uri.startsWith("data:image/") || !uri.contains(";base64,"))
        return QString();
    const QByteArray bytes = QByteArray::fromBase64(
                uri.mid(uri.indexOf(";base64,") + 8).toLatin1());
    QImage img = QImage::fromData(bytes);
    if (img.isNull())
        return QString();
    QImage square = img.scaled(size, size, Qt::KeepAspectRatioByExpanding,
                               Qt::SmoothTransformation);
    const QRect crop((square.width() - size) / 2, (square.height() - size) / 2, size, size);
    square = square.copy(crop);
    QImage out(size, size, QImage::Format_ARGB32_Premultiplied);
    out.fill(Qt::transparent);
    QPainter painter(&out);
    painter.setRenderHint(QPainter::Antialiasing);
    QPainterPath rounded;
    rounded.addRoundedRect(0, 0, size, size, size / 2, size / 2);
    painter.setClipPath(rounded);
    painter.drawImage(0, 0, square);
    painter.end();
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    QDir().mkpath(dir);
    const QString path = dir + QString("/avatar_%1_%2_%3.png")
            .arg(characterId).arg(size).arg(data.value("updatedAt").toLongLong());
    out.save(path, "PNG");
    return path;
}

QString AstnStore::saveCoverFrame(const QImage &img, const QString &name)
{
    if (img.isNull())
        return QString();
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    QDir().mkpath(dir);
    const QString path = dir + "/" + name;
    img.save(path, "PNG");
    return path;
}

int AstnStore::countWords(const QString &text) const
{
    return astnCountWords(text);
}

void AstnStore::saveAutosave(const QString &bookId, const QString &chapterId, const QString &content)
{
    const QString dir = bookDir(bookId) + "/autosave";
    QDir().mkpath(dir);
    QFile file(dir + "/" + chapterId + ".txt");
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        file.write(content.toUtf8());
}

QString AstnStore::loadAutosave(const QString &bookId, const QString &chapterId)
{
    QFile file(bookDir(bookId) + "/autosave/" + chapterId + ".txt");
    if (!file.open(QIODevice::ReadOnly))
        return QString();
    return QString::fromUtf8(file.readAll());
}

void AstnStore::clearAutosave(const QString &bookId, const QString &chapterId)
{
    QFile::remove(bookDir(bookId) + "/autosave/" + chapterId + ".txt");
}

QVariantList AstnStore::outlines(const QString &bookId)
{
    return listJsonDir(bookDir(bookId) + "/outlines", "order", false);
}

QString AstnStore::createOutline(const QString &bookId, const QString &parentId, int level,
                                 const QString &title)
{
    const QString id = newId("ot_");
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const QVariantList siblings = outlines(bookId);
    int maxOrder = -1;
    for (int i = 0; i < siblings.size(); ++i) {
        const QVariantMap o = siblings.at(i).toMap();
        if (o.value("parentId").toString() == parentId && o.value("order").toInt() > maxOrder)
            maxOrder = o.value("order").toInt();
    }
    QVariantMap data;
    data["id"] = id;
    data["bookId"] = bookId;
    data["parentId"] = parentId;
    data["level"] = level;
    data["title"] = title;
    data["content"] = QString();
    data["notes"] = QString();
    data["linkedChapterIds"] = QVariantList();
    data["linkedCharacterIds"] = QVariantList();
    data["linkedWorldEntryIds"] = QVariantList();
    data["order"] = maxOrder + 1;
    data["createdAt"] = now;
    data["updatedAt"] = now;
    QDir().mkpath(bookDir(bookId) + "/outlines");
    if (!writeJson(bookDir(bookId) + "/outlines/" + id + ".json", data))
        return QString();
    return id;
}

bool AstnStore::updateOutline(const QString &bookId, const QString &outlineId,
                              const QVariantMap &fields)
{
    QVariantMap data = readJson(bookDir(bookId) + "/outlines/" + outlineId + ".json");
    if (data.isEmpty())
        return false;
    static const char *kOutlineKeys[] = {"title", "content", "notes", "parentId", "level",
                                         "order", "linkedChapterIds", "linkedCharacterIds",
                                         "linkedWorldEntryIds"};
    for (unsigned i = 0; i < sizeof(kOutlineKeys) / sizeof(kOutlineKeys[0]); ++i) {
        const QString key = QString::fromLatin1(kOutlineKeys[i]);
        if (fields.contains(key))
            data[key] = fields.value(key);
    }
    return writeJson(bookDir(bookId) + "/outlines/" + outlineId + ".json", touch(data));
}

bool AstnStore::deleteOutline(const QString &bookId, const QString &outlineId)
{
    return QFile::remove(bookDir(bookId) + "/outlines/" + outlineId + ".json");
}

// Index-only read: does a book with the same title already exist?
QString AstnStore::importConflictBookId(const QString &path)
{
    QString filePath = path;
    if (filePath.startsWith("file://"))
        filePath = QUrl(filePath).toLocalFile();

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return QString();
    const QByteArray data = file.readAll();
    if (data.size() < 28)
        return QString();
    if (readUInt32BE(data, 0) != ASTN_MAGIC_HEADER)
        return QString();

    const QByteArray salt = data.mid(4, ASTN_SALT_SIZE);
    const QByteArray key = astnDeriveKey(salt);
    if (key.isEmpty())
        return QString();
    const quint32 indexLength = readUInt32BE(data, 20);
    if (indexLength == 0 || int(24 + indexLength + 4) > data.size())
        return QString();
    const QByteArray indexJson = astnDecryptChunk(key, data.mid(24, (int)indexLength));
    if (indexJson.isEmpty())
        return QString();

    QJsonParseError err;
    QJsonDocument indexDoc = QJsonDocument::fromJson(indexJson, &err);
    if (err.error != QJsonParseError::NoError || !indexDoc.isObject())
        return QString();
    const QString title = indexDoc.object().toVariantMap()
            .value("metadata").toMap().value("title").toString();
    if (title.isEmpty())
        return QString();
    const QVariantList allBooks = books();
    for (int i = 0; i < allBooks.size(); ++i) {
        if (allBooks.at(i).toMap().value("title").toString() == title)
            return allBooks.at(i).toMap().value("id").toString();
    }
    return QString();
}

// ---------------------------------------------------------------------------
// World setting entries (field templates mirror WorldSetting.ets)
// ---------------------------------------------------------------------------
QStringList AstnStore::worldFields(const QString &category)
{
    if (category == "GEOGRAPHY")
        return QStringList() << "地区名称" << "地形地貌" << "气候特征" << "自然资源"
                             << "居民分布" << "与相邻地区关系" << "备注";
    if (category == "HISTORY")
        return QStringList() << "事件名称" << "发生时间" << "关键人物" << "事件经过"
                             << "影响与后果" << "与其他事件关联" << "备注";
    if (category == "MAGIC_SYSTEM")
        return QStringList() << "体系名称" << "能量来源" << "施法规则" << "限制条件"
                             << "与其他体系的关系" << "备注";
    if (category == "SOCIAL_STRUCTURE")
        return QStringList() << "组织名称" << "组织类型" << "层级结构" << "权力分布"
                             << "核心价值观" << "与其他组织关系" << "备注";
    return QStringList() << "条目标题" << "详细描述" << "备注";
}

// --- UI language preference (persisted in ~/.config) -----------------------
QString AstnStore::uiLanguage() const
{
    QSettings s(QStringLiteral("harbour-astnovel"), QStringLiteral("harbour-astnovel"));
    return s.value(QStringLiteral("ui/language")).toString();
}

void AstnStore::setUiLanguage(const QString &lang)
{
    QSettings s(QStringLiteral("harbour-astnovel"), QStringLiteral("harbour-astnovel"));
    s.setValue(QStringLiteral("ui/language"), lang);
    s.sync();
    emit uiLanguageChanged();
}

// --- Dark mode preference (persisted in ~/.config) -------------------------
bool AstnStore::darkMode() const
{
    QSettings s(QStringLiteral("harbour-astnovel"), QStringLiteral("harbour-astnovel"));
    return s.value(QStringLiteral("ui/darkMode"), false).toBool();
}

void AstnStore::setDarkMode(bool dark)
{
    QSettings s(QStringLiteral("harbour-astnovel"), QStringLiteral("harbour-astnovel"));
    s.setValue(QStringLiteral("ui/darkMode"), dark);
    s.sync();
    emit darkModeChanged();
}

static QString worldTitleFromFields(const QVariantMap &fields)
{
    // first non-empty value excluding the 备注 field (like getSummary)
    QList<QString> keys = fields.keys();
    for (int i = 0; i < keys.size(); ++i) {
        if (keys.at(i) == "备注")
            continue;
        const QString v = fields.value(keys.at(i)).toString().trimmed();
        if (!v.isEmpty())
            return v;
    }
    return QString();
}

QVariantList AstnStore::worldEntries(const QString &bookId, const QString &category)
{
    QVariantList items = listJsonDir(bookDir(bookId) + "/world/" + category, "createdAt", false);
    const QStringList fieldsTemplate = worldFields(category);
    for (int i = 0; i < items.size(); ++i) {
        QVariantMap w = items.at(i).toMap();
        if (!w.contains("fields")) {
            // migrate legacy flat entries (title/content) into the template
            QVariantMap f;
            if (!fieldsTemplate.isEmpty())
                f[fieldsTemplate.first()] = w.value("title").toString();
            if (!fieldsTemplate.isEmpty())
                f[fieldsTemplate.last()] = w.value("content").toString();
            w["fields"] = f;
            w["notes"] = QString();
        }
        items[i] = w;
    }
    return items;
}

QString AstnStore::createWorldEntry(const QString &bookId, const QString &category,
                                    const QVariantMap &fields, const QString &notes)
{
    const QString id = newId("ws_");
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    QVariantMap data;
    data["id"] = id;
    data["bookId"] = bookId;
    data["category"] = category;
    data["title"] = worldTitleFromFields(fields);
    data["fields"] = fields;
    data["notes"] = notes;
    data["createdAt"] = now;
    data["updatedAt"] = now;
    QDir().mkpath(bookDir(bookId) + "/world/" + category);
    if (!writeJson(bookDir(bookId) + "/world/" + category + "/" + id + ".json", data))
        return QString();
    return id;
}

bool AstnStore::updateWorldEntry(const QString &bookId, const QString &category,
                                 const QString &entryId, const QVariantMap &fields,
                                 const QString &notes)
{
    QVariantMap data = readJson(bookDir(bookId) + "/world/" + category + "/" + entryId + ".json");
    if (data.isEmpty())
        return false;
    data["fields"] = fields;
    data["notes"] = notes;
    data["title"] = worldTitleFromFields(fields);
    return writeJson(bookDir(bookId) + "/world/" + category + "/" + entryId + ".json",
                     touch(data));
}

bool AstnStore::deleteWorldEntry(const QString &bookId, const QString &category,
                                 const QString &entryId)
{
    return QFile::remove(bookDir(bookId) + "/world/" + category + "/" + entryId + ".json");
}

// ---------------------------------------------------------------------------
// Cover image
// ---------------------------------------------------------------------------
bool AstnStore::setBookCoverFromImage(const QString &bookId, const QString &imagePath)
{
    QString path = imagePath;
    if (path.startsWith("file://"))
        path = QUrl(path).toLocalFile();
    QImage image(path);
    if (image.isNull())
        return false;
    if (image.width() > 640)
        image = image.scaledToWidth(640, Qt::SmoothTransformation);

    QByteArray bytes;
    QBuffer buffer(&bytes);
    buffer.open(QIODevice::WriteOnly);
    if (!image.save(&buffer, "PNG"))
        return false;

    QVariantMap meta = readJson(bookDir(bookId) + "/meta.json");
    if (meta.isEmpty())
        return false;
    meta["coverDataUri"] = "data:image/png;base64," + bytes.toBase64();
    return writeJson(bookDir(bookId) + "/meta.json", touch(meta));
}

bool AstnStore::clearBookCover(const QString &bookId)
{
    QVariantMap meta = readJson(bookDir(bookId) + "/meta.json");
    if (meta.isEmpty())
        return false;
    meta["coverDataUri"] = QString();
    return writeJson(bookDir(bookId) + "/meta.json", touch(meta));
}

// ---------------------------------------------------------------------------
// .astn export / import
// ---------------------------------------------------------------------------
static QString sanitizeFileName(const QString &name)
{
    QString out = name;
    const QString illegal = "\\/:*?\"<>|";
    for (int i = 0; i < illegal.length(); ++i)
        out.replace(illegal.at(i), QChar('_'));
    out = out.trimmed();
    if (out.isEmpty())
        out = "book";
    return out;
}

// Strip markdown markers for TXT export (mirrors original ExportService)
static QString stripMarkdownText(const QString &text)
{
    QString out = text;
    out.remove(QRegularExpression("\\*\\*"));
    out.remove(QRegularExpression("\\*"));
    out.remove(QRegularExpression("^#{1,3}\\s", QRegularExpression::MultilineOption));
    out.remove(QRegularExpression("^[-*]\\s", QRegularExpression::MultilineOption));
    return out;
}

QString AstnStore::gradientCoverPath(int index, qreal width, qreal height, qreal radius,
                                     const QString &topColor, const QString &bottomColor)
{
    const int w = qRound(width);
    const int h = qRound(height);
    const int r = qRound(radius);
    if (w <= 0 || h <= 0 || r <= 0 || index < 0 || index >= 8)
        return QString();

    // Cache file per (gradient, size, radius, colors) — baked once, drawn as
    // a plain texture afterwards (fast on CPU-rendered Qt Quick scenes).
    const QString key = QString("grad%1_%2x%3_r%4_%5_%6")
            .arg(index).arg(w).arg(h).arg(r)
            .arg(topColor.mid(1)).arg(bottomColor.mid(1));
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    if (dir.isEmpty())
        return QString();
    QDir().mkpath(dir);
    const QString path = dir + "/" + key + ".png";
    // Regenerate if missing OR corrupt (e.g. truncated by an abrupt shutdown)
    QFileInfo cacheInfo(path);
    if (!cacheInfo.exists() || cacheInfo.size() <= 0) {
        QFile::remove(path);
        QImage img(w, h, QImage::Format_ARGB32_Premultiplied);
        img.fill(Qt::transparent);
        QPainter painter(&img);
        painter.setRenderHint(QPainter::Antialiasing);
        QPainterPath roundedPath;
        roundedPath.addRoundedRect(0, 0, w, h, r, r);
        painter.setClipPath(roundedPath);
        // 135° diagonal gradient (original CSS linear-gradient(135deg,...))
        QLinearGradient grad(0, 0, w, h);
        grad.setColorAt(0.0, QColor(topColor));
        grad.setColorAt(1.0, QColor(bottomColor));
        painter.fillRect(0, 0, w, h, grad);
        painter.end();
        if (!img.save(path, "PNG"))
            return QString();
    }
    return path;
}

QString AstnStore::exportBookAs(const QString &bookId, const QString &format,
                                const QString &outputDir)
{
    if (format == "astn")
        return exportBookToAstn(bookId, outputDir);

    const QVariantMap b = book(bookId);
    if (b.isEmpty())
        return QString();

    QString content;
    if (format == "md") {
        content += "# " + b.value("title").toString() + "\n\n";
        const QString desc = b.value("description").toString();
        if (!desc.isEmpty())
            content += desc + "\n\n";
        content += "---\n\n";
        const QVariantList chs = chapters(bookId);
        for (int i = 0; i < chs.size(); ++i) {
            const QVariantMap c = chs.at(i).toMap();
            content += "## " + c.value("title").toString() + "\n\n";
            content += c.value("content").toString() + "\n\n";
        }
    } else { // txt
        content += b.value("title").toString() + "\n\n";
        const QString desc = b.value("description").toString();
        if (!desc.isEmpty())
            content += desc + "\n\n";
        const QVariantList chs = chapters(bookId);
        for (int i = 0; i < chs.size(); ++i) {
            const QVariantMap c = chs.at(i).toMap();
            content += c.value("title").toString() + "\n\n";
            content += stripMarkdownText(c.value("content").toString()) + "\n\n";
        }
    }

    QString dir = outputDir;
    if (dir.startsWith("file://"))
        dir = QUrl(dir).toLocalFile();
    if (dir.isEmpty())
        dir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (!QDir().mkpath(dir))
        return QString();
    const QString ext = format == "md" ? ".md" : ".txt";
    const QString path = dir + "/" + sanitizeFileName(b.value("title").toString()) + ext;
    QFile outFile(path);
    if (!outFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return QString();
    const QByteArray utf8 = content.toUtf8();
    if (outFile.write(utf8) != utf8.size())
        return QString();
    return path;
}

QString AstnStore::exportBookToAstn(const QString &bookId, const QString &outputDir)
{
    const QVariantMap b = book(bookId);
    if (b.isEmpty())
        return QString();

    struct Payload {
        QString id;
        QString type;
        QString name;
        QByteArray data;
    };
    QList<Payload> assets;

    // Cover image (data URI -> raw PNG bytes)
    QString coverAssetId;
    const QString coverUri = b.value("coverDataUri").toString();
    if (coverUri.startsWith("data:image/") && coverUri.contains(";base64,")) {
        const int base64Start = coverUri.indexOf(";base64,") + 8;
        const QByteArray imageBytes = QByteArray::fromBase64(
                    coverUri.mid(base64Start).toLatin1());
        if (!imageBytes.isEmpty()) {
            coverAssetId = "asset_img_cover_" + bookId;
            Payload cover;
            cover.id = coverAssetId;
            cover.type = "image";
            cover.name = "cover";
            cover.data = imageBytes;
            assets.append(cover);
        }
    }

    // Chapters
    const QVariantList chapterItems = chapters(bookId);
    for (int i = 0; i < chapterItems.size(); ++i) {
        const QVariantMap c = chapterItems.at(i).toMap();
        QVariantMap obj;
        obj["id"] = c.value("id");
        obj["bookId"] = bookId;
        obj["title"] = c.value("title");
        obj["content"] = c.value("content");
        obj["order"] = i;
        obj["wordCount"] = c.value("wordCount");
        obj["createdAt"] = c.value("createdAt");
        obj["updatedAt"] = c.value("updatedAt");
        Payload p;
        p.id = "asset_chap_" + c.value("id").toString();
        p.type = "chapter";
        p.name = c.value("title").toString();
        p.data = QJsonDocument::fromVariant(obj).toJson(QJsonDocument::Compact);
        assets.append(p);
    }

    // Outline nodes (full OutlineNode JSON, mirrors the original outline asset)
    const QVariantList outlineItems = outlines(bookId);
    for (int i = 0; i < outlineItems.size(); ++i) {
        const QVariantMap o = outlineItems.at(i).toMap();
        QVariantMap obj;
        obj["id"] = o.value("id");
        obj["bookId"] = bookId;
        obj["parentId"] = o.value("parentId");
        obj["level"] = o.value("level");
        obj["title"] = o.value("title");
        obj["content"] = o.value("content");
        obj["notes"] = o.value("notes");
        obj["linkedChapterIds"] = o.value("linkedChapterIds");
        obj["linkedCharacterIds"] = o.value("linkedCharacterIds");
        obj["linkedWorldEntryIds"] = o.value("linkedWorldEntryIds");
        obj["order"] = o.value("order");
        obj["createdAt"] = o.value("createdAt");
        obj["updatedAt"] = o.value("updatedAt");
        Payload p;
        p.id = "asset_ot_" + o.value("id").toString();
        p.type = "outline";
        p.name = o.value("title").toString();
        p.data = QJsonDocument::fromVariant(obj).toJson(QJsonDocument::Compact);
        assets.append(p);
    }

    // World entries (structured fields, mirrors WorldSettingEntry serialization)
    for (int ci = 0; ci < 5; ++ci) {
        const QString category = QString::fromLatin1(ASTN_WORLD_CATS[ci]);
        const QVariantList items = worldEntries(bookId, category);
        for (int i = 0; i < items.size(); ++i) {
            const QVariantMap w = items.at(i).toMap();
            QVariantMap obj;
            obj["id"] = w.value("id");
            obj["bookId"] = bookId;
            obj["category"] = category;
            obj["title"] = w.value("title");
            obj["fields"] = w.value("fields");
            obj["notes"] = w.value("notes");
            obj["createdAt"] = w.value("createdAt");
            obj["updatedAt"] = w.value("updatedAt");
            Payload p;
            p.id = "asset_ws_" + w.value("id").toString();
            p.type = "worldview";
            p.name = w.value("title").toString();
            p.data = QJsonDocument::fromVariant(obj).toJson(QJsonDocument::Compact);
            assets.append(p);
        }
    }

    // Characters (full field set, mirrors AstnFileWriter's character JSON)
    const QVariantList characterItems = characters(bookId);
    for (int i = 0; i < characterItems.size(); ++i) {
        const QVariantMap c = characterItems.at(i).toMap();
        const QString cid = c.value("id").toString();
        const QString avatarUri = c.value("avatarDataUri").toString();
        const bool hasAvatar = avatarUri.startsWith("data:image/") && avatarUri.contains(";base64,");
        const QVariantList extraImages = c.value("imageDataUris").toList();
        int extraCount = 0;
        for (int j = 0; j < extraImages.size(); ++j) {
            const QString extraUri = extraImages.at(j).toString();
            if (!extraUri.startsWith("data:image/") || !extraUri.contains(";base64,"))
                continue;
            const QByteArray imageBytes = QByteArray::fromBase64(
                        extraUri.mid(extraUri.indexOf(";base64,") + 8).toLatin1());
            if (imageBytes.isEmpty())
                continue;
            Payload a;
            a.id = "asset_img_" + cid + "_" + QString::number(j);
            a.type = "image";
            a.name = "image_" + cid + "_" + QString::number(j);
            a.data = imageBytes;
            assets.append(a);
            ++extraCount;
        }
        QVariantMap obj;
        obj["id"] = c.value("id");
        obj["bookId"] = bookId;
        obj["name"] = c.value("name");
        obj["age"] = c.value("age");
        obj["gender"] = c.value("gender");
        obj["height"] = c.value("height");
        obj["weight"] = c.value("weight");
        obj["race"] = c.value("race");
        obj["appearance"] = c.value("appearance");
        obj["personality"] = c.value("personality");
        obj["background"] = c.value("background");
        obj["notes"] = c.value("notes");
        obj["avatarImageCount"] = hasAvatar ? 1 : 0;
        obj["extraImageCount"] = extraCount;
        obj["createdAt"] = c.value("createdAt");
        obj["updatedAt"] = c.value("updatedAt");
        Payload p;
        p.id = "asset_char_" + cid;
        p.type = "character";
        const QString displayName = c.value("name").toString().trimmed();
        p.name = displayName.isEmpty() ? QString::fromUtf8("未命名角色") : displayName;
        p.data = QJsonDocument::fromVariant(obj).toJson(QJsonDocument::Compact);
        assets.append(p);

        // avatar carried as an independent IMAGE asset (like the original)
        if (hasAvatar) {
            const QByteArray imageBytes = QByteArray::fromBase64(
                        avatarUri.mid(avatarUri.indexOf(";base64,") + 8).toLatin1());
            if (!imageBytes.isEmpty()) {
                Payload a;
                a.id = "asset_img_avatar_" + cid;
                a.type = "image";
                a.name = "avatar_" + cid;
                a.data = imageBytes;
                assets.append(a);
            }
        }
    }

    // Encrypt every asset chunk
    QByteArray salt(ASTN_SALT_SIZE, 0);
    if (RAND_bytes((unsigned char *)salt.data(), ASTN_SALT_SIZE) != 1)
        return QString();
    const QByteArray key = astnDeriveKey(salt);
    if (key.isEmpty())
        return QString();

    QList<QByteArray> chunks;
    for (int i = 0; i < assets.size(); ++i) {
        const QByteArray chunk = astnEncryptChunk(key, assets.at(i).data);
        if (chunk.isEmpty())
            return QString();
        chunks.append(chunk);
    }

    // Build index; iterate until encrypted index size is stable
    QByteArray encryptedIndex;
    qint64 firstAssetOffset = 0;
    for (int round = 0; round < 4; ++round) {
        QVariantMap index;
        index["version"] = "2.0";
        QVariantMap meta;
        meta["title"] = b.value("title");
        meta["description"] = b.value("description");
        meta["cover_asset_id"] = coverAssetId;
        index["metadata"] = meta;
        QVariantList assetEntries;
        qint64 offset = firstAssetOffset;
        for (int i = 0; i < assets.size(); ++i) {
            QVariantMap entry;
            entry["id"] = assets.at(i).id;
            entry["type"] = assets.at(i).type;
            entry["name"] = assets.at(i).name;
            entry["offset"] = offset;
            entry["length"] = (qint64)chunks.at(i).size();
            assetEntries.append(entry);
            offset += chunks.at(i).size();
        }
        index["assets"] = assetEntries;
        const QByteArray indexJson = QJsonDocument::fromVariant(index).toJson(QJsonDocument::Compact);
        encryptedIndex = astnEncryptChunk(key, indexJson);
        if (encryptedIndex.isEmpty())
            return QString();
        const qint64 newFirstAssetOffset = 24 + encryptedIndex.size();
        if (newFirstAssetOffset == firstAssetOffset)
            break;
        firstAssetOffset = newFirstAssetOffset;
    }

    // Assemble file
    QByteArray file;
    appendUInt32BE(file, ASTN_MAGIC_HEADER);
    file.append(salt);
    appendUInt32BE(file, (quint32)encryptedIndex.size());
    file.append(encryptedIndex);
    for (int i = 0; i < chunks.size(); ++i)
        file.append(chunks.at(i));
    appendUInt32BE(file, ASTN_MAGIC_FOOTER);

    QString dir = outputDir;
    if (dir.startsWith("file://"))
        dir = QUrl(dir).toLocalFile();
    if (dir.isEmpty())
        dir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (!QDir().mkpath(dir))
        return QString();
    const QString path = dir + "/" + sanitizeFileName(b.value("title").toString()) + ".astn";
    QFile outFile(path);
    if (!outFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return QString();
    if (outFile.write(file) != file.size())
        return QString();
    return path;
}

QString AstnStore::importBookFromAstn(const QString &path, const QString &mode)
{
    QString filePath = path;
    if (filePath.startsWith("file://"))
        filePath = QUrl(filePath).toLocalFile();

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return QString();
    const QByteArray data = file.readAll();
    if (data.size() < 28)
        return QString();
    if (readUInt32BE(data, 0) != ASTN_MAGIC_HEADER)
        return QString();
    if (readUInt32BE(data, data.size() - 4) != ASTN_MAGIC_FOOTER)
        return QString();

    const QByteArray salt = data.mid(4, ASTN_SALT_SIZE);
    const QByteArray key = astnDeriveKey(salt);
    if (key.isEmpty())
        return QString();
    const quint32 indexLength = readUInt32BE(data, 20);
    if (indexLength == 0 || int(24 + indexLength + 4) > data.size())
        return QString();
    const QByteArray indexJson = astnDecryptChunk(key, data.mid(24, (int)indexLength));
    if (indexJson.isEmpty())
        return QString();

    QJsonParseError err;
    QJsonDocument indexDoc = QJsonDocument::fromJson(indexJson, &err);
    if (err.error != QJsonParseError::NoError || !indexDoc.isObject())
        return QString();
    const QVariantMap index = indexDoc.object().toVariantMap();
    const QVariantMap meta = index.value("metadata").toMap();
    const QVariantList assetEntries = index.value("assets").toList();

    // Create the book shell ("copy" mode appends the original's import suffix)
    QString bookTitle = meta.value("title").toString();
    if (mode == "copy")
        bookTitle += " (导入)";
    const QString newBookId = createBook(bookTitle, meta.value("description").toString());
    if (newBookId.isEmpty())
        return QString();

    // First pass: collect character IMAGE assets (they may precede their character)
    QMap<QString, QByteArray> avatarImages;                 // avatar_<cid> -> bytes
    QMap<QString, QMap<int, QByteArray> > extraImagesByChar; // image_<cid>_<j>
    for (int i = 0; i < assetEntries.size(); ++i) {
        const QVariantMap entry = assetEntries.at(i).toMap();
        if (entry.value("type").toString() != "image")
            continue;
        const QString name = entry.value("name").toString();
        const qint64 offset = entry.value("offset").toLongLong();
        const qint64 length = entry.value("length").toLongLong();
        if (offset < 0 || length <= 0 || offset + length > data.size())
            continue;
        const QByteArray plain = astnDecryptChunk(key, data.mid((int)offset, (int)length));
        if (plain.isEmpty())
            continue;
        if (name.startsWith("avatar_")) {
            avatarImages.insert(name, plain);
        } else if (name.startsWith("image_")) {
            const int sep = name.lastIndexOf('_');
            if (sep > 6) {
                const QString cid = name.mid(6, sep - 6);
                const int idx = name.mid(sep + 1).toInt();
                extraImagesByChar[cid][idx] = plain;
            }
        }
    }

    for (int i = 0; i < assetEntries.size(); ++i) {
        const QVariantMap entry = assetEntries.at(i).toMap();
        const qint64 offset = entry.value("offset").toLongLong();
        const qint64 length = entry.value("length").toLongLong();
        const QString type = entry.value("type").toString();
        const QString assetId = entry.value("id").toString();
        if (offset < 0 || length <= 0 || offset + length > data.size())
            continue;
        const QByteArray plain = astnDecryptChunk(key, data.mid((int)offset, (int)length));
        if (plain.isEmpty())
            continue;

        if (type == "image" && assetId == meta.value("cover_asset_id").toString()) {
            QVariantMap bookMeta = readJson(bookDir(newBookId) + "/meta.json");
            bookMeta["coverDataUri"] = "data:image/png;base64," + plain.toBase64();
            writeJson(bookDir(newBookId) + "/meta.json", bookMeta);
            continue;
        }
        if (type != "chapter" && type != "worldview" && type != "character"
                && type != "outline")
            continue;

        QJsonParseError objErr;
        QJsonDocument objDoc = QJsonDocument::fromJson(plain, &objErr);
        if (objErr.error != QJsonParseError::NoError || !objDoc.isObject())
            continue;
        const QVariantMap obj = objDoc.object().toVariantMap();
        const QString objId = obj.value("id").toString();
        if (objId.isEmpty())
            continue;

        const qint64 createdAt = obj.value("createdAt").toLongLong();
        const qint64 updatedAt = obj.value("updatedAt").toLongLong();

        if (type == "chapter") {
            QVariantMap chapterData;
            chapterData["id"] = objId;
            chapterData["bookId"] = newBookId;
            chapterData["title"] = obj.value("title");
            chapterData["content"] = obj.value("content");
            chapterData["wordCount"] = obj.value("wordCount");
            chapterData["createdAt"] = createdAt;
            chapterData["updatedAt"] = updatedAt;
            QDir().mkpath(bookDir(newBookId) + "/chapters");
            writeJson(bookDir(newBookId) + "/chapters/" + objId + ".json", chapterData);
        } else if (type == "worldview") {
            QString category = obj.value("category").toString();
            bool known = false;
            for (int ci = 0; ci < 5; ++ci) {
                if (category == QString::fromLatin1(ASTN_WORLD_CATS[ci]))
                    known = true;
            }
            if (!known)
                category = "OTHER";
            QVariantMap entryData;
            entryData["id"] = objId;
            entryData["bookId"] = newBookId;
            entryData["category"] = category;
            entryData["title"] = obj.value("title");
            entryData["fields"] = obj.value("fields");
            entryData["notes"] = obj.value("notes");
            entryData["createdAt"] = createdAt;
            entryData["updatedAt"] = updatedAt;
            QDir().mkpath(bookDir(newBookId) + "/world/" + category);
            writeJson(bookDir(newBookId) + "/world/" + category + "/" + objId + ".json",
                      entryData);
        } else if (type == "outline") {
            QVariantMap outlineData;
            outlineData["id"] = objId;
            outlineData["bookId"] = newBookId;
            outlineData["parentId"] = obj.value("parentId");
            outlineData["level"] = obj.value("level");
            outlineData["title"] = obj.value("title");
            outlineData["content"] = obj.value("content");
            outlineData["notes"] = obj.value("notes");
            outlineData["linkedChapterIds"] = obj.value("linkedChapterIds");
            outlineData["linkedCharacterIds"] = obj.value("linkedCharacterIds");
            outlineData["linkedWorldEntryIds"] = obj.value("linkedWorldEntryIds");
            outlineData["order"] = obj.value("order");
            outlineData["createdAt"] = createdAt;
            outlineData["updatedAt"] = updatedAt;
            QDir().mkpath(bookDir(newBookId) + "/outlines");
            writeJson(bookDir(newBookId) + "/outlines/" + objId + ".json", outlineData);
        } else { // character
            QVariantMap characterData;
            characterData["id"] = objId;
            characterData["bookId"] = newBookId;
            characterData["name"] = obj.value("name");
            characterData["age"] = obj.value("age");
            characterData["gender"] = obj.value("gender");
            characterData["height"] = obj.value("height");
            characterData["weight"] = obj.value("weight");
            characterData["race"] = obj.value("race");
            characterData["appearance"] = obj.value("appearance");
            characterData["personality"] = obj.value("personality");
            characterData["background"] = obj.value("background");
            characterData["notes"] = obj.value("notes");
            const QString avatarName = "avatar_" + objId;
            if (avatarImages.contains(avatarName))
                characterData["avatarDataUri"] = "data:image/png;base64,"
                        + avatarImages.value(avatarName).toBase64();
            if (extraImagesByChar.contains(objId)) {
                QVariantList extraUris;
                const QMap<int, QByteArray> extras = extraImagesByChar.value(objId);
                for (QMap<int, QByteArray>::const_iterator it = extras.constBegin();
                     it != extras.constEnd(); ++it) {
                    extraUris.append("data:image/png;base64," + it.value().toBase64());
                }
                characterData["imageDataUris"] = extraUris;
            }
            characterData["createdAt"] = createdAt;
            characterData["updatedAt"] = updatedAt;
            QDir().mkpath(bookDir(newBookId) + "/characters");
            writeJson(bookDir(newBookId) + "/characters/" + objId + ".json", characterData);
        }
    }

    return newBookId;
}
