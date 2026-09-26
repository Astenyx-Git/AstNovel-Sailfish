#include "BookManager.h"
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QStandardPaths>

BookManager& BookManager::instance() {
    static BookManager instance;
    return instance;
}

BookManager::BookManager() {
    // Get application data directory
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataPath);
    m_baseDir = appDataPath;
    m_booksDir = m_baseDir + "/books";

    // Ensure directories exist
    ensureDir(m_booksDir);
}

BookManager::~BookManager() {
}

bool BookManager::createBook(const QString& title, const QString& description, QString& bookId) {
    bookId = "book_" + QString::number(QDateTime::currentMSecsSinceEpoch()) + "_" +
             QString::number(QRandomGenerator::global()->bounded(10000));

    QJsonObject bookJson;
    bookJson["id"] = bookId;
    bookJson["title"] = title;
    bookJson["description"] = description;
    bookJson["coverDataUri"] = "";
    bookJson["createdAt"] = QDateTime::currentMSecsSinceEpoch();
    bookJson["updatedAt"] = QDateTime::currentMSecsSinceEpoch();

    QString metaFile = getBookMetaFile(bookId);
    QFile file(metaFile);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(bookJson).toJson());
        file.close();

        // Create book directory
        QDir().mkpath(getBookDir(bookId));
        QDir().mkpath(getChaptersDir(bookId));
        return true;
    }

    return false;
}

bool BookManager::updateBook(const QString& bookId, const QString& title, const QString& description) {
    QJsonObject bookJson = getBook(bookId);
    if (bookJson.isEmpty()) {
        return false;
    }

    bookJson["title"] = title;
    bookJson["description"] = description;
    bookJson["updatedAt"] = QDateTime::currentMSecsSinceEpoch();

    QString metaFile = getBookMetaFile(bookId);
    QFile file(metaFile);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(bookJson).toJson());
        file.close();
        return true;
    }

    return false;
}

bool BookManager::deleteBook(const QString& bookId) {
    // Delete book directory
    QDir bookDir(getBookDir(bookId));
    bookDir.removeRecursively();

    // Delete meta file
    QFile metaFile(getBookMetaFile(bookId));
    return metaFile.remove();
}

QJsonObject BookManager::getBook(const QString& bookId) {
    QFile file(getBookMetaFile(bookId));
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

QList<QJsonObject> BookManager::getAllBooks() {
    QList<QJsonObject> books;

    QDir booksDir(m_booksDir);
    QFileInfoList bookDirs = booksDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);

    for (const QFileInfo& dirInfo : bookDirs) {
        QJsonObject bookJson = getBook(dirInfo.fileName());
        if (!bookJson.isEmpty()) {
            books.append(bookJson);
        }
    }

    // Sort by updated date (newest first)
    std::sort(books.begin(), books.end(), [](const QJsonObject& a, const QJsonObject& b) {
        return a["updatedAt"].toVariant().toLongLong() > b["updatedAt"].toVariant().toLongLong();
    });

    return books;
}

bool BookManager::bookExists(const QString& bookId) {
    QFile file(getBookMetaFile(bookId));
    return file.exists();
}

QString BookManager::getBookDir(const QString& bookId) {
    return m_booksDir + "/" + bookId;
}

QString BookManager::getBookMetaFile(const QString& bookId) {
    return m_booksDir + "/" + bookId + "/meta.json";
}

QString BookManager::getChaptersDir(const QString& bookId) {
    return getBookDir(bookId) + "/chapters";
}

QString BookManager::getAutosaveFile(const QString& bookId) {
    return getBookDir(bookId) + "/autosave.txt";
}

void BookManager::ensureDir(const QString& path) {
    QDir dir(path);
    if (!dir.exists()) {
        dir.mkpath(".");
    }
}
