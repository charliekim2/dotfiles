// Every piece of prose in the shell goes through here, so the serif and its
// sizes are set in exactly one place.
import QtQuick
import qs

Text {
    color: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fsBody
    font.weight: Font.Medium           // 400 reads thin at 12px on this bar
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering   // hinted stems; a serif at 12px needs it
}
