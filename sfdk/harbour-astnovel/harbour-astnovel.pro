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

INSTALLS += target qml desktop icons
