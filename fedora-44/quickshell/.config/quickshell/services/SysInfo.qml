//
// SysInfo — CPU load, memory pressure and package temperature.
//
// Read straight out of /proc and /sys with FileView rather than shelling out
// to top/free/sensors every tick. Those tools read these same files anyway,
// so polling them directly costs no fork and no parsing of human-facing
// output that changes between releases.
//
// The one thing that CANNOT be a fixed path is the temperature sensor. hwmon
// numbering is handed out in probe order and is not stable across reboots —
// the coretemp block is hwmon6 today and may be hwmon3 after the next kernel
// update — so the path is resolved once at startup by sensor *name* and then
// read like any other file.
//
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs

Singleton {
    id: sys

    readonly property int sampleInterval: 2000

    property int  cpu       : 0      // percent
    property int  mem       : 0      // percent
    property int  temp      : 0      // degrees C
    property bool tempKnown : false

    property real memUsedGiB : 0
    property real memTotalGiB: 0

    // /proc/stat counters are cumulative since boot, so a single sample says
    // nothing about current load — it is the DELTA between two that matters.
    // Until two have been taken, report nothing rather than a garbage 100%.
    property real prevIdle : 0
    property real prevTotal: 0
    property bool primed   : false

    property string tempPath: ""

    FileView { id: statFile; path: "/proc/stat";    blockLoading: true }
    FileView { id: memFile;  path: "/proc/meminfo"; blockLoading: true }
    FileView { id: tempFile; path: sys.tempPath;    blockLoading: true }

    Timer {
        interval: sys.sampleInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sys.sample()
    }

    function sample() {
        sys.sampleCpu();
        sys.sampleMem();
        sys.sampleTemp();
    }

    function sampleCpu() {
        statFile.reload();
        const first = statFile.text().split("\n")[0];
        if (!first || first.indexOf("cpu") !== 0) return;

        // cpu  user nice system idle iowait irq softirq steal guest guest_nice
        const n = first.trim().split(/\s+/).slice(1).map(Number);
        if (n.length < 5) return;

        const idle = n[3] + n[4];            // idle + iowait
        var total = 0;
        for (var i = 0; i < n.length; i++) total += n[i];

        const dTotal = total - sys.prevTotal;
        const dIdle  = idle  - sys.prevIdle;
        if (sys.primed && dTotal > 0)
            sys.cpu = Math.max(0, Math.min(100,
                Math.round(100 * (dTotal - dIdle) / dTotal)));

        sys.prevTotal = total;
        sys.prevIdle  = idle;
        sys.primed    = true;
    }

    function sampleMem() {
        memFile.reload();
        const t = memFile.text();
        const total = sys.field(t, "MemTotal");
        // MemAvailable, NOT MemFree. Free excludes page cache and reclaimable
        // slab, so it would report this box as nearly full while it is in fact
        // mostly idle with a warm cache.
        const avail = sys.field(t, "MemAvailable");
        if (total <= 0 || avail < 0) return;

        sys.memTotalGiB = total / 1048576;
        sys.memUsedGiB  = (total - avail) / 1048576;
        sys.mem = Math.round(100 * (total - avail) / total);
    }

    function field(text, key) {
        const m = new RegExp("^" + key + ":\\s+(\\d+)", "m").exec(text);
        return m ? parseInt(m[1], 10) : -1;
    }

    function sampleTemp() {
        if (sys.tempPath.length === 0) return;
        tempFile.reload();
        const raw = parseInt(tempFile.text().trim(), 10);
        if (isNaN(raw)) return;
        sys.temp = Math.round(raw / 1000);   // hwmon reports millidegrees
        sys.tempKnown = true;
    }

    // Resolve the CPU temperature sensor once, by name: coretemp is Intel,
    // k10temp and zenpower are AMD. "Package id 0" / "Tctl" is the die-wide
    // reading, which is what a bar wants — an individual core spikes on any
    // single-threaded burst and tells you nothing useful.
    Process {
        running: true
        command: ["sh", "-c",
            'for h in /sys/class/hwmon/hwmon*; do ' +
              'n=$(cat "$h/name" 2>/dev/null) || continue; ' +
              'case "$n" in coretemp|k10temp|zenpower) ;; *) continue ;; esac; ' +
              'for l in "$h"/temp*_label; do ' +
                '[ -e "$l" ] || continue; ' +
                'case "$(cat "$l" 2>/dev/null)" in ' +
                  'Package*|Tctl*) echo "${l%_label}_input"; exit 0 ;; ' +
                'esac; ' +
              'done; ' +
              '[ -e "$h/temp1_input" ] && { echo "$h/temp1_input"; exit 0; }; ' +
            'done']

        stdout: SplitParser {
            onRead: line => {
                const p = line.trim();
                if (p.length > 0) {
                    sys.tempPath = p;
                    sys.sampleTemp();
                }
            }
        }
    }

    // Keep the pill's own hue while things are calm, and escalate only when
    // the number is worth looking at. A bar that is permanently amber trains
    // you to ignore it.
    function pressure(base, value, warn, crit) {
        if (value >= crit) return Theme.poppy;
        if (value >= warn) return Theme.butter;
        return base;
    }
}
