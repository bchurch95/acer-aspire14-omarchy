import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.menu"

  implicitWidth: 36
  implicitHeight: barSize

  Image {
    anchors.centerIn: parent
    source: Qt.resolvedUrl("assets/logo.png")
    width: 22
    height: 22
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    asynchronous: false
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (!root.bar) return
      if (mouse.button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }
  }
}
