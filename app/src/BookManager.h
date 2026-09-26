#ifndef BOOKMANAGER_H
#define BOOKMANAGER_H

#include <QString>
#include <QList>
#include <QJsonObject>
#include <QFile>

class BookManager {
public:
    static BookManager& instance();

    // Book operations
    bool createBook(const QString& title, const QString& description, QString& bookId);
    bool updateBook(const QString& bookId, const QString& title, const QString& description);
    bool deleteBook(const QString& bookId);
    QJsonObject getBook(const QString& bookId);
    QList<QJsonObject> getAllBooks();
    bool bookExists(const QString& bookId);

    // File operations
    QString getBookDir(const QString& bookId);
    QString getBookMetaFile(const QString& bookId);
    QString getChaptersDir(const QString& bookId);
    QString getAutosaveFile(const QString& bookId);

private:
    BookManager();
    ~BookManager();

    QString m_baseDir;
    QString m_booksDir;

    void ensureDir(const QString& path);
};

#endif // BOOKMANAGER_H
