// A Material Icons glyph sized and centred like a character of body text.
//
// renderType is deliberately left at the default (distance-field) here, the
// opposite of StyledText: NativeRendering snaps icon outlines to the pixel
// grid and visibly deforms the round Material shapes at 15px, while text at
// the same size needs that snapping to stay crisp.
import QtQuick
import qs

Text {
    color: Theme.text
    font.family: Theme.iconFamily
    font.pixelSize: Theme.fsIcon
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
