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

  // Vertical bars (left/right) are too narrow for "Asr: 14:46", so stack the
  // label like the built-in clock: name, then the time as HH / — / mm.
  readonly property var verticalLines: {
    if (!root.vertical) return []
    var lines = []
    lines.push(service && service.nextPrayerName !== ""
      ? service.displayPrayerName(service.nextPrayerName) : "--")
    var t = service ? service.nextPrayerTime : ""
    var p = t.split(":")
    if (p.length === 2) lines.push(p[0], "\u2014", p[1])
    else lines.push("--", "\u2014", "--")
    return lines
  }

  readonly property bool vertical: button.vertical

  // Shrink long lines (prayer names) so they fit the narrow vertical slot.
  function glyphFontSize(text) {
    var base = button.fontSize
    var n = String(text || "").length
    if (n <= 3) return base
    var width = button.width > 0 ? button.width : Style.bar.sizeHorizontal
    var fit = Math.floor((width - 2) / (n * 0.6))
    return Math.max(6, Math.min(base, fit))
  }

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
    text: root.vertical ? "" : root.label
    labelVisible: !root.vertical
    hasVisualContent: root.vertical ? root.verticalLines.length > 0 : text !== ""
    fixedHeight: root.vertical ? root.verticalLines.length * Style.bar.iconSlot : -1
    horizontalMargin: 8.75
    verticalPadding: 8.75
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

    Column {
      visible: root.vertical
      anchors.fill: parent

      Repeater {
        model: root.verticalLines

        OpticalGlyph {
          required property var modelData
          width: button.width
          height: Style.bar.iconSlot
          text: modelData
          fontFamily: button.fontFamily
          fontSize: root.glyphFontSize(modelData)
          color: button.foreground
        }
      }
    }
  }
}