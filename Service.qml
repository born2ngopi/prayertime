import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string latitude: "-6.2088"
  property string longitude: "106.8456"
  property int calcMethod: 20
  property string language: root.resolveLanguage(Qt.locale().name)

  // --- PERSISTENT SETTINGS ---
  property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy/prayertime.json"

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadState(text())
    onLoadFailed: {
      root.saveState()
      root.fetchPrayerTimes()
    }
    onFileChanged: reload()
  }

  function loadState(raw) {
    if (!raw || raw.trim() === "") { root.fetchPrayerTimes(); return }
    try {
      var data = JSON.parse(raw)
      if (data && data.settings) {
        if (data.settings.latitude !== undefined) root.latitude = data.settings.latitude
        if (data.settings.longitude !== undefined) root.longitude = data.settings.longitude
        if (data.settings.calcMethod !== undefined) root.calcMethod = data.settings.calcMethod
        if (data.settings.language !== undefined) root.language = root.resolveLanguage(data.settings.language)
      }
    } catch (e) {
      console.warn("[PrayerTime] failed to parse state JSON", e)
    }
    root.fetchPrayerTimes()
  }

  function saveState() {
    stateFile.setText(JSON.stringify({
      settings: {
        latitude: root.latitude,
        longitude: root.longitude,
        calcMethod: root.calcMethod,
        language: root.language
      }
    }, null, 2) + "\n")
  }

  property string nextPrayerName: ""
  property string nextPrayerTime: "--:--"
  property string hijriDateText: ""
  property var prayerList: []
  property string lastNotifiedPrayer: ""
  property bool notificationSent: false

  // --- INTERNATIONALIZATION ---
  readonly property var supportedLanguages: ["en", "id", "ar"]
  property var translations: ({})
  property var _enTranslations: ({})
  property string _hijriDay: ""
  property string _hijriMonthNum: ""
  property string _hijriYear: ""

  function resolveLanguage(candidate) {
    var c = String(candidate || "").toLowerCase()
    if (c.indexOf("_") > 0) c = c.split("_")[0]
    return root.supportedLanguages.indexOf(c) >= 0 ? c : "en"
  }

  function urlToPath(url) {
    var s = url.toString()
    if (s.indexOf("file://") === 0) s = s.substring(7)
    try { s = decodeURIComponent(s) } catch (e) {}
    return s
  }

  function i18nFilePath(lang) {
    return root.urlToPath(Qt.resolvedUrl("./i18n/" + lang + ".json"))
  }

  FileView {
    id: i18nFile
    path: root.i18nFilePath(root.language)
    printErrors: false
    onLoaded: root.applyTranslations(text())
    onLoadFailed: root.applyTranslations("")
  }

  FileView {
    id: enFallback
    path: root.i18nFilePath("en")
    printErrors: false
    onLoaded: root._enTranslations = root.parseTranslations(text())
  }

  function parseTranslations(raw) {
    try { return JSON.parse(raw) || {} } catch (e) { return {} }
  }

  function applyTranslations(raw) {
    root.translations = root.parseTranslations(raw)
    root.updateHijriText()
  }

  function setLanguage(lang) {
    root.language = root.resolveLanguage(lang)
    i18nFile.path = root.i18nFilePath(root.language)
    i18nFile.reload()
    root.saveState()
  }

  function tr(key) {
    var t = root.translations
    if (t && t[key] !== undefined && t[key] !== "") return t[key]
    var f = root._enTranslations
    if (f && f[key] !== undefined && f[key] !== "") return f[key]
    return key
  }

  function trf(key, params) {
    var s = root.tr(key)
    if (params) {
      for (var k in params) s = s.split("{" + k + "}").join(String(params[k]))
    }
    return s
  }

  function displayPrayerName(name) {
    return root.tr("prayer." + name)
  }

  function pad2(n) {
    return ("0" + String(n)).slice(-2)
  }

  function updateHijriText() {
    if (root._hijriMonthNum === "") return
    root.hijriDateText = root._hijriDay + " " +
      root.tr("hijri.m" + root.pad2(root._hijriMonthNum)) + " " +
      root._hijriYear + " " + root.tr("hijri.ah")
  }

  function getTodayFormatted() {
    var now = new Date();
    var day = ("0" + now.getDate()).slice(-2);
    var month = ("0" + (now.getMonth() + 1)).slice(-2);
    var year = now.getFullYear();
    return day + "-" + month + "-" + year;
  }

  function fetchPrayerTimes() {
    var dateStr = getTodayFormatted();
    var url = "https://api.aladhan.com/v1/timings/" + dateStr +
      "?latitude=" + latitude +
      "&longitude=" + longitude +
      "&method=" + calcMethod;

    var xhr = new XMLHttpRequest();
    xhr.open("GET", url, true);
    xhr.onreadystatechange = function() {
      if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
        var response = JSON.parse(xhr.responseText);
        if (response && response.code === 200 && response.data) {
          var t = response.data.timings;
          var h = response.data.date.hijri;
          root._hijriDay = h.day;
          root._hijriMonthNum = h.month.number;
          root._hijriYear = h.year;
          root.updateHijriText();
          root.prayerList = [
            { name: "Imsak", time: t.Imsak },
            { name: "Fajr", time: t.Fajr },
            { name: "Sunrise", time: t.Sunrise },
            { name: "Dhuhr", time: t.Dhuhr },
            { name: "Asr", time: t.Asr },
            { name: "Maghrib", time: t.Maghrib },
            { name: "Isha", time: t.Isha }
          ];
          calculateNextPrayer();
          root.notificationSent = false;
          root.lastNotifiedPrayer = "";
          console.log("[PrayerTime] loaded. Next:", root.nextPrayerName, root.nextPrayerTime);
        }
      }
    };
    xhr.send();
  }

  function calculateNextPrayer() {
    if (prayerList.length === 0) return;
    var now = new Date();
    var currentMinutes = now.getHours() * 60 + now.getMinutes();
    for (var i = 0; i < prayerList.length; i++) {
      var name = prayerList[i].name;
      if (name === "Imsak" || name === "Sunrise") continue;
      var timeParts = prayerList[i].time.split(":");
      var prayerMinutes = parseInt(timeParts[0]) * 60 + parseInt(timeParts[1]);
      if (prayerMinutes > currentMinutes) {
        root.nextPrayerName = name;
        root.nextPrayerTime = prayerList[i].time;
        return;
      }
    }
    var fajr = prayerList.find(function(p) { return p.name === "Fajr"; });
    if (fajr) {
      root.nextPrayerName = "Fajr";
      root.nextPrayerTime = fajr.time;
    }
  }

  function checkAndNotify() {
    if (prayerList.length === 0) return;
    var now = new Date();
    var currentMinutes = now.getHours() * 60 + now.getMinutes();
    for (var i = 0; i < prayerList.length; i++) {
      var name = prayerList[i].name;
      if (name === "Imsak" || name === "Sunrise") continue;
      var timeParts = prayerList[i].time.split(":");
      var prayerMinutes = parseInt(timeParts[0]) * 60 + parseInt(timeParts[1]);
      var diff = prayerMinutes - currentMinutes;
      if (diff >= 0 && diff <= 5 && root.lastNotifiedPrayer !== name) {
        root.lastNotifiedPrayer = name;
        root.notificationSent = true;
        Quickshell.execDetached([
          "omarchy-notification-send",
          "-g", "\uf06d",
          "-u", "critical",
          "Prayer Time",
          "It is time for " + name + " prayer."
        ]);
        return;
      }
    }
  }

  Component.onCompleted: {
    console.log("[PrayerTime] service started");
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: {
      root.calculateNextPrayer();
      root.checkAndNotify();
    }
  }
}
