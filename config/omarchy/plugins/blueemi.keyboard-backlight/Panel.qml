import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import qs.Commons as Commons

// Keyboard backlight bar widget.
//   Left click   open the panel (slider + on/off switch)
//   Right/middle toggle the backlight off, or back on at the last level
//   Scroll       step brightness by 5%
// Reads sysfs directly (no process per poll) and writes through brightnessctl,
// the same tool omarchy-brightness-keyboard uses, so the Ctrl+brightness keys
// and this widget stay in sync.
Panel {
  id: root
  moduleName: "blueemi.keyboard-backlight"
  ipcTarget: "blueemi.keyboard-backlight"

  readonly property string device: "apple::kbd_backlight"
  readonly property string devicePath: "/sys/class/leds/" + device

  property bool available: false
  property int maxLevel: 0
  property int percent: 0
  // Level to come back to when switched on again.
  property int lastOnPercent: 50
  property int pendingPercent: 0
  property bool setQueued: false
  property real wheelAccumulator: 0
  property bool cursorActive: false
  // "slider" or "switch"
  property string focusSection: "slider"

  readonly property bool isOn: percent > 0
  readonly property string glyphOn: String.fromCodePoint(0xF030C)
  readonly property string glyphOff: String.fromCodePoint(0xF0310)

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function readNumber(file) {
    file.reload()
    file.waitForJob()
    var n = parseInt(String(file.text() || "").trim(), 10)
    return isFinite(n) ? n : -1
  }

  function refresh() {
    // Don't clobber the value we just wrote while it is still being applied.
    if (setProc.running || setQueued) return
    var max = readNumber(maxFile)
    if (!(max > 0)) { available = false; return }
    var level = readNumber(levelFile)
    if (level < 0) { available = false; return }
    available = true
    maxLevel = max
    percent = Math.round(100 * level / max)
    if (percent > 0) lastOnPercent = percent
  }

  function setPercent(value) {
    if (!available) return
    var p = Math.max(0, Math.min(100, Math.round(value)))
    percent = p
    if (p > 0) lastOnPercent = p
    pendingPercent = p
    if (setProc.running) { setQueued = true; return }
    setQueued = false
    var raw = Math.round(p * maxLevel / 100)
    setProc.command = ["brightnessctl", "-q", "-d", device, "set", String(raw)]
    setProc.running = true
  }

  function toggleLight() {
    setPercent(isOn ? 0 : Math.max(5, lastOnPercent))
  }

  function showOsd() {
    if (!bar || !bar.shell) return
    bar.shell.summon("omarchy.osd", JSON.stringify({
      icon: "keyboard",
      message: "",
      value: String(percent),
      progressText: Commons.I18n.formatNumber(percent) + "%",
      max: "100",
      duration: ""
    }))
  }

  Component.onCompleted: refresh()

  onOpenedChanged: {
    if (opened) {
      refresh()
      focusSection = "slider"
      cursorActive = false
    }
  }

  // Cheap sysfs read; keeps the bar glyph honest when the keys change it.
  Timer {
    interval: root.opened ? 1000 : 4000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  FileView {
    id: levelFile
    path: root.devicePath + "/brightness"
    blockLoading: true
    printErrors: false
  }

  FileView {
    id: maxFile
    path: root.devicePath + "/max_brightness"
    blockLoading: true
    printErrors: false
  }

  Process {
    id: setProc
    onRunningChanged: {
      if (running) return
      if (root.setQueued) root.setPercent(root.pendingPercent)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    visible: root.available
    text: root.isOn ? root.glyphOn : root.glyphOff
    opacity: root.isOn ? 1 : 0.55
    tooltipText: root.isOn
      ? strings.t("tooltip").arg(Commons.I18n.formatNumber(root.percent) + "%")
      : strings.t("tooltipOff")
    onPressed: function(b) {
      if (b === Qt.RightButton || b === Qt.MiddleButton) {
        root.toggleLight()
        root.showOsd()
      } else {
        root.toggle()
      }
    }
    onWheelMoved: function(delta) {
      if (!root.available) return
      var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
      root.wheelAccumulator = wheel.remainder
      if (wheel.steps === 0) return
      root.setPercent(root.percent + wheel.steps * 5)
      root.showOsd()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(300))

    content: PanelKeyCatcher {
      implicitHeight: panelColumn.implicitHeight
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        if (dy !== 0) root.focusSection = dy > 0 ? "slider" : "switch"
        else if (dx !== 0 && root.focusSection === "slider") root.setPercent(root.percent + dx * 5)
      }
      onActivateRequested: root.toggleLight()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.space(14)

        PanelHero {
          title: strings.t("title")
          meta: !root.available ? strings.t("unavailable")
                : root.isOn ? Commons.I18n.formatNumber(Math.round(slider.dragging ? slider.liveValue : root.percent)) + "%"
                : strings.t("off")
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          iconComponent: Component {
            Text {
              textFormat: Text.PlainText
              text: root.isOn ? root.glyphOn : root.glyphOff
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
            }
          }
          trailingControl: Component {
            ToggleSwitch {
              checked: root.isOn
              enabled: root.available
              foreground: root.bar.foreground
              hasCursor: root.cursorActive && root.focusSection === "switch"
              onToggled: root.toggleLight()
              onHovered: function(h) { if (h) { root.cursorActive = true; root.focusSection = "switch" } }
            }
          }
        }

        PanelSeparator {
          visible: root.available
          foreground: root.bar.foreground
        }

        Column {
          visible: root.available
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: strings.t("brightness")
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          CursorSurface {
            id: sliderRow
            width: parent.width
            height: slider.implicitHeight + Style.spacing.controlGap
            hasCursor: root.cursorActive && root.focusSection === "slider"
            foreground: root.bar.foreground
            outline: true

            PanelSlider {
              id: slider
              bar: root.bar
              anchors.fill: parent
              anchors.leftMargin: Style.space(6)
              anchors.rightMargin: Style.space(6)
              minimum: 0
              maximum: 100
              step: 1
              integer: true
              value: root.percent
              onMoved: function(v) { root.setPercent(v) }
              onReleased: function(v) { root.setPercent(v) }
            }

            HoverHandler {
              onHoveredChanged: if (hovered) { root.cursorActive = true; root.focusSection = "slider" }
            }
          }
        }
      }
    }
  }
}
