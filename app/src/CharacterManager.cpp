#include "CharacterManager.h"
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QDateTime>

CharacterManager& CharacterManager::instance() {
    static CharacterManager instance;
    return instance;
}

CharacterManager::CharacterManager() {
}

CharacterManager::~CharacterManager() {
}

bool CharacterManager::createCharacter(const QString& bookId, const QString& name, const QString& description, QString& characterId) {
    characterId = "character_" + QString::number(QDateTime::currentMSecsSinceEpoch());

    QJsonObject characterJson;
    characterJson["id"] = characterId;
    characterJson["name"] = name;
    characterJson["description"] = description;
    characterJson["createdAt"] = QDateTime::currentMSecsSinceEpoch();
    characterJson["updatedAt"] = QDateTime::currentMSecsSinceEpoch();

    QString charactersDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId + "/characters";
    QDir().mkpath(charactersDir);

    QString characterFile = characterId + ".json";
    QString filePath = charactersDir + "/" + characterFile;

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(characterJson).toJson());
        file.close();
        return true;
    }

    return false;
}

bool CharacterManager::updateCharacter(const QString& bookId, const QString& characterId, const QString& name, const QString& description) {
    QJsonObject characterJson = getCharacter(bookId, characterId);
    if (characterJson.isEmpty()) {
        return false;
    }

    characterJson["name"] = name;
    characterJson["description"] = description;
    characterJson["updatedAt"] = QDateTime::currentMSecsSinceEpoch();

    QString charactersDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId + "/characters";
    QString characterFile = characterId + ".json";
    QString filePath = charactersDir + "/" + characterFile;

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(characterJson).toJson());
        file.close();
        return true;
    }

    return false;
}

bool CharacterManager::deleteCharacter(const QString& bookId, const QString& characterId) {
    QString charactersDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId + "/characters";
    QString characterFile = characterId + ".json";
    QString filePath = charactersDir + "/" + characterFile;

    QFile file(filePath);
    return file.remove();
}

QJsonObject CharacterManager::getCharacter(const QString& bookId, const QString& characterId) {
    QString charactersDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId + "/characters";
    QString characterFile = characterId + ".json";
    QString filePath = charactersDir + "/" + characterFile;

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

QList<QJsonObject> CharacterManager::getCharacters(const QString& bookId) {
    QList<QJsonObject> characters;

    QString charactersDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId + "/characters";
    QDir dir(charactersDir);

    if (!dir.exists()) {
        return characters;
    }

    QFileInfoList characterFiles = dir.entryInfoList(QStringList() << "*.json", QDir::Files);

    for (const QFileInfo& fileInfo : characterFiles) {
        QFile file(fileInfo.absoluteFilePath());
        if (file.open(QIODevice::ReadOnly)) {
            QByteArray data = file.readAll();
            file.close();

            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isObject()) {
                characters.append(doc.object());
            }
        }
    }

    return characters;
}
