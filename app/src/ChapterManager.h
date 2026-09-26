#ifndef CHAPTERMANAGER_H
#define CHAPTERMANAGER_H

#include <QString>
#include <QList>
#include <QJsonObject>

class ChapterManager {
public:
    static ChapterManager& instance();

    // Chapter operations
    bool createChapter(const QString& bookId, const QString& title, QString& chapterId);
    bool updateChapter(const QString& bookId, const QString& chapterId, const QString& content);
    bool deleteChapter(const QString& bookId, const QString& chapterId);
    QString getChapterContent(const QString& bookId, const QString& chapterId);
    bool chapterExists(const QString& bookId, const QString& chapterId);

    // List chapters
    QList<QJsonObject> getChapters(const QString& bookId);
    QJsonObject getChapter(const QString& bookId, const QString& chapterId);

private:
    ChapterManager();
    ~ChapterManager();

    QString m_chaptersDir;
};

#endif // CHAPTERMANAGER_H
