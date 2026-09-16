import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "widgets"
import "components"
import "settings"

ShellRoot {
    id: root

    // ── NOTIFICATIONS ──
    Notifications {}

    // ── CONTROLCENTER ──
    ControlCenter {}

    // ── WEATHER ──
    property bool   weatherVisible: false
    property bool   weatherOnTop:   false
    property string weatherLoc: "Loading..."
    property string weatherCond: "..."
    property string weatherTemp: "--"
    property string weatherWind: "--"
    property string weatherHum: "--"

    Process {
        id: weatherProc
        command: ["sh", "-c", "curl -s 'wttr.in/?format=%l|%c|%C|%t|%w|%h' || echo 'Unavailable'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var w = data.trim()
                if (w !== "" && w !== "Unavailable" && w.indexOf("|") !== -1) {
                    var parts = w.split("|")
                    if (parts.length >= 6) {
                        root.weatherLoc  = parts[0].toUpperCase()
                        root.weatherCond = (parts[1] + " " + parts[2]).toUpperCase()
                        root.weatherTemp = parts[3]
                        root.weatherWind = parts[4]
                        root.weatherHum  = parts[5]
                    }
                }
            }
        }
    }
    Timer { interval: 1800000; running: true; repeat: true; onTriggered: weatherProc.running = true }

    property string currentUser: "user"
    Process {
        id: getUserProc; command:["sh","-c","echo $USER"]; running:true
        stdout: SplitParser { onRead: data => { var u=data.trim(); if(u!=="") root.currentUser=u } }
    }

    property int _lastToggle: 0; property int _lastFront: 0
    property int _lastMenu:   0

    Process { id:chkToggle; command:["sh","-c","wc -l < /tmp/qs-toggle 2>/dev/null || echo 0"]; running:false
        stdout:StdioCollector{ onStreamFinished:{ var n=parseInt(this.text.trim())||0; if(n!==root._lastToggle){root._lastToggle=n;root.weatherVisible=!root.weatherVisible} }}
    }
    Process { id:chkFront; command:["sh","-c","wc -l < /tmp/qs-front 2>/dev/null || echo 0"]; running:false
        stdout:StdioCollector{ onStreamFinished:{ var n=parseInt(this.text.trim())||0; if(n!==root._lastFront){root._lastFront=n;root.weatherOnTop=!root.weatherOnTop} }}
    }
    Process { id:chkMenu; command:["sh","-c","wc -l < /tmp/qs-menu 2>/dev/null || echo 0"]; running:false
        stdout:StdioCollector{ onStreamFinished:{ var n=parseInt(this.text.trim())||0; if(n!==root._lastMenu){root._lastMenu=n;detectMonitor.running=true} }}
    }

    Timer { interval:200; running:true; repeat:true
        onTriggered:{ chkToggle.running=true;chkFront.running=true;chkMenu.running=true }
    }

    Component.onCompleted: {
        Qt.createQmlObject(
            'import Quickshell.Io; Process{command:["sh","-c","rm -f /tmp/qs-menu /tmp/qs-toggle /tmp/qs-front"];running:true}',
            root, "cleanup")
    }

    property string menuActiveMonitor: Quickshell.screens.length>0 ? Quickshell.screens[0].name : ""
    signal menuFireToggle()

    Process {
        id: detectMonitor
        command: ["/bin/sh", Qt.resolvedUrl("active-monitor.sh").toString().replace("file://","")]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var name = this.text.trim()
                if (name !== "") root.menuActiveMonitor = name
                root.menuFireToggle()
            }
        }
    }






    // ── MENU ──
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen:modelData
            anchors.top:true;anchors.left:true;anchors.right:true;anchors.bottom:true
            exclusionMode:ExclusionMode.Ignore
            aboveWindows:menuItem.menuOpen||menuItem.wipeHideRunning
            color:"transparent"
            WlrLayershell.keyboardFocus:menuItem.menuOpen?WlrKeyboardFocus.Exclusive:WlrKeyboardFocus.None
            implicitWidth:modelData.width;implicitHeight:modelData.height
            Menu{id:menuItem;anchors.fill:parent;screenW:modelData.width;screenH:modelData.height}
            Connections{target:root;function onMenuFireToggle(){
                if(root.menuActiveMonitor!==modelData.name)return
                if(menuItem.menuOpen)menuItem.closeMenu();else menuItem.openMenu()
            }}
        }
    }


    // ── WEATHER ──
    Variants {
        model:Quickshell.screens
        PanelWindow {
            required property var modelData;screen:modelData
            anchors.top:true;anchors.right:true
            margins.top:Math.round(modelData.height*Settings.playerPositionY);margins.right:20
            exclusionMode:ExclusionMode.Ignore;aboveWindows:root.weatherOnTop;color:"transparent"
            implicitWidth:Settings.playerWidth;implicitHeight:weatherItem.implicitHeight
            Weather{id:weatherItem;anchors.fill:parent
                weatherLoc:  root.weatherLoc
                weatherCond: root.weatherCond
                weatherTemp: root.weatherTemp
                weatherWind: root.weatherWind
                weatherHum:  root.weatherHum
            }
            Connections{target:root;function onWeatherVisibleChanged(){weatherItem.toggleVisible()}}
        }
    }
}
