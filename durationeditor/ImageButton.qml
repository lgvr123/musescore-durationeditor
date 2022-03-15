import QtQuick 2.9
import QtQuick.Controls 2.2

/**********************
/* Parking B - ImageButton
/* v1.2.1
/* ChangeLog:
/* 	- 1.1.0: Initial release
/* 	- 1.1.0: New color for Disabled mode
/* 	- 1.2.0: New fillMode option
/*  - 1.2.1: Sizing corrections
/**********************************************/

Button {
    id: smbtn
    property var imageSource: ""
    property alias imageHeight: img.height
    property alias imageWidth: img.width
    property int imagePadding: 3
	property alias imageFillMode: img.fillMode 
    font.pointSize: 7
    implicitWidth: img.width + imagePadding * 2
    implicitHeight: img.height + imagePadding * 2
    background: Rectangle {
        implicitWidth: smbtn.width
        implicitHeight: smbtn.height

        color: smbtn.down ? "#C0C0C0" : (smbtn.enabled?(smbtn.hovered ? "#D0D0D0" : (smbtn.highlighted?"lightsteelblue":"transparent" /*"#E0E0E0"*/)):"#D7CEE0")
        //border.color: "red"
        //border.width: 1
        radius: 4
    }
    indicator:
    Image {
		id: img
        source: smbtn.imageSource
        height: 18
        fillMode: Image.PreserveAspectFit // ensure it fits
        mipmap: true // smoothing
        anchors.centerIn: parent
    }

    hoverEnabled: true
    ToolTip.delay: 1000
    ToolTip.timeout: 5000
    ToolTip.visible: hovered

}
