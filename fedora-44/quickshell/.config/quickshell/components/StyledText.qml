// Every piece of prose in the shell goes through here, so the serif and its
// sizes are set in exactly one place.
import QtQuick
import qs

Text {
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fsBody
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering   // hinted stems; a serif at 12px needs it
}
