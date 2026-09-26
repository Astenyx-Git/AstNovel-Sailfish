// main.cpp — AstNovel entry point (Sailfish OS, Qt 5.6)
#include <QtQuick>
#include <sailfishapp.h>
#include "astnovel.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    AstnStore store;
    view->rootContext()->setContextProperty("store", &store);

    view->setSource(SailfishApp::pathTo("qml/main.qml"));
    view->show();

    return app->exec();
}
