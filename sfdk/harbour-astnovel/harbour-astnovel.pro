# harbour-astnovel.pro — qmake project for Sailfish OS (Qt 5.6)
TARGET = harbour-astnovel
QT += quick
CONFIG += c++11 link_pkgconfig
PKGCONFIG += sailfishapp openssl

SOURCES += \
    src/main.cpp \
    src/astnovel.cpp

HEADERS += \
    src/astnovel.h

# UI translations: source language is Chinese (as in the original app);
# English is the default, de/ru/fi follow the system locale (see main.cpp).
# The .qm files are compiled from the .ts sources with lrelease on the host
# (translations/gen-ts.ps1) — the Build Engine has no lrelease.
OTHER_FILES += \
    translations/harbour-astnovel_en.ts \
    translations/harbour-astnovel_de.ts \
    translations/harbour-astnovel_ru.ts \
    translations/harbour-astnovel_fi.ts

translations.files = \
    translations/harbour-astnovel_en.qm \
    translations/harbour-astnovel_de.qm \
    translations/harbour-astnovel_ru.qm \
    translations/harbour-astnovel_fi.qm
translations.path = /usr/share/harbour-astnovel/translations

OTHER_FILES += \
    qml/main.qml \
    qml/pages/*.qml \
    qml/components/*.qml \
    qml/styles/qmldir \
    qml/styles/AstnStyle.qml \
    rpm/harbour-astnovel.spec \
    harbour-astnovel.desktop

target.path = /usr/bin
qml.files = qml
qml.path = /usr/share/harbour-astnovel
desktop.files = harbour-astnovel.desktop
desktop.path = /usr/share/applications
icons.files = icons/86x86/harbour-astnovel.png
icons.path = /usr/share/icons/hicolor/86x86/apps

INSTALLS += target qml desktop icons translations
