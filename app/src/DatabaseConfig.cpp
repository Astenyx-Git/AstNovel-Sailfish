#include "DatabaseConfig.h"
#include <QStandardPaths>
#include <QDir>

DatabaseConfig& DatabaseConfig::instance() {
    static DatabaseConfig instance;
    return instance;
}

DatabaseConfig::DatabaseConfig() {
    // Get application data directory
    QString appDataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(appDataPath);
    m_baseDir = appDataPath;
    m_booksDir = m_baseDir + "/books";

    // Ensure directories exist
    QDir().mkpath(m_booksDir);
}

DatabaseConfig::~DatabaseConfig() {
}

QString DatabaseConfig::getBaseDir() const {
    return m_baseDir;
}

QString DatabaseConfig::getBooksDir() const {
    return m_booksDir;
}

QString DatabaseConfig::getBookDir(const QString& bookId) const {
    return m_booksDir + "/" + bookId;
}

QString DatabaseConfig::getBookMetaFile(const QString& bookId) const {
    return m_booksDir + "/" + bookId + "/meta.json";
}

QString DatabaseConfig::getChaptersDir(const QString& bookId) const {
    return m_booksDir + "/" + bookId + "/chapters";
}

QString DatabaseConfig::getAutosaveFile(const QString& bookId) const {
    return m_booksDir + "/" + bookId + "/autosave.txt";
}
