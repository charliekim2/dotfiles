//
// Theme — the whole palette and every metric, in one place.
//
// NOTE the pragma. Quickshell 0.3.1 registers a singleton from the *bare*
// `pragma Singleton` only. The `//@ pragma Singleton` comment form that some
// third-party docs show does NOT work here: the file still resolves as a type,
// but every property reads back `undefined`, which surfaces far away from the
// cause as "Unable to assign [undefined]". Verified by experiment, not docs.
//
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: theme

    // ---------------------------------------------------------------- colour
    //
    // "Plein air": a toned canvas with gouache laid over it. The ground is
    // deliberately warm-slate rather than neutral grey — against a neutral
    // grey the pastels read as neon, against this they read as paint.
    //
    readonly property color ink     : "#1f222a"   // deepest: switcher, scrims
    readonly property color bar     : "#242832"   // the floating bar body
    readonly property color panel   : "#272b35"   // dropdown body
    readonly property color raised  : "#313644"   // cards inside a panel
    readonly property color line    : "#3b4150"   // hairlines

    readonly property color text    : "#ece9e1"   // warm off-white, "paper"
    readonly property color subtext : "#b9b6ad"
    readonly property color muted   : "#7d8494"

    // Each pastel is a landscape note. Keep them equal-weight: no single hue
    // should jump forward, or the bar stops reading as one painting.
    readonly property color sage    : "#a9c4a4"   // foliage
    readonly property color sky     : "#9cc0d8"   // open sky
    readonly property color apricot : "#e8b98d"   // low sun
    readonly property color blush   : "#e3a5ad"   // petals
    readonly property color lilac   : "#bfaed6"   // far hills
    readonly property color seafoam : "#9ed3c4"   // water
    readonly property color butter  : "#e6d29a"   // wheat
    readonly property color clay    : "#d3937c"   // turned earth
    readonly property color poppy   : "#dd8b8b"   // the one alarm colour

    // Cycled by index for workspaces, switcher tiles and per-app notification
    // accents, so colour variety falls out of position and needs no config.
    readonly property var accents: [sage, sky, apricot, lilac, seafoam, blush, butter, clay]

    // Index-safe, and correct for negative indices (JS % keeps the sign).
    function accent(i) {
        const n = accents.length;
        return accents[((i % n) + n) % n];
    }

    // Stable hue per string, so a given app always paints the same colour.
    function accentFor(key) {
        var h = 0;
        for (var i = 0; i < String(key).length; i++)
            h = (h * 31 + String(key).charCodeAt(i)) | 0;
        return accent(h);
    }

    // A pill is a *wash* of its hue, not a slab of it. Solid pastel is reserved
    // for genuine state (focused workspace, muted sink, open panel) — using it
    // for hover as well turns the bar into a wall of colour.
    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    // Same wash, but flattened onto an opaque base. A translucent fill is fine
    // for a pill sitting on the bar, but a card that FLOATS (a toast over the
    // desktop) has nothing behind it, so a 10% wash leaves it 90% see-through
    // and the wallpaper reads straight through the text. Anything that can
    // float must use this instead of tint().
    function over(base, c, a) { return Qt.tint(base, Qt.rgba(c.r, c.g, c.b, a)); }

    readonly property real washIdle  : 0.14
    readonly property real washHover : 0.26
    readonly property real edgeAlpha : 0.30

    // --------------------------------------------------------------- metrics
    //
    // MUST match Hyprland's general:gaps_out (hyprland.lua). The bar, the
    // popups and the tiled windows all sit this far apart, which is the only
    // way the bar reads as one more tile rather than a separate slab. Note
    // Hyprland's gaps_in is HALF the window-to-window gap, so gaps_in 5 and
    // gaps_out 10 both come out as a 10px gutter everywhere.
    readonly property int gapsOut    : 10

    readonly property int barHeight  : 36
    readonly property int barRadius  : 16
    readonly property int barGapTop  : gapsOut
    readonly property int barGapSide : gapsOut
    readonly property int barPadH    : 10

    readonly property int pillHeight : 24
    readonly property int pillPadH   : 10
    readonly property int pillGap    : 6    // within a cluster
    readonly property int clusterGap : 12   // between clusters

    readonly property int panelRadius : 18
    readonly property int cardRadius  : 12

    // ------------------------------------------------------------------ type
    // Noto Sans is what GTK is already set to (gtk-font-name), so the bar
    // matches the apps under it rather than introducing a second UI sans.
    // Ships with Fedora, stays readable at the 12px this bar runs at, and
    // carries `tnum`/`lnum` for the tabular figures the clock and the
    // percentages need.
    readonly property string fontFamily : "IBM Plex Sans"

    // Material Icons Round — the rounded cut echoes the pill geometry.
    // This is NOT a Nerd Font, so glyphs are addressed by codepoint in
    // Icons.qml rather than by the private-use characters a Nerd Font uses.
    readonly property string iconFamily : "Material Icons Round"

    readonly property int fsSmall : 11
    readonly property int fsBody  : 12
    readonly property int fsLarge : 14
    readonly property int fsIcon  : 15

    readonly property int anim : 140
}
