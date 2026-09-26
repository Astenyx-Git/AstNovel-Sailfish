#include "ChapterManager.h"
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QDateTime>

ChapterManager& ChapterManager::instance() {
    static ChapterManager instance;
    return instance;
}

ChapterManager::ChapterManager() {
    // Get base directory from BookManager
    QString baseDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    m_chaptersDir = baseDir + "/books/*/chapters";
}

ChapterManager::~ChapterManager() {
}

bool ChapterManager::createChapter(const QString& bookId, const QString& title, QString& chapterId) {
    chapterId = "chapter_" + QString::number(QDateTime::currentMSecsSinceEpoch());

    QJsonObject chapterJson;
    chapterJson["id"] = chapterId;
    chapterJson["title"] = title;
    chapterJson["content"] = "";
    chapterJson["createdAt"] = QDateTime::currentMSecsSinceEpoch();
    chapterJson["updatedAt"] = QDateTime::currentMSecsSinceEpoch();

    QString chapterFile = bookId + "/" + chapterId + ".json";
    QString filePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + chapterFile;

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(chapterJson).toJson());
        file.close();
        return true;
    }

    return false;
}

bool ChapterManager::updateChapter(const QString& bookId, const QString& chapterId, const QString& content) {
    QJsonObject chapterJson = getChapter(bookId, chapterId);
    if (chapterJson.isEmpty()) {
        return false;
    }

    chapterJson["content"] = content;
    chapterJson["updatedAt"] = QDateTime::currentMSecsSinceEpoch();

    QString chapterFile = bookId + "/" + chapterId + ".json";
    QString filePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + chapterFile;

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(chapterJson).toJson());
        file.close();
        return true;
    }

    return false;
}

bool ChapterManager::deleteChapter(const QString& bookId, const QString& chapterId) {
    QString chapterFile = bookId + "/" + chapterId + ".json";
    QString filePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + chapterFile;

    QFile file(filePath);
    return file.remove();
}

QString ChapterManager::getChapterContent(const QString& bookId, const QString& chapterId) {
    QJsonObject chapterJson = getChapter(bookId, chapterId);
    return chapterJson["content"].toString();
}

bool ChapterManager::chapterExists(const QString& bookId, const QString& chapterId) {
    QString chapterFile = bookId + "/" + chapterId + ".json";
    QString filePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + chapterFile;

    QFile file(filePath);
    return file.exists();
}

QList<QJsonObject> ChapterManager::getChapters(const QString& bookId) {
    QList<QJsonObject> chapters;

    QString chaptersDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + bookId;
    QDir dir(chaptersDir);

    if (!dir.exists()) {
        return chapters;
    }

    QFileInfoList chapterFiles = dir.entryInfoList(QStringList() << "*.json", QDir::Files);

    for (const QFileInfo& fileInfo : chapterFiles) {
        QFile file(fileInfo.absoluteFilePath());
        if (file.open(QIODevice::ReadOnly)) {
            QByteArray data = file.readAll();
            file.close();

            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isObject()) {
                chapters.append(doc.object());
            }
        }
    }

    // Sort by created date (newest first)
    std::sort(chapters.begin(), chapters.end(), [](const QJsonObject& a, const QJsonObject& b) {
        return a["createdAt"].toVariant().toLongLong() > b["createdAt"].toVariant().toLongLong();
    });

    return chapters;
}

QJsonObject ChapterManager::getChapter(const QString& bookId, const QString& chapterId) {
    QString chapterFile = bookId + "/" + chapterId + ".json";
    QString filePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/books/" + chapterFile;

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
