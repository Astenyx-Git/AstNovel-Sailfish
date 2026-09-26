#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "BookManager.h"
#include "ChapterManager.h"
#include "CharacterManager.h"
#include "WorldSettingManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Enable Sailfish OS theme
    app.setStyle("sailfish");

    QQmlApplicationEngine engine;

    // Expose managers to QML
    engine.rootContext()->setContextProperty("bookManager", &BookManager::instance());
    engine.rootContext()->setContextProperty("chapterManager", &ChapterManager::instance());
    engine.rootContext()->setContextProperty("characterManager", &CharacterManager::instance());
    engine.rootContext()->setContextProperty("worldSettingManager", &WorldSettingManager::instance());

    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
