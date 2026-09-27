// main.cpp — AstNovel entry point (Sailfish OS, Qt 5.6)
#include <QtQuick>
#include <QLocale>
#include <QSettings>
#include <QTimer>
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

// Swap the active translator for the resolved language. Removing and
// installing translators makes Qt deliver LanguageChange events, which the
// QML engine uses to re-evaluate every qsTr() binding — i.e. live
// switching without a restart. Chinese needs no translator (source lang).
static QString applyLanguage(QGuiApplication *app, QTranslator **active)
{
    if (*active) {
        app->removeTranslator(*active);
        delete *active;
        *active = 0;
    }

    const QString code = resolveUiLanguage();
    if (code == QLatin1String("zh"))
        return code;

    QTranslator *tr = new QTranslator(app);
    if (tr->load(QStringLiteral("harbour-astnovel_") + code,
                 QStringLiteral("/usr/share/harbour-astnovel/translations"))) {
        app->installTranslator(tr);
        *active = tr;
    } else {
        delete tr;   // fall back to the Chinese source strings
    }
    return code;
}

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QTranslator *activeTranslator = 0;
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    AstnStore store;
    const QString uiLang = applyLanguage(app.data(), &activeTranslator);
    view->rootContext()->setContextProperty("store", &store);
    view->rootContext()->setContextProperty("uiLangApplied", uiLang);

    // Live switch: the settings page persists the preference and emits
    // uiLanguageChanged. Qt 5.6's QML engine does not reliably re-evaluate
    // qsTr() bindings on LanguageChange, so after swapping translators the
    // whole view is reloaded from source (deferred with a zero-timer so we
    // never tear down QML objects while a QML call is still on the stack).
    // The result is an immediate UI in the new language — no manual restart.
    QObject::connect(&store, &AstnStore::uiLanguageChanged, app.data(),
                     [&app, &activeTranslator, &view]() {
        QTimer::singleShot(0, app.data(), [&app, &activeTranslator, &view]() {
            const QString code = applyLanguage(app.data(), &activeTranslator);
            view->rootContext()->setContextProperty("uiLangApplied", code);
            view->engine()->clearComponentCache();
            view->setSource(SailfishApp::pathTo("qml/main.qml"));
        });
    });

    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->show();

    return app->exec();
}
