#include "WorldSettingManager.h"
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QDateTime>

WorldSettingManager& WorldSettingManager::instance() {
    static WorldSettingManager instance;
    return instance;
}

WorldSettingManager::WorldSettingManager() {
}

WorldSettingManager::~WorldSettingManager() {
}

bool WorldSettingManager::createEntry(const QString& bookId, const QString& category, const QString& title, const QString& content, QString& entryId) {
    entryId = "entry_" + QString::number(QDateTime::currentMSecsSinceEpoch());

    QJsonObject entryJson;
    entryJson["id"] = entryId;
    entryJson["category"] = category;
    entryJson["title"] = title;
    entryJson["content"] = content;
    entryJson["createdAt"] = QDateTime::currentMSecsSinceEpoch();
    entryJson["updatedAt"] = QDateTime::currentMSecsSinceEpoch();

    QString worldDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId + "/world";
    QDir().mkpath(worldDir + "/" + category);

    QString entryFile = entryId + ".json";
    QString filePath = worldDir + "/" + category + "/" + entryFile;

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(entryJson).toJson());
        file.close();
        return true;
    }

    return false;
}

bool WorldSettingManager::updateEntry(const QString& bookId, const QString& category, const QString& entryId, const QString& title, const QString& content) {
    QJsonObject entryJson = getEntry(bookId, category, entryId);
    if (entryJson.isEmpty()) {
        return false;
    }

    entryJson["title"] = title;
    entryJson["content"] = content;
    entryJson["updatedAt"] = QDateTime::currentMSecsSinceEpoch();

    QString worldDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId + "/world";
    QString entryFile = entryId + ".json";
    QString filePath = worldDir + "/" + category + "/" + entryFile;

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(entryJson).toJson());
        file.close();
        return true;
    }

    return false;
}

bool WorldSettingManager::deleteEntry(const QString& bookId, const QString& category, const QString& entryId) {
    QString worldDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId + "/world";
    QString entryFile = entryId + ".json";
    QString filePath = worldDir + "/" + category + "/" + entryFile;

    QFile file(filePath);
    return file.remove();
}

QJsonObject WorldSettingManager::getEntry(const QString& bookId, const QString& category, const QString& entryId) {
    QString worldDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId + "/world";
    QString entryFile = entryId + ".json";
    QString filePath = worldDir + "/" + category + "/" + entryFile;

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        return QJsonObject();
    }

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isObject()) {
        return doc.object();
    }

    return QJsonObject();
}

QList<QJsonObject> WorldSettingManager::getEntries(const QString& bookId, const QString& category) {
    QList<QJsonObject> entries;

    QString worldDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId + "/world/" + category;
    QDir dir(worldDir);

    if (!dir.exists()) {
        return entries;
    }

    QFileInfoList entryFiles = dir.entryInfoList(QStringList() << "*.json", QDir::Files);

    for (const QFileInfo& fileInfo : entryFiles) {
        QFile file(fileInfo.absoluteFilePath());
        if (file.open(QIODevice::ReadOnly)) {
            QByteArray data = file.readAll();
            file.close();

            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isObject()) {
                entries.append(doc.object());
            }
        }
    }

    return entries;
}
