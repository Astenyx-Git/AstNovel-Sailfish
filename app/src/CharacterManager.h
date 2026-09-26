#ifndef CHARACTERMANAGER_H
#define CHARACTERMANAGER_H

#include <QString>
#include <QList>
#include <QJsonObject>

class CharacterManager {
public:
    static CharacterManager& instance();

    // Character operations
    bool createCharacter(const QString& bookId, const QString& name, const QString& description, QString& characterId);
    bool updateCharacter(const QString& bookId, const QString& characterId, const QString& name, const QString& description);
    bool deleteCharacter(const QString& bookId, const QString& characterId);
    QJsonObject getCharacter(const QString& bookId, const QString& characterId);
    QList<QJsonObject> getCharacters(const QString& bookId);

private:
    CharacterManager();
    ~CharacterManager();
};

#endif // CHARACTERMANAGER_H
