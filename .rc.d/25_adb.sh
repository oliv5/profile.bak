#!/bin/sh
# https://thangamaniarun.wordpress.com/2013/04/19/useful-android-adb-commands-over-usbwi-fi/

#Connect adb over wi-fi
adb_wifi() {
    adb shell setprop service.adb.tcp.port 5555 && stop adbd && start adbd
    adb connect
}

#Unlock your Android screen
adb_unlock() {
    adb shell input keyevent 82
}

#Lock your Android screen
adb_lock() {
    adb shell input keyevent 6
    adb shell input keyevent 26
}

#Open default browser
adb_browser() {
    adb shell input keyevent 23
}

#Keep your android phone volume up(+)
adb_volp() {
    adb shell input keyevent 24
}

#Keep your android phone volume down(-)
adb_voln() {
    adb shell input keyevent 25
}

#Go to your Android Home screen
adb_home() {
    adb shell input keyevent 3
}

#Take Screenshot from adb
adb_screenshot() {
    adb shell screenshot /sdcard/test.png
}

#Another Screen capture command
#screencap [-hp] [-d display-id] [FILENAME]
# -h: this message
# -p: save the file as a png.
# -d: specify the display id to capture, default 0

#start clock app
adb_clock_start() {
    adb shell am start com.google.android.deskclock
}

#stop clock app
adb_clock_stop() {
    adb shell am force-stop com.google.android.deskclock
}

#start wifi settings manager
adb_wifi_mgr() {
    adb shell am start -a android.intent.action.MAIN -n com.android.settings/.wifi.WifiSettings
}

#Testing wifi status – Thanks Saimadhu
adb_wifi_status() {
    adb shell am start -n com.android.settings/.wifi.WifiStatusTest
}

#Below commands only works on Rooted Devices – Thanks Pooja Shah for asking the questions
#wifi on
adb_wifi_on() {
    adb shell svc wifi enable
}

#wifi off
adb_wifi_off() {
    adb shell svc wifi disable
}

#Mobile Data on
adb_data_on() {
    adb shell svc data enable
}

#Mobile Data off
adb_data_off() {
    adb shell svc data disable
}
