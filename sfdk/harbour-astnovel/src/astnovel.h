// astnovel.h — AstnStore: data layer exposed to QML (Qt 5.6 compatible)
#ifndef ASTNOVEL_H
#define ASTNOVEL_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

class AstnStore : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString uiLanguage READ uiLanguage WRITE setUiLanguage NOTIFY uiLanguageChanged)
    Q_PROPERTY(bool darkMode READ darkMode WRITE setDarkMode NOTIFY darkModeChanged)

signals:
    void uiLanguageChanged();
    void darkModeChanged();

public:
    explicit AstnStore(QObject *parent = 0);

    // Books
    Q_INVOKABLE QVariantList books();
    Q_INVOKABLE QVariantMap book(const QString &bookId);
    Q_INVOKABLE QString createBook(const QString &title, const QString &description);
    Q_INVOKABLE bool updateBook(const QString &bookId, const QString &title, const QString &description);
    Q_INVOKABLE bool deleteBook(const QString &bookId);
    Q_INVOKABLE int chapterCount(const QString &bookId);

    // Chapters
    Q_INVOKABLE QVariantList chapters(const QString &bookId);
    Q_INVOKABLE QVariantMap chapter(const QString &bookId, const QString &chapterId);
    Q_INVOKABLE QString createChapter(const QString &bookId, const QString &title);
    Q_INVOKABLE bool saveChapter(const QString &bookId, const QString &chapterId, const QString &content);
    Q_INVOKABLE bool deleteChapter(const QString &bookId, const QString &chapterId);

    // Characters (structured fields, mirrors original CharacterCard.ets)
    Q_INVOKABLE QVariantList characters(const QString &bookId);
    Q_INVOKABLE QString createCharacter(const QString &bookId, const QVariantMap &fields);
    Q_INVOKABLE bool updateCharacter(const QString &bookId, const QString &characterId,
                                     const QVariantMap &fields);
    Q_INVOKABLE bool deleteCharacter(const QString &bookId, const QString &characterId);
    // Character avatar + setting images (CharacterCard.avatarDataUri / imageDataUris)
    Q_INVOKABLE bool setCharacterAvatar(const QString &bookId, const QString &characterId,
                                        const QString &imagePath);
    Q_INVOKABLE bool clearCharacterAvatar(const QString &bookId, const QString &characterId);
    Q_INVOKABLE bool addCharacterImage(const QString &bookId, const QString &characterId,
                                       const QString &imagePath);
    Q_INVOKABLE bool removeCharacterImage(const QString &bookId, const QString &characterId, int index);
    // Pre-baked rounded square avatar thumbnail for fast display
    Q_INVOKABLE QString avatarThumbPath(const QString &bookId, const QString &characterId, int size);
    // Save a grabbed frame (cover thumbnail) to the cache dir; returns the
    // path or "" — the cover window cannot use itemgrabber:// URLs directly
    Q_INVOKABLE QString saveCoverFrame(const QImage &img, const QString &name);

    // UI language preference ("", "en", "de", "ru", "fi", "zh"); ""
    // means "follow the system locale" (see main.cpp)
    Q_INVOKABLE QString uiLanguage() const;
    Q_INVOKABLE void setUiLanguage(const QString &lang);
    Q_INVOKABLE bool darkMode() const;
    Q_INVOKABLE void setDarkMode(bool dark);

    // Editor support: CJK word count + crash-recovery autosave
    Q_INVOKABLE int countWords(const QString &text) const;
    Q_INVOKABLE void saveAutosave(const QString &bookId, const QString &chapterId, const QString &content);
    Q_INVOKABLE QString loadAutosave(const QString &bookId, const QString &chapterId);
    Q_INVOKABLE void clearAutosave(const QString &bookId, const QString &chapterId);

    // Outline (mirrors Outline.ets: 卷/章/节 tree with linked entities)
    Q_INVOKABLE QVariantList outlines(const QString &bookId);
    Q_INVOKABLE QString createOutline(const QString &bookId, const QString &parentId, int level,
                                      const QString &title);
    Q_INVOKABLE bool updateOutline(const QString &bookId, const QString &outlineId,
                                   const QVariantMap &fields);
    Q_INVOKABLE bool deleteOutline(const QString &bookId, const QString &outlineId);

    // Import conflict check (mirrors AstnImportService.checkConflict: title match)
    Q_INVOKABLE QString importConflictBookId(const QString &path);

    // World setting entries (per-category field templates, mirrors WorldSetting.ets)
    Q_INVOKABLE QStringList worldFields(const QString &category);
    Q_INVOKABLE QVariantList worldEntries(const QString &bookId, const QString &category);
    Q_INVOKABLE QString createWorldEntry(const QString &bookId, const QString &category,
                                         const QVariantMap &fields, const QString &notes);
    Q_INVOKABLE bool updateWorldEntry(const QString &bookId, const QString &category, const QString &entryId,
                                      const QVariantMap &fields, const QString &notes);
    Q_INVOKABLE bool deleteWorldEntry(const QString &bookId, const QString &category, const QString &entryId);

    // Cover image
    // Cover helpers
    Q_INVOKABLE bool setBookCoverFromImage(const QString &bookId, const QString &imagePath);
    Q_INVOKABLE bool clearBookCover(const QString &bookId);
    // Pre-baked rounded gradient cover (texture draw is cheap on software rendering)
    Q_INVOKABLE QString gradientCoverPath(int index, qreal width, qreal height, qreal radius,
                                          const QString &topColor, const QString &bottomColor);

    // .astn import / export
    Q_INVOKABLE QString exportBookAs(const QString &bookId, const QString &format,
                                     const QString &outputDir);
    Q_INVOKABLE QString exportBookToAstn(const QString &bookId, const QString &outputDir);
    Q_INVOKABLE QString importBookFromAstn(const QString &path, const QString &mode);

private:
    QString newId(const QString &prefix) const;
    QVariantMap readJson(const QString &path) const;
    bool writeJson(const QString &path, const QVariantMap &data) const;
    QVariantList listJsonDir(const QString &dirPath, const QString &sortKey, bool newestFirst) const;
    QVariantMap touch(const QVariantMap &data) const;
    QString bookDir(const QString &bookId) const;

    QString m_baseDir;
};

#endif // ASTNOVEL_H
