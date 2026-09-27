// main.cpp — AstNovel entry point (Sailfish OS, Qt 5.6)
#include <QtQuick>
#include <QLocale>
#include <QTranslator>
#include <sailfishapp.h>
#include "astnovel.h"

// UI language policy: German/Russian/Finnish follow the system locale;
// Chinese is the source language (no translator needed); everything else
// — including unknown locales — defaults to English.
static void installUiTranslator(QGuiApplication *app)
{
    const QString lang = QLocale::system().name();   // e.g. "de_DE"
    QString file;
    if (lang.startsWith(QLatin1String("de")))
        file = QStringLiteral("harbour-astnovel_de");
    else if (lang.startsWith(QLatin1String("ru")))
        file = QStringLiteral("harbour-astnovel_ru");
    else if (lang.startsWith(QLatin1String("fi")))
        file = QStringLiteral("harbour-astnovel_fi");
    else if (lang.startsWith(QLatin1String("zh")))
        return;
    else
        file = QStringLiteral("harbour-astnovel_en");

    QTranslator *tr = new QTranslator(app);
    if (tr->load(file, QStringLiteral("/usr/share/harbour-astnovel/translations")))
        app->installTranslator(tr);
    else
        delete tr;   // fall back to the Chinese source strings
}

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    installUiTranslator(app.data());
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    AstnStore store;
    view->rootContext()->setContextProperty("store", &store);

    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->show();

    return app->exec();
}
