import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

Item {
  id: root
  property var bar
  property string moduleName
  property var settings

  property int cpuPercent: 0
  property int memPercent: 0

  property var prevCpuTimes: null

  implicitWidth: row.implicitWidth + Style.space(8)
  implicitHeight: bar ? bar.barSize : 26

  Process {
    id: statsProc
    command: ["bash", "-c", "cat /proc/stat | head -n 1; free -m | grep Mem"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").trim().split("\n")
        if (lines.length >= 2) {
          // Parse CPU
          var cpuParts = lines[0].trim().split(/\s+/)
          if (cpuParts.length >= 5) {
            var user = parseInt(cpuParts[1]) || 0
            var nice = parseInt(cpuParts[2]) || 0
            var sys = parseInt(cpuParts[3]) || 0
            var idle = parseInt(cpuParts[4]) || 0
            var total = user + nice + sys + idle
            var busy = user + nice + sys
            if (root.prevCpuTimes) {
              var totalDiff = total - root.prevCpuTimes.total
              var busyDiff = busy - root.prevCpuTimes.busy
              if (totalDiff > 0) {
                root.cpuPercent = Math.min(100, Math.max(0, Math.round((busyDiff / totalDiff) * 100)))
              }
            }
            root.prevCpuTimes = { total: total, busy: busy }
          }
          // Parse Memory
          var memParts = lines[1].trim().split(/\s+/)
          if (memParts.length >= 3) {
            var totalMem = parseInt(memParts[1]) || 1
            var usedMem = parseInt(memParts[2]) || 0
            root.memPercent = Math.min(100, Math.max(0, Math.round((usedMem / totalMem) * 100)))
          }
        }
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!statsProc.running) statsProc.running = true
    }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(8)

    Row {
      spacing: Style.space(3)
      anchors.verticalCenter: parent.verticalCenter
      Text {
        text: "󰻠"
        color: root.cpuPercent > 80 ? (root.bar ? root.bar.urgent : "red") : (root.bar ? root.bar.barForeground : "white")
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: Style.font.body
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: root.cpuPercent + "%"
        color: root.bar ? root.bar.barForeground : "white"
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: Style.font.bodySmall
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Row {
      spacing: Style.space(3)
      anchors.verticalCenter: parent.verticalCenter
      Text {
        text: "󰍛"
        color: root.memPercent > 85 ? (root.bar ? root.bar.urgent : "red") : (root.bar ? root.bar.barForeground : "white")
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: Style.font.body
        anchors.verticalCenter: parent.verticalCenter
      }
      Text {
        text: root.memPercent + "%"
        color: root.bar ? root.bar.barForeground : "white"
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: Style.font.bodySmall
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
    }
  }
}
