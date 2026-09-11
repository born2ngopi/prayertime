import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Item {
  id: root

  property bool opened: false
  property var shell: null
  property var manifest: null

  property string activePrayerName: "Prayer Time"
  property string hijriDateText: ""

  property var service: null

  function open(payloadJson) {
    root.opened = true;
    if (service) {
      root.activePrayerName = service.nextPrayerName;
      root.hijriDateText = service.hijriDateText;
    }
    console.log("[PrayerTime] overlay opened. prayer=", root.activePrayerName, "hijri=", root.hijriDateText);
  }

  function close() {
    root.opened = false;
  }

  function dismiss() {
    root.opened = false;
    if (shell) shell.hide(manifest.id);
  }

  PanelWindow {
    id: notificationWindow
    visible: root.opened

    anchors {
      top: true
      right: true
    }

    margins {
      top: 40
      right: 20
    }

    implicitWidth: 320
    implicitHeight: 100
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: "#1E1E2E"
      border.color: "#89B4FA"
      border.width: 1.5
      radius: 12

      RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Text {
          text: "\uf06d"
          font.pixelSize: 24
          Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          spacing: 3

          Text {
            text: root.service ? root.service.tr("notify.altTitle") : "Prayer Time Alert"
            color: "#89B4FA"
            font.pixelSize: 11
            font.bold: true
          }

          Text {
            text: root.service
              ? root.service.trf("notify.body", { name: root.service.displayPrayerName(root.activePrayerName) })
              : "It is time for " + root.activePrayerName + " prayer."
            color: "#CDD6F4"
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
          }

          Text {
            text: root.hijriDateText !== "" ? root.hijriDateText
              : (root.service ? root.service.tr("notify.prepare") : "Please prepare for prayer.")
            color: "#A6ADC8"
            font.pixelSize: 10
            visible: text !== ""
          }
        }

        Rectangle {
          width: 24
          height: 24
          radius: 12
          color: dismissMouse.containsMouse ? "#313244" : "transparent"

          Text {
            anchors.centerIn: parent
            text: "\u2715"
            color: "#A6ADC8"
            font.pixelSize: 11
          }

          MouseArea {
            id: dismissMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.dismiss()
          }
        }
      }
    }
  }
}
