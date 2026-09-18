import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "born2ngopi.prayertime"
  ipcTarget: "born2ngopi.prayertime"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  property bool settingsOpen: false
  property bool quranOpen: false
  property int selectedSurahNumber: 1

  readonly property var service: root.bar && root.bar.shell
    ? root.bar.shell.serviceFor("born2ngopi.prayertime") : null

  function open() {
    root.settingsOpen = false
    root.controller.show()
  }
  function close() { root.controller.hide() }
  function toggle() { if (root.opened) root.close(); else root.open() }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(300))
    contentHeight: panel.fittedContentHeight(contentLoader.item ? contentLoader.item.implicitHeight : Style.space(420))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: contentLoader.item ? (contentLoader.item.inputActive || contentLoader.item.dropdownOpen) : false
      onCloseRequested: root.close()

      Loader {
        id: contentLoader
        anchors.fill: parent
        active: true
        sourceComponent: contentComponent
      }
    }
  }

  Component {
    id: contentComponent

    Column {
      id: content
      readonly property bool inputActive: inputLat.activeFocus || inputLong.activeFocus
      readonly property bool dropdownOpen: calcMethodDropdown.popupOpen || languageDropdown.popupOpen
      readonly property bool rtl: root.service && root.service.language === "ar"
      width: parent.width
      spacing: Style.space(10)

      readonly property var calcMethodOptions: [
        { value: "0",  label: "Jafari / Shia Ithna-Ashari" },
        { value: "1",  label: "University of Islamic Sciences, Karachi" },
        { value: "2",  label: "Islamic Society of North America" },
        { value: "3",  label: "Muslim World League" },
        { value: "4",  label: "Umm Al-Qura University, Makkah" },
        { value: "5",  label: "Egyptian General Authority of Survey" },
        { value: "7",  label: "Institute of Geophysics, University of Tehran" },
        { value: "8",  label: "Gulf Region" },
        { value: "9",  label: "Kuwait" },
        { value: "10", label: "Qatar" },
        { value: "11", label: "Majlis Ugama Islam Singapura, Singapore" },
        { value: "12", label: "Union Organization islamic de France" },
        { value: "13", label: "Diyanet İşleri Başkanlığı, Turkey" },
        { value: "14", label: "Spiritual Administration of Muslims of Russia" },
        { value: "15", label: "Moonsighting Committee Worldwide" },
        { value: "16", label: "Dubai (experimental)" },
        { value: "17", label: "Jabatan Kemajuan Islam Malaysia (JAKIM)" },
        { value: "18", label: "Tunisia" },
        { value: "19", label: "Algeria" },
        { value: "20", label: "KEMENAG - Kementerian Agama Republik Indonesia" },
        { value: "21", label: "Morocco" },
        { value: "22", label: "Comunidade Islamica de Lisboa" },
        { value: "23", label: "Ministry of Awqaf, Islamic Affairs and Holy Places, Jordan" }
      ]

      property int tick: 0

      function pad2(n) {
        return ("0" + String(n)).slice(-2)
      }

      function formatCountdown(seconds) {
        if (seconds === undefined || seconds === null || seconds < 0) return "--:--:--"
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        var s = Math.floor(seconds % 60)
        return content.pad2(h) + ":" + content.pad2(m) + ":" + content.pad2(s)
      }

      readonly property string countdownText: {
        var _tick = content.tick
        var secs = root.service ? root.service.secondsUntilNextPrayer() : -1
        return content.formatCountdown(secs)
      }

      Timer {
        interval: 1000
        repeat: true
        running: root.opened
        onTriggered: content.tick++
      }

      Column {
        width: parent.width
        spacing: Style.space(4)

        Item {
          width: parent.width
          height: settingsToggle.implicitHeight

          Button {
            id: settingsToggle
            anchors.right: parent.right
            iconText: root.quranOpen ? "\uf053" : (root.settingsOpen ? "\uf053" : "\uf013")
            iconSize: Style.font.title
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            foreground: root.bar ? root.bar.foreground : Color.foreground
            tooltipText: root.service
              ? root.service.tr(root.quranOpen || root.settingsOpen ? "panel.back" : "panel.settings")
              : ((root.quranOpen || root.settingsOpen) ? "Back" : "Settings")
            onClicked: {
              if (root.quranOpen) root.quranOpen = false
              else root.settingsOpen = !root.settingsOpen
            }
          }
        }

        Text {
          width: parent.width
          text: root.service
            ? root.service.tr(root.settingsOpen ? "panel.settings" : "panel.title")
            : (root.settingsOpen ? "Settings" : "Today's Prayer Times")
          color: root.bar ? root.bar.foreground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
          elide: Text.ElideRight
          horizontalAlignment: content.rtl ? Text.AlignRight : Text.AlignLeft
        }
      }

      StackLayout {
        id: pages
        width: parent.width
        height: implicitHeight
        currentIndex: root.settingsOpen ? 1 : 0
        implicitHeight: pages.currentIndex === 0 ? mainPage.implicitHeight : settingsPage.implicitHeight

        Column {
          id: mainPage
          width: parent.width
          spacing: Style.space(8)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.service ? root.service.hijriDateText : ""
            color: Color.urgent
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.bold: true
            visible: text !== ""
          }

          Column {
            width: parent.width
            spacing: Style.space(2)

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.service && root.service.nextPrayerName !== ""
                ? root.service.trf("panel.countdownTo", { name: root.service.displayPrayerName(root.service.nextPrayerName) })
                : (root.service ? root.service.tr("bar.loading") : "Loading...")
              color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.muted
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: content.countdownText
              color: Color.accent
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.display
              font.bold: true
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: root.service ? "[" + root.service.nextPrayerTime + "]" : "[--:--]"
              color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.muted
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.caption
              visible: root.service && root.service.nextPrayerTime !== ""
            }
          }

          PanelSeparator {
            foreground: root.bar ? root.bar.foreground : Color.foreground
          }

          Column {
            width: parent.width
            spacing: Style.space(3)

            Repeater {
              model: root.service ? root.service.prayerList : []

              delegate: Row {
                required property var modelData
                width: parent.width
                spacing: Style.space(8)

                property bool isNext: root.service
                  && modelData.name === root.service.nextPrayerName
                  && modelData.name !== "Imsak"
                  && modelData.name !== "Sunrise"

                Text {
                  text: root.service ? root.service.displayPrayerName(modelData.name) : modelData.name
                  color: parent.isNext ? Color.accent : (root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.muted)
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.bold: parent.isNext
                  font.pixelSize: Style.font.bodySmall
                  horizontalAlignment: content.rtl ? Text.AlignRight : Text.AlignLeft
                  width: parent.width * 0.5
                }

                Text {
                  text: modelData.time
                  color: parent.isNext ? Color.accent : (root.bar ? root.bar.foreground : Color.foreground)
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.bold: parent.isNext
                  font.pixelSize: Style.font.bodySmall
                  horizontalAlignment: Text.AlignRight
                  width: parent.width * 0.5
                }
              }
            }
          }
        }

        PanelSeparator {
          foreground: root.bar ? root.bar.foreground : Color.foreground
        }

        Column {
          id: settingsPage
          width: parent.width
          spacing: Style.space(10)

          onVisibleChanged: {
            if (settingsPage.visible) {
              inputLat.text = root.service ? root.service.latitude : ""
              inputLong.text = root.service ? root.service.longitude : ""
            }
          }

          Dropdown {
            id: calcMethodDropdown
            label: root.service ? root.service.tr("panel.calcMethod") : "Calculation Method"
            value: root.service ? String(root.service.calcMethod) : "20"
            options: content.calcMethodOptions
            foreground: root.bar ? root.bar.foreground : Color.foreground
            width: parent.width
            onChanged: function(v) {
              if (root.service) {
                root.service.calcMethod = parseInt(v, 10)
                root.service.saveState()
                root.service.fetchPrayerTimes()
              }
            }
          }

          Dropdown {
            id: languageDropdown
            label: root.service ? root.service.tr("panel.language") : "Language"
            value: root.service ? root.service.language : "en"
            options: [
              { value: "en", label: "English" },
              { value: "id", label: "Bahasa Indonesia" },
              { value: "ar", label: "العربية" }
            ]
            foreground: root.bar ? root.bar.foreground : Color.foreground
            width: parent.width
            onChanged: function(v) {
              if (root.service) root.service.setLanguage(v)
            }
          }

          PanelSectionHeader {
            text: root.service ? root.service.tr("panel.coords") : "Set Coordinates (Lat / Long):"
            foreground: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.muted
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Row {
            width: parent.width
            spacing: Style.space(6)

            TextField {
              id: inputLat
              placeholderText: root.service ? root.service.tr("panel.latPlaceholder") : "Latitude"
              foreground: root.bar ? root.bar.foreground : Color.foreground
              width: parent.width / 2 - parent.spacing / 2
              Keys.onReturnPressed: saveButton.clicked()
              Keys.onEnterPressed: saveButton.clicked()
            }

            TextField {
              id: inputLong
              placeholderText: root.service ? root.service.tr("panel.longPlaceholder") : "Longitude"
              foreground: root.bar ? root.bar.foreground : Color.foreground
              width: parent.width / 2 - parent.spacing / 2
              Keys.onReturnPressed: saveButton.clicked()
              Keys.onEnterPressed: saveButton.clicked()
            }
          }

          Button {
            id: saveButton
            text: root.service ? root.service.tr("panel.save") : "Save & Refresh"
            foreground: root.bar ? root.bar.foreground : Color.foreground
            width: parent.width
            onClicked: {
              if (root.service) {
                root.service.latitude = inputLat.text
                root.service.longitude = inputLong.text
                root.service.saveState()
                root.service.fetchPrayerTimes()
              }
              root.settingsOpen = false
            }
          }
        }
      }
    }
  }
}