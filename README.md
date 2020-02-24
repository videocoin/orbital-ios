# Introduction

This open-source project demonstrates how to interact with the VideoCoin Network from an iOS app, as well as integrate the network to your own backend service. You will also find a full implementation of RTMP streaming and HLS playback in iOS using standard or open-sorce solutions, with a detailed instruction below, to further assist your integration with the VideoCoin Network.

For instructions that are not listed here, see: https://docs.videocoin.network/developers

# Setup

## Installation

1. Run `setup.sh` in the project directory. 
2. Make sure the target is set to `OrbitalApp` in the automatically-opened Xcode project.

## Firebase Configuration

This app will communicate with a Firebase database which you will have set up and configured in a specific format.

1. Open the Firebase console: https://console.firebase.google.com/
2. Create a new Firebase project.
3. Add a new iOS project and follow the steps to add the .plist file, Firebase dependencies, and initialization code.
4. Follow the specification of the Firebase project here: https://liveplanet.atlassian.net/wiki/spaces/V/pages/655032321/Orbital+app+-+Firebase
5. Run the iOS app on a local device or emulator to verify proper Firebase configuration.

# Targets

A variety of targets are available to help debug any issues with streaming video to the VideoCoin network.

- VideoCoin -- Distributable framework to interact with the VideoCoin Network in Swift language.
- VideoCoinTest -- Tests for VideoCoin framework.
- VideoCoinHost -- Dummy app to run VideoCoinTest.
- orbitalApp -- Orbital app.
- vlcDebug -- App to debug VLC framework.
- haishinkitDebug -- App to debug HaishinKit framework.
- RtmpDebug -- App to debug RTMP streaming.
- AVPlayerDebug -- App to debug AVPlayer stream playback.

# Testing & Debugging

## Debugging VideoCoin Network

Run `VideoCoinTest/VideoCoinTest.swift`.

## Debugging RTMP Playback

Run `vlcDebug` app.

## Debugging RTMP Streaming

Run `haishinkitDebug` app.
Set your desired RTMP desination path in `ViewControlelr` class.
To set up a local RTMP server, see guidelines below.

## Debugging Firebase Authentication

Run `firebaseDebug` app.

# Setting Up Local RTMP Server (Mac)

This section will help you debug RTMP streaming & playback via your own local RTMP server.

Use [NGINX](https://www.nginx.com/) to host a RTMP server.

    $ brew tap marcqualie/nginx
    $ brew install nginx-full --with-rtmp-module
    $ nginx -V

Open the config file:

    $ open /usr/local/etc/nginx/nginx.conf

Modify the port from `8080` to `80`:

    http {
        server {
            listen       80;  ## Modify 8080 → 80
            server_name  localhost;
            #charset koi8-r;
            #access_log  logs/host.access.log  main;
            location / {
                root   html;
                index  index.html index.htm;
            }
        }
    }

Add RTMP configuration:

    rtmp {
        server {
            listen 1935;
            application live { ## `live` will become the path
                live on;
                hls  on;
                record off;
                hls_path /usr/local/nginx/html/;
                hls_fragment 1s;
                hls_type live;
            }
        }
    }

Run the server:

    $ sudo nginx

Open your web browser and access `localhost:80`. 

You'll see the "Welcome" page.

## Setting Up Live Video Streaming

Use [OBS](https://obsproject.com/) to stream a live video into the RTMP server.

Download & install the OBS app via the official download page:
[https://obsproject.com/](https://obsproject.com/)

Open the setup wizard on the app launch (or `Tools > Auto Configuration Wizard`).

In *Stream Information* page, enter:

    Service: Custom...
    Server: rtmp://127.0.0.1/live
    Stream Key: blablabla

Make sure that the wizard goes through some tests on streaming optimization at the end.

In the main windowm, set up *Display Capture* in the `Sources` list at the bottom of the app window.

You'll see the main view displaying the screen capture.

Hit `Start Streaming` button at the bottom right of the app window.

## Setting Up Live Video Playback

Use [VLC](https://www.videolan.org/vlc/index.html) to play a live video hosted in the RTMP server.

Download & install the VLC app via the official download page:
[https://www.videolan.org/vlc/index.html](https://www.videolan.org/vlc/index.html)

Open `File > Open Network...` and enter:

    URL: rtmp://127.0.0.1/live/blablabla

Press `Open` and you'll have a new window pop up which displays the desktop screen.

Press `Command + Shift + M` to open a logger view in case the playback won't start.

## Setting Up Live Video Playback (iOS)

Use [VLC for iOS](https://www.videolan.org/vlc/download-ios.html).

## Debugging iOS App Using Local RTMP Server

1. Make sure your iOS device is connected to the same WiFi as the host server.
1. In the host computer, open *Network Utility*, navigate to *Info* tab and note the *IP Address*.
1. In your iOS app, connect to the IP address and play/stream a live video.
