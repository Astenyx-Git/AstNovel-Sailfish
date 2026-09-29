# harbour-astnovel.pro — qmake project for Sailfish OS (Qt 5.6)
TARGET = harbour-astnovel
QT += quick
CONFIG += c++11 link_pkgconfig
PKGCONFIG += sailfishapp openssl

# .astn master secrets — never stored in the repository.
# Preferred: create a local (gitignored) mastersecret.pri next to this file
# containing both injected values, e.g.
#   DEFINES += ASTN_MASTER_SECRET=\"<legacy interop secret>\"
#   DEFINES += ASTN_GEN2_SECRET=\"<generation-2 hex digest>\"
# Alternative: export ASTN_MASTER_SECRET / ASTN_GEN2_SECRET in an
# environment that reaches qmake; see README.
ASTN_MASTER_SECRET_ENV = $$(ASTN_MASTER_SECRET)
!isEmpty(ASTN_MASTER_SECRET_ENV) {
    DEFINES += ASTN_MASTER_SECRET=\\\"$$ASTN_MASTER_SECRET_ENV\\\"
}
ASTN_GEN2_SECRET_ENV = $$(ASTN_GEN2_SECRET)
!isEmpty(ASTN_GEN2_SECRET_ENV) {
    DEFINES += ASTN_GEN2_SECRET=\\\"$$ASTN_GEN2_SECRET_ENV\\\"
}
isEmpty(ASTN_MASTER_SECRET_ENV):isEmpty(ASTN_GEN2_SECRET_ENV) {
    exists(mastersecret.pri) { include(mastersecret.pri) }
}

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
