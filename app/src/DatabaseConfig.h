#ifndef DATABASECONFIG_H
#define DATABASECONFIG_H

#include <QString>

class DatabaseConfig {
public:
    static DatabaseConfig& instance();

    // Get storage paths
    QString getBaseDir() const;
    QString getBooksDir() const;
    QString getBookDir(const QString& bookId) const;
    QString getBookMetaFile(const QString& bookId) const;
    QString getChaptersDir(const QString& bookId) const;
    QString getAutosaveFile(const QString& bookId) const;

private:
    DatabaseConfig();
    ~DatabaseConfig();

    QString m_baseDir;
    QString m_booksDir;
};

#endif // DATABASECONFIG_H
