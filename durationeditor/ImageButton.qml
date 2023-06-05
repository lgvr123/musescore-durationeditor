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
/*  - 1.2.2: Use of palettes color
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

        color: smbtn.down ? sysActivePalette.shadow : (smbtn.hovered ? sysActivePalette.mid : (smbtn.highlighted?sysActivePalette.highlight:"transparent"))
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
        opacity: smbtn.enabled?1:0.2
        mipmap: true // smoothing
        anchors.centerIn: parent
    }

    hoverEnabled: true
    ToolTip.delay: 1000
    ToolTip.timeout: 5000
    ToolTip.visible: hovered

    
    SystemPalette {
        id: sysActivePalette;
        colorGroup: SystemPalette.Active
    }
    SystemPalette {
        id: sysDisabledPalette;
        colorGroup: SystemPalette.Disabled
    }

}
