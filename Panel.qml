import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "born2ngopi.prayertime"

  readonly property var service: root.bar && root.bar.shell
    ? root.bar.shell.serviceFor("born2ngopi.prayertime") : null

  readonly property string label: service
    ? (service.nextPrayerName
        ? service.displayPrayerName(service.nextPrayerName) + ": " + service.nextPrayerTime
        : service.tr("bar.loading"))
    : "--:--"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item && panelLoader.item.closeForPopoutSwitch) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Popup.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.label
    fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
    tooltipText: root.service ? root.service.tr("bar.tooltip") : "Prayer Time"

    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.RightButton) {
        if (root.service) root.service.fetchPrayerTimes()
      } else {
        root.togglePanel()
      }
    }
  }
}