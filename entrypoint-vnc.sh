#!/bin/sh

#CMD ["x11vnc","-nopw","-display","WAIT:1600x960:cmd=FINDCREATEDISPLAY-Xvfb"]
if [ true ]; then
	DISPLAY=:1
	Xvfb ${DISPLAY} -pixdepths 8,16,32  -screen 1  1600x960x16 &
	sleep 20
	DISPLAY=${DISPLAY} /srv/hamclock/hamclockrun &

	x11vnc -nopw --forever -display "${DISPLAY}" -noscr
else
  ## THIS STUFF DOESN"T WORK AND I DONT KNOW WHY!
    DISPLAY=:0
    Xvfb :0 -pixdepths 8,16,32  -screen 1  1600x960x16 &
    sleep 20
    DISPLAY=:0.1 /srv/hamclock/hamclockrun &

    x11vnc -nopw --forever -display ":0" -noscr
fi

