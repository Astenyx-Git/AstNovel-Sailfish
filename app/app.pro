TEMPLATE = app
TARGET = astn
CONFIG += sailfishapp qt5 qt quick qml

SOURCES += \
    src/main.cpp \
    src/BookManager.cpp \
    src/ChapterManager.cpp \
    src/CharacterManager.cpp \
    src/WorldSettingManager.cpp \
    src/DatabaseConfig.cpp

HEADERS += \
    src/BookManager.h \
    src/ChapterManager.h \
    src/CharacterManager.h \
    src/WorldSettingManager.h \
    src/DatabaseConfig.h

RESOURCES += qml/qml.qrc

DISTFILES += \
    qml/imports/AstNovel/*.qml \
    harbour/astn.spec

# Include Sailfish OS specific paths
SAILFISHOS_DEPLOYMENT_PATHS = /usr/lib/qt5/imports

# Data storage
CONFIG += sailfishapp_data

# Enable C++11 features
CONFIG += c++11

# QML imports
QML_IMPORT_PATH = /usr/lib/qt5/imports

# Compiler settings
QMAKE_CXXFLAGS += -std=c++11
QMAKE_CFLAGS += -std=c11
