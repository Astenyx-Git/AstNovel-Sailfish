#ifndef WORLDSETTINGMANAGER_H
#define WORLDSETTINGMANAGER_H

#include <QString>
#include <QList>
#include <QJsonObject>

class WorldSettingManager {
public:
    static WorldSettingManager& instance();

    // World setting operations
    bool createEntry(const QString& bookId, const QString& category, const QString& title, const QString& content, QString& entryId);
    bool updateEntry(const QString& bookId, const QString& category, const QString& entryId, const QString& title, const QString& content);
    bool deleteEntry(const QString& bookId, const QString& category, const QString& entryId);
    QJsonObject getEntry(const QString& bookId, const QString& category, const QString& entryId);
    QList<QJsonObject> getEntries(const QString& bookId, const QString& category);

private:
    WorldSettingManager();
    ~WorldSettingManager();
};

#endif // WORLDSETTINGMANAGER_H
