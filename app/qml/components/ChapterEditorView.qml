import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Page {
    id: chapterEditorPage

    property string bookId: ""
    property string chapterId: ""

    // Background color
    background: Rectangle {
        color: Theme.themeBackground
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Chapter Editor")
                menu: MenuItem {
                    text: qsTr("Save")
                    onClicked: saveChapter()
                }
            }

            // Chapter list
            Label {
                width: parent.width
                color: Theme.themeTextSecondary
                font.pixelSize: Theme.typography.captionSize
                text: qsTr("Chapters")
            }

            Repeater {
                model: chapterManager.getChapters(bookId)

                ChapterItem {
                    chapterId: modelData.id
                    title: modelData.title
                    contentPreview: modelData.content
                    createdAt: modelData.createdAt

                    onClicked: {
                        if (chapterEditorPage.chapterId === "") {
                            chapterEditorPage.chapterId = chapterId;
                            loadChapter();
                        }
                    }
                }
            }

            // Editor area
            SectionHeader {
                text: qsTr("Editor")
            }

            TextArea {
                id: editor
                width: parent.width
                height: parent.height - column.height - Theme.paddingLarge
                font.pixelSize: Theme.typography.bodySize
                wrapMode: TextArea.Wrap
                placeholderText: qsTr("Start writing...")
                text: getChapterContent()
            }

            EditorToolbar {
                width: parent.width
                onBack: {
                    if (chapterEditorPage.chapterId !== "") {
                        chapterEditorPage.chapterId = "";
                        chapterEditorPage.loadChapter();
                    } else {
                        pageStack.pop();
                    }
                }

                onSave: {
                    saveChapter();
                }

                onDelete: {
                    deleteChapter();
                }

                onCreateChapter: {
                    createNewChapter();
                }
            }
        }
    }

    function loadChapter() {
        if (chapterId !== "") {
            editor.text = chapterManager.getChapterContent(bookId, chapterId);
        } else {
            editor.text = "";
        }
    }

    function saveChapter() {
        if (chapterId !== "") {
            chapterManager.updateChapter(bookId, chapterId, editor.text);
            Toast.show(qsTr("Chapter saved"));
        }
    }

    function deleteChapter() {
        chapterManager.deleteChapter(bookId, chapterId);
        chapterId = "";
        editor.text = "";
        Toast.show(qsTr("Chapter deleted"));
        pageStack.pop();
    }

    function createNewChapter() {
        var newChapterId = "";
        chapterManager.createChapter(bookId, qsTr("New Chapter"), newChapterId);
        chapterId = newChapterId;
        editor.text = "";
        Toast.show(qsTr("New chapter created"));
    }

    function getChapterContent() {
        if (chapterId !== "") {
            return chapterManager.getChapterContent(bookId, chapterId);
        }
        return "";
    }
}
