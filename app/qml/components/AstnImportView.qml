import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Page {
    id: astnImportPage

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Import ASTN")
            }

            Label {
                width: parent.width
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Import a novel from ASTN format file")
            }

            Button {
                width: parent.width
                text: qsTr("Select File")
                onClicked: selectFile()
            }

            Label {
                width: parent.width
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Note: ASTN import requires C++ backend implementation")
            }
        }
    }

    function selectFile() {
        // TODO: Implement file picker
        Toast.show(qsTr("File picker coming soon"));
    }
}
