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

  readonly property var service: root.bar && root.bar.shell
    ? root.bar.shell.serviceFor("born2ngopi.prayertime") : null

  function open() { root.controller.show() }
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

      Column {
        width: parent.width
        spacing: Style.space(2)

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.service ? root.service.tr("panel.title") : "Today's Prayer Times"
          color: root.bar ? root.bar.foreground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.service ? root.service.hijriDateText : ""
          color: Color.urgent
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          visible: text !== ""
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

      PanelSeparator {
        foreground: root.bar ? root.bar.foreground : Color.foreground
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

      Text {
        text: root.service ? root.service.tr("panel.coords") : "Set Coordinates (Lat / Long):"
        color: root.bar ? Qt.darker(root.bar.foreground, 1.4) : Color.muted
        font.family: root.bar ? root.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.caption
        horizontalAlignment: content.rtl ? Text.AlignRight : Text.AlignLeft
        width: parent.width
      }

      Row {
        width: parent.width
        spacing: Style.space(6)

        TextField {
          id: inputLat
          placeholderText: root.service ? root.service.tr("panel.latPlaceholder") : "Latitude"
          text: root.service ? root.service.latitude : ""
          foreground: root.bar ? root.bar.foreground : Color.foreground
          width: parent.width / 2 - parent.spacing / 2
          Keys.onReturnPressed: saveButton.clicked()
          Keys.onEnterPressed: saveButton.clicked()
        }

        TextField {
          id: inputLong
          placeholderText: root.service ? root.service.tr("panel.longPlaceholder") : "Longitude"
          text: root.service ? root.service.longitude : ""
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
          root.close()
        }
      }
    }
  }
}