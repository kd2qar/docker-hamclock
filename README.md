# docker-hamclock
Run hamclock from within a docker container

You can build it two ways. Using the web version (smaller)
or the x11 version running in a VNC session.
Modify the docker-compose.yaml file in the x-anchors section

You can also change the base OS to either alpine or a debian based system
Modify the docker-compose.yaml file in the x-anchors section

NOTE: the combination of 'web' and 'alpine' results in the smallest container size


Use the RESTful api to manipulate the behavior and  grap 'screen shots' of
the display and grab the screen images.


user guide: https://www.clearskyinstitute.com/ham/HamClock/HamClockKey.pdf

ports:
8088: 	RESTful web api (curl http://<server>:8088/  for list)
8091:   web interactive web user interface (When run_type is web Open http://<server>:8091/live.html)
8092:	web static web view (when run_type is web Open http://<server>:8092/live.html)
5099:	vnc port (when run_type is vnc)

