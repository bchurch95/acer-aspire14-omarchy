import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

BarWidget {
  id: root
  moduleName: "ben.media"

  readonly property var mediaService: bar?.shell?.serviceFor("ben.media") || bar?.shell?.firstPartyServiceFor("omarchy.media")
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property var sourcePlayers: mediaService ? mediaService.sourcePlayers : []

  readonly property bool hasMedia: mediaService ? mediaService.hasMedia : false
  readonly property string playIcon: activePlayer && activePlayer.isPlaying ? "󰏤" : "󰐊"
  readonly property string title: mediaService ? mediaService.title : ""
  readonly property string artist: mediaService ? mediaService.artist : ""

  property bool popupOpen: false

  function close() { popupOpen = false }
  property real maxLabelWidth: 180

  visible: hasMedia
  implicitWidth: hasMedia ? row.implicitWidth + Style.space(14) : 0
  implicitHeight: barSize

  MouseArea {
    anchors.fill: parent
    z: 0
    hoverEnabled: true
    cursorShape: root.activePlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: function(mouse) {
      if (!root.activePlayer) return
      if (mouse.button === Qt.MiddleButton) {
        if (root.mediaService) root.mediaService.runAction("next", false)
      } else if (mouse.button === Qt.RightButton) {
        root.popupOpen = !root.popupOpen
      } else {
        if (root.mediaService) root.mediaService.runAction("playPause", false)
      }
    }
    onWheel: function(wheel) {
      if (!root.activePlayer) return
      if (wheel.angleDelta.y > 0 && root.mediaService) root.mediaService.runAction("previous", false)
      else if (wheel.angleDelta.y < 0 && root.mediaService) root.mediaService.runAction("next", false)
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.hasMedia ? (root.title + (root.artist ? " — " + root.artist : "")) : "")
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  Row {
    id: row
    z: 1
    anchors.centerIn: parent
    spacing: Style.space(6)

    Item {
      id: playButton
      width: Math.max(Style.space(32), glyph.implicitWidth + Style.space(16))
      height: Math.max(glyph.height + Style.space(10), Style.space(24))
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        id: playBg
        anchors.fill: parent
        radius: Style.spacing.labelGap
        color: playMouseArea.containsMouse ? Style.hoverFillFor(root.bar.barForeground, root.bar.barForeground) : "transparent"
        Behavior on color {
          enabled: !root.bar || root.bar.foregroundAnimationEnabled
          ColorAnimation { duration: 120 }
        }
      }

      Text {
        id: glyph
        anchors.centerIn: parent
        text: root.playIcon
        color: (playMouseArea.containsMouse || (activePlayer && activePlayer.isPlaying))
          ? root.bar.barForeground
          : Qt.darker(root.bar.barForeground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        Behavior on color {
          enabled: !root.bar || root.bar.foregroundAnimationEnabled
          ColorAnimation { duration: 120 }
        }
      }

      MouseArea {
        id: playMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 2

        onClicked: function(mouse) {
          if (root.mediaService && root.activePlayer) {
            root.mediaService.runAction("playPause", false, root.mediaService.playerKey(root.activePlayer))
          }
        }
        onEntered: if (root.bar) root.bar.showTooltip(playButton, activePlayer && activePlayer.isPlaying ? "Pause" : "Play")
        onExited: if (root.bar) root.bar.hideTooltip(playButton)
      }
    }

    Item {
      id: scrollClip
      width: Math.min(root.maxLabelWidth, labelText1.implicitWidth)
      height: glyph.height
      clip: true
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.bar.vertical && root.title !== ""

      readonly property string fullText: root.title + (root.artist ? "  ·  " + root.artist : "")
      readonly property bool needsScroll: labelText1.implicitWidth > root.maxLabelWidth

      Row {
        id: textRow
        spacing: Style.space(36)
        anchors.verticalCenter: parent.verticalCenter

        Text {
          id: labelText1
          text: scrollClip.fullText
          color: root.bar.barForeground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
        }

        Text {
          id: labelText2
          text: scrollClip.needsScroll ? scrollClip.fullText : ""
          color: root.bar.barForeground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          visible: scrollClip.needsScroll
        }

        NumberAnimation on x {
          id: marqueeAnim
          running: scrollClip.needsScroll && !root.popupOpen && !root.bar.vertical
          loops: Animation.Infinite
          duration: Math.max(5000, labelText1.implicitWidth * 30)
          from: 0
          to: -(labelText1.implicitWidth + textRow.spacing)
          easing.type: Easing.Linear
        }
      }

      onNeedsScrollChanged: {
        if (!needsScroll) textRow.x = 0
      }
    }

    Item {
      id: nextButton
      width: Math.max(Style.space(32), nextGlyph.implicitWidth + Style.space(16))
      height: Math.max(glyph.height + Style.space(10), Style.space(24))
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.bar.vertical && root.hasMedia

      Rectangle {
        id: nextBg
        anchors.fill: parent
        radius: Style.spacing.labelGap
        color: nextMouseArea.containsMouse ? Style.hoverFillFor(root.bar.barForeground, root.bar.barForeground) : "transparent"
        Behavior on color {
          enabled: !root.bar || root.bar.foregroundAnimationEnabled
          ColorAnimation { duration: 120 }
        }
      }

      Text {
        id: nextGlyph
        anchors.centerIn: parent
        text: "󰒭"
        color: nextMouseArea.containsMouse ? root.bar.barForeground : Qt.darker(root.bar.barForeground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        Behavior on color {
          enabled: !root.bar || root.bar.foregroundAnimationEnabled
          ColorAnimation { duration: 120 }
        }
      }

      MouseArea {
        id: nextMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 2

        onClicked: function(mouse) {
          if (root.mediaService && root.activePlayer) {
            root.mediaService.runAction("next", false, root.mediaService.playerKey(root.activePlayer))
          }
        }
        onEntered: if (root.bar) root.bar.showTooltip(nextButton, "Next track")
        onExited: if (root.bar) root.bar.hideTooltip(nextButton)
      }
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        spacing: Style.space(10)
        width: parent.width

        BorderSurface {
          width: Style.space(64)
          height: Style.space(64)
          radius: Style.spacing.labelGap
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

          Image {
            anchors.fill: parent
            anchors.margins: Style.space(2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            source: mediaService ? mediaService.artUrl : ""
            visible: source !== ""
          }

          Text {
            anchors.centerIn: parent
            visible: !mediaService || !mediaService.artUrl
            text: "󰝚"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayLarge
          }
        }

        Column {
          spacing: Style.space(4)
          width: parent.width - Style.space(74)

          Text {
            text: root.title || "Nothing playing"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            text: root.artist
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }

          Text {
            text: mediaService ? mediaService.album : ""
            color: Qt.darker(root.bar.foreground, 1.6)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)

        Button {
          iconText: "󰒮"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.activePlayer && root.activePlayer.canGoPrevious
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("previous", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          iconText: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.panelGap
          verticalPadding: Style.spacing.controlPaddingY
          iconSize: Style.font.iconLarge
          enabled: root.activePlayer && (root.activePlayer.canTogglePlaying || root.activePlayer.canPlay || root.activePlayer.canPause)
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("playPause", false, root.mediaService.playerKey(root.activePlayer))
        }

        Button {
          iconText: "󰒭"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          enabled: root.activePlayer && root.activePlayer.canGoNext
          opacity: enabled ? 1.0 : 0.4
          onClicked: if (root.mediaService) root.mediaService.runAction("next", false, root.mediaService.playerKey(root.activePlayer))
        }
      }

      PanelSeparator {
        visible: root.sourcePlayers.length > 1
        foreground: root.bar.foreground
      }

      Column {
        id: sourceList
        visible: root.sourcePlayers.length > 1
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          model: root.sourcePlayers

          BorderSurface {
            id: sourceRow
            required property var modelData

            readonly property var player: modelData
            readonly property bool selected: root.activePlayer && player
              && root.mediaService.playerKey(root.activePlayer) === root.mediaService.playerKey(player)
            readonly property string sourceTitle: player ? (player.trackTitle || player.identity || player.desktopEntry || "Media source") : "Media source"
            readonly property string sourceDetail: player && player.trackArtist ? player.trackArtist : (player && player.identity ? player.identity : "")

            width: sourceList.width
            height: sourceInner.implicitHeight + Style.space(10)
            radius: Style.spacing.labelGap
            color: selected ? Style.selectedFillFor(root.bar.foreground, Color.accent) : "transparent"
            borderSpec: selected ? Border.controlSpec("normal", root.bar.foreground, Color.accent) : Border.none()

            Row {
              id: sourceInner
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: sourceRow.borderLeft + Style.space(8)
              anchors.rightMargin: sourceRow.borderRight + Style.space(8)
              spacing: Style.space(8)

              Text {
                text: sourceRow.player && sourceRow.player.isPlaying ? "󰏤" : "󰐊"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
                width: Style.space(18)
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - Style.space(26)
                spacing: Style.space(1)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  text: sourceRow.sourceTitle
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: sourceRow.selected
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  text: sourceRow.sourceDetail
                  color: Qt.darker(root.bar.foreground, 1.5)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                  width: parent.width
                  visible: text !== ""
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.mediaService) root.mediaService.selectPlayer(root.mediaService.playerKey(sourceRow.player))
            }
          }
        }
      }
    }
  }
}
