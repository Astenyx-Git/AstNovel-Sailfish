// main.cpp — AstNovel entry point (Sailfish OS, Qt 5.6)
#include <QtQuick>
#include <QLocale>
#include <QSettings>
#include <QTranslator>
#include <sailfishapp.h>
#include "astnovel.h"

// Resolve the UI language: the in-app preference ("", "en", "de", "ru",
// "fi", "zh") wins; with no preference German/Russian/Finnish follow the
// system locale, Chinese uses the source strings, and everything else —
// including unknown locales — defaults to English.
static QString resolveUiLanguage()
{
    QSettings s(QStringLiteral("harbour-astnovel"), QStringLiteral("harbour-astnovel"));
    const QString pref = s.value(QStringLiteral("ui/language")).toString();
    if (pref == QLatin1String("en") || pref == QLatin1String("de") ||
        pref == QLatin1String("ru") || pref == QLatin1String("fi") ||
        pref == QLatin1String("zh"))
        return pref;

    const QString lang = QLocale::system().name();   // e.g. "de_DE"
    if (lang.startsWith(QLatin1String("de")))
        return QStringLiteral("de");
    if (lang.startsWith(QLatin1String("ru")))
        return QStringLiteral("ru");
    if (lang.startsWith(QLatin1String("fi")))
        return QStringLiteral("fi");
    if (lang.startsWith(QLatin1String("zh")))
        return QStringLiteral("zh");
    return QStringLiteral("en");
}

// Install the QTranslator for the resolved language; returns the code so
// the UI can tell whether the persisted preference is already applied.
static QString installUiTranslator(QGuiApplication *app)
{
    const QString code = resolveUiLanguage();
    if (code == QLatin1String("zh"))
        return code;                                 // source language

    QTranslator *tr = new QTranslator(app);
    if (tr->load(QStringLiteral("harbour-astnovel_") + code,
                 QStringLiteral("/usr/share/harbour-astnovel/translations")))
        app->installTranslator(tr);
    else
        delete tr;   // fall back to the Chinese source strings
    return code;
}

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    const QString uiLang = installUiTranslator(app.data());
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    AstnStore store;
    view->rootContext()->setContextProperty("store", &store);
    view->rootContext()->setContextProperty("uiLangApplied", uiLang);

    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->show();

    return app->exec();
}
