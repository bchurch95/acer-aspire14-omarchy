import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "ben.apple-music-button"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property bool specialMusicActive: false

  // Dynamic geometry based on target screen resolution (defaults to 1600x1000 logical)
  readonly property var activeScreen: root.bar && root.bar.screen ? root.bar.screen : (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
  readonly property real screenWidth: activeScreen ? activeScreen.width : 1600
  readonly property real screenHeight: activeScreen ? activeScreen.height : 1000

  readonly property real windowWidth: 880
  readonly property real windowHeight: 560
  readonly property real windowTop: 36

  readonly property real sideScrimWidth: Math.max(0, (screenWidth - windowWidth) / 2)
  readonly property real bottomScrimHeight: Math.max(0, screenHeight - windowHeight - windowTop)

  function isAppleMusicWindow(winClass, winTitle) {
    var c = String(winClass || "").toLowerCase()
    var t = String(winTitle || "").toLowerCase()
    return c.indexOf("music.apple.com") !== -1
      || c.indexOf("apple-music") !== -1
      || t.indexOf("apple music") !== -1
      || t.indexOf("apple\xa0music") !== -1
  }

  function dismiss() {
    root.specialMusicActive = false
    if (!toggleSpecialProc.running) toggleSpecialProc.running = true
  }

  Process {
    id: toggleSpecialProc
    command: ["hyprctl", "dispatch", "hl.dsp.workspace.toggle_special(\"music\")"]
  }

  Process {
    id: launchProc
    command: ["apple-music"]
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      var name = String(event && event.name ? event.name : "")
      var data = String(event && event.data ? event.data : "")

      if (name === "activespecial") {
        var spec = data.split(",")[0] || ""
        root.specialMusicActive = (spec === "special:music")
      } else if (name === "activewindow" && root.specialMusicActive) {
        var commaIdx = data.indexOf(",")
        var winClass = commaIdx >= 0 ? data.substring(0, commaIdx) : data
        var winTitle = commaIdx >= 0 ? data.substring(commaIdx + 1) : ""

        if (!root.isAppleMusicWindow(winClass, winTitle)) {
          root.dismiss()
        }
      }
    }
  }

  Component.onCompleted: {
    if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.name === "special:music") {
      root.specialMusicActive = true
    }
  }

  // Left click-catcher panel (left of Apple Music window)
  PanelWindow {
    screen: root.activeScreen
    visible: root.specialMusicActive
    anchors { left: true; top: true; bottom: true }
    implicitWidth: root.sideScrimWidth
    color: "transparent"
    WlrLayershell.namespace: "apple-music-scrim-left"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onPressed: root.dismiss()
    }
  }

  // Right click-catcher panel (right of Apple Music window)
  PanelWindow {
    screen: root.activeScreen
    visible: root.specialMusicActive
    anchors { right: true; top: true; bottom: true }
    implicitWidth: root.sideScrimWidth
    color: "transparent"
    WlrLayershell.namespace: "apple-music-scrim-right"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onPressed: root.dismiss()
    }
  }

  // Bottom click-catcher panel (below Apple Music window)
  PanelWindow {
    screen: root.activeScreen
    visible: root.specialMusicActive
    anchors { left: true; right: true; bottom: true }
    implicitHeight: root.bottomScrimHeight
    color: "transparent"
    WlrLayershell.namespace: "apple-music-scrim-bottom"
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore

    MouseArea {
      anchors.fill: parent
      onPressed: root.dismiss()
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰝚"
    slotSize: Style.bar.iconSlot
    fontSize: Style.bar.iconFont
    foreground: root.bar ? root.bar.barForeground : Color.foreground
    active: root.specialMusicActive
    tooltipText: "Apple Music"
    onPressed: {
      if (!launchProc.running) launchProc.running = true
    }
  }
}
