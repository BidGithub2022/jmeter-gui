# jmeter-gui

docker build -t quay.io/mailtobidyut/images/jmeter-fedora-2 --platform=linux/amd64 .


JMeter GUI access via browser:
- Headless X11 display (Xvfb)
- Lightweight window manager (Fluxbox)
- Remote access(x11vnc)
- Web based VNC viewer (noVNC)
- Process controller (supervisord)

1. Xvfb(X virtual framebuffer)
   Creates a virtual display.
   Jmeter GUI needs a X11 display for its window.

2. Fluxbox(Window manager)
   Provides window management- minimal desktop environment.
   Xvfb provides display , Fluxbox handles JMeter windows inside the display.

3. JMeter GUI:
   Launches JMeter application with a GUI.

4. x11VNC (VNC Server for X11)
   Bridges the virtual X11 display (:1) to a VNC protocol server on port 5901.
   It allows remote access to the virtual desktop so that we can control it from browser or VNC client.

5. noVNC(Web VNC client)
   A browser based VNC client that connects to the VNC server and shows the GUI on the browser.

6. Supervisord
   Manages all background processes: Xvfb, x11vnc, fluxbox,novnc.
   containers need a "main" process (PID 1) and you want all  your services running together.
   It used the /etc/supervisord.d/supervisord.conf with multiple [program:*] entries.


FLow:
1. Container starts with /startup.sh
2. Creates required dirs, starts supervisord.
3. supervisord launches:
   Xvfb -> virtual display :1
   fluxbox -> wundow namager
   x11vnc -> VNC server on port 5901
   noVNC -> WebSocket proxy on port 6080
4. Fluxbox runs ~/.fluxbox/startup, which launches jmeter
5. GUI is accessible at https://<app url>/vnc.html
  

