###
#
#  BUILD HAMCLOCK image
#
ARG COMPOSE_PROJECT_NAME
ARG BUILDER_IMAGE
ARG ROOT_IMAGE=alpine
ARG RUN_TYPE=vnc
ARG DIMENSIONS=1600x960

#FROM debian:stable-slim AS root
FROM ${ROOT_IMAGE} AS root
ENV DEBIAN_FRONTEND=noninteractive
LABEL org.opencontainers.image.authors="Mark Vincett kd2qar@gmail.com"
RUN <<-ROOTINSTALL
	if [ -f /usr/bin/apt ]; then
	  apt-get update \
	  && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
	  libc6 curl && \
	  rm -rf /var/lib/apt/lists/*
	fi
	if [ -f /sbin/apk ]; then
	  apk add curl libstdc++
	fi
	ROOTINSTALL

RUN <<-STUFF
	if [ -f ~/.bashrc ]; then 
	  sed  's/# alias/ alias/g' -i ~/.bashrc; 
	  sed 's/# export/ export/g' -i ~/.bashrc; 
	  sed "s/alias ll='ls "'$LS_OPTIONS'" -l'/alias ll='ls "'$LS_OPTIONS'" -lAh'/g" -i ~/.bashrc; 
	else 
	  cat <<-ECHO >>/root/.bashrc
		alias ls='ls --color -a'
		alias ll='ls -alh'
		ECHO
	  sed  "s/alias ll='ls -alF'/# alias ll='ls -alF'/g" -i ~/.bashrc; 
	  sed "s/alias la='ls -A'/# alias la='ls -A'/g" -i ~/.bashrc; 
	  sed "s/alias l='ls -CF'/# alias l='ls -CF'/g" -i ~/.bashrc; 
	fi ;
	echo "set background=dark" >>/etc/vim/vimrc.local; 
	if [ -f /etc/default/vimrc.vim ]; then 
	    echo "source /etc/default/vimrc.vim">>~/.vimrc; 
	else 
	  echo "\"source /etc/vim/vimrc">>~/.vimrc; 
	fi; 
	echo "set background=dark">>~/.vimrc; 
	echo "set mouse=">>~/.vimrc; 
	echo "alias ls='ls --color -a'" >>/root/.bash_aliases; 
	echo "alias ll='ls -alh'" >>/root/.bash_aliases; 
	STUFF

## DOWNLOADER STAGE
FROM root as buildstage
################# BUILDER STAGE
ARG DIMENSIONS
ARG RUN_TYPE

WORKDIR /tmp

RUN <<-BUILDTOOLS
	if [ -f /usr/bin/apt ]; then
	  apt-get update \
	  && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
	  make g++ libx11-dev build-essential xorg-dev && \
	  rm -rf /var/lib/apt/lists/*
	fi
	if [ -f /sbin/apk ]; then
	  apk add make g++ libx11-dev perl # linux-headers
	fi
	BUILDTOOLS

## DOWNLOAD STAGE

WORKDIR /hamclock

## dowload may change
# 72.167.43.150
#ADD https://www.clearskyinstitute.com/ham/HamClock/ESPHamClock.tgz /hamclock/
#ADD https://72.167.43.150/ham/HamClock/ESPHamClock.tgz /hamclock/
COPY ./ESPHamClock.tgz /hamclock/ 

RUN tar xzf ESPHamClock.tgz && rm ESPHamClock.tgz

## BUILDSTAGE STAGE

WORKDIR /hamclock/ESPHamClock

RUN <<-MAKEIT
	HAMCLOCKTARGET=hamclock$(if [ ${RUN_TYPE} = web ]; then echo "-web"; else echo "";fi)-${DIMENSIONS}
	make clean && \
	make -j 4 "${HAMCLOCKTARGET}" && \
	mv "${HAMCLOCKTARGET}" /hamclock/hamclock ;
	MAKEIT

## NOTE: you must run 'make clean' between each build or they will not work
#RUN make clean && make -j 4 hamclock-web-${DIMENSIONS}  && mv hamclock-web-${DIMENSIONS} /hamclock/ ;
#RUN make clean && make -j 4 hamclock-${DIMENSIONS}     && mv hamclock-${DIMENSIONS} /hamclock/ ;

# 800x480
#RUN make clean && make -j 4 hamclock-fb0-800x480  && mv hamclock-fb0-800x480 /hamclock/ ;
#RUN make clean && make -j 4 hamclock-web-800x480  && mv hamclock-web-800x480 /hamclock/ ;
#RUN make clean && make -j 4 hamclock-800x480      && mv hamclock-800x480 /hamclock/ ;

# 1600x960
#RUN make clean && make -j 4 hamclock-fb0-1600x960 && mv hamclock-fb0-1600x960 /hamclock/ ;
#RUN make clean && make -j 4 hamclock-web-1600x960  && mv hamclock-web-1600x960 /hamclock/ ;
#RUN make clean && make -j 4 hamclock-1600x960     && mv hamclock-1600x960 /hamclock/ ;

# fb0 is 1920 x 1080 x 16
#RUN make clean && make -j 4 hamclock-fb0-2400x1440 && mv hamclock-fb0-2400x1440 /hamclock/ ;
#RUN make clean && make -j 4 hamclock-web-2400x1440  && mv hamclock-web-2400x1440 /hamclock/ ;
#RUN make clean && make -j 4 hamclock-2400x1440     && mv hamclock-2400x1440 /hamclock/ ;

# hamclock-fb0-3200x1920
#RUN make clean && make -j 4 hamclock-fb0-3200x1920 && mv hamclock-fb0-3200x1920 /hamclock/ ;
#RUN make clean && make -j 4 hamclock-web-3200x1920  && mv hamclock-web-3200x1920 /hamclock/ ;
#RUN make clean && make -j 4 hamclock-3200x1920     && mv hamclock-3200x1920 /hamclock/ ;
#RUN make clean

RUN rm -rf /tmp/* /hamclock/ESP*

#########  FINAL STAGE WEB ############
FROM root AS web
ARG DIMENSIONS

WORKDIR /srv/hamclock

COPY --from=buildstage /hamclock/hamclock  ./hamclock

USER root
COPY --chmod=755 <<-ENTRYPOINT /srv/hamclock/entrypoint.sh
	#!/bin/sh
	nice -n 25 /srv/hamclock/hamclock -d /srv/hamclock/.hamclock -o
	ENTRYPOINT

#################################################


#########  FINAL STAGE VNC ############
FROM root as vnc
ARG DIMENSIONS

RUN <<-X11VNC
	if [ -f /usr/bin/apt ]; then
	  apt-get update && \
	  DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
	  x11vnc xvfb libx11-6 && \
	  rm -rf /var/lib/apt/lists/* 
	fi
	if [ -f /sbin/apk ]; then
	  apk add x11vnc xvfb libx11
	fi
	X11VNC

WORKDIR /srv/hamclock

#COPY --from=buildstage /hamclock/hamclock-${DIMENSIONS} /srv/hamclock/hamclock-${DIMENSIONS}
COPY --from=buildstage /hamclock/hamclock /srv/hamclock/hamclock
COPY --chmod=755 <<-HAMCLOCKRUN /srv/hamclock/hamclockrun
	#!/bin/sh
	/srv/hamclock/hamclock -t 50 -d /srv/hamclock/.hamclock -o -k
	HAMCLOCKRUN

ADD --chmod=755  entrypoint-vnc.sh /srv/hamclock/entrypoint.sh

#################################################
FROM ${RUN_TYPE:-vnc} as hamclick
# picks the image base to be used
################################################
## FLATTEN
FROM scratch

COPY --from=hamclick / /

#The options that can appear before CMD are:
#
#--interval=DURATION (default: 30s)
#--timeout=DURATION (default: 30s)
#--start-period=DURATION (default: 0s)
#--start-interval=DURATION (default: 5s)
#--retries=N (default: 3)

HEALTHCHECK --interval=5m --timeout=15s \
            CMD curl --fail localhost:8080/get_sys.txt
WORKDIR /srv/hamclock/

MAINTAINER Mark Vincett kd2qar@gmail.com
LABEL org.opencontainers.image.authors="Mark Vincett kd2qar@gmail.com"

ENTRYPOINT ["/srv/hamclock/entrypoint.sh"]


