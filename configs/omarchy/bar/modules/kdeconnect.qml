import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

Item {
  id: root
  property var bar
  property string moduleName: "kdeconnect"
  property var settings

  property bool isInstalled: false
  property bool hasDevice: false
  property string deviceName: ""
  property string deviceId: ""
  property string deviceStatus: "KDE Connect not running"

  implicitWidth: row.implicitWidth + Style.space(8)
  implicitHeight: bar ? bar.barSize : 26

  Process {
    id: checkProc
    command: ["bash", "-c", "if ! which kdeconnect-cli >/dev/null 2>&1; then echo 'NOT_INSTALLED'; else kdeconnect-cli -a --id-name-only 2>/dev/null | head -n 1; fi"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var output = String(text || "").trim()
        if (output === "NOT_INSTALLED") {
          root.isInstalled = false
          root.hasDevice = false
          root.deviceId = ""
          root.deviceName = ""
          root.deviceStatus = "KDE Connect is not installed (run: sudo pacman -S kdeconnect)"
        } else if (output.length > 0 && output.indexOf(" ") > 0) {
          root.isInstalled = true
          var firstSpace = output.indexOf(" ")
          root.deviceId = output.substring(0, firstSpace).trim()
          root.deviceName = output.substring(firstSpace + 1).trim()
          root.hasDevice = true
          root.deviceStatus = "Connected: " + root.deviceName
        } else {
          root.isInstalled = true
          root.hasDevice = false
          root.deviceId = ""
          root.deviceName = ""
          root.deviceStatus = "KDE Connect active (no phone paired/connected)"
        }
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!checkProc.running) checkProc.running = true
    }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(4)

    Text {
      text: root.hasDevice ? "󰄡" : (root.isInstalled ? "󰄢" : "󰄢")
      color: root.hasDevice ? (root.bar ? root.bar.barForeground : Color.foreground) : (root.bar ? Util.alpha(root.bar.barForeground, 0.45) : "#777777")
      font.family: root.bar ? root.bar.fontFamily : "monospace"
      font.pixelSize: Style.font.body
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      visible: root.hasDevice && (!root.bar || !root.bar.vertical)
      text: root.deviceName
      color: root.bar ? root.bar.barForeground : Color.foreground
      font.family: root.bar ? root.bar.fontFamily : "monospace"
      font.pixelSize: Style.font.bodySmall
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true

    onEntered: {
      if (root.bar && root.bar.showTooltip) {
        var msg = "KDE Connect: " + root.deviceStatus
        if (root.hasDevice) {
          msg += "\n• Left-click: Settings\n• Middle-click: Ring Phone\n• Right-click: Send Clipboard"
        } else if (root.isInstalled) {
          msg += "\n• Left-click: Open KDE Connect app"
        } else {
          msg += "\n• Left-click: Needs installation"
        }
        root.bar.showTooltip(root, msg)
      }
    }
    onExited: {
      if (root.bar && root.bar.hideTooltip) {
        root.bar.hideTooltip(root)
      }
    }

    onClicked: function(mouse) {
      if (mouse.button === Qt.LeftButton) {
        if (root.bar) root.bar.run("kdeconnect-app || kdeconnect-settings")
      } else if (mouse.button === Qt.MiddleButton) {
        if (root.hasDevice && root.deviceId.length > 0 && root.bar) {
          root.bar.run("kdeconnect-cli -d " + root.bar.shellQuote(root.deviceId) + " --ring")
        }
      } else if (mouse.button === Qt.RightButton) {
        if (root.hasDevice && root.deviceId.length > 0 && root.bar) {
          root.bar.run("wl-paste | kdeconnect-cli -d " + root.bar.shellQuote(root.deviceId) + " --share-text -")
        }
      }
    }
  }
}
