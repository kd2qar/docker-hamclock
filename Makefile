#####
TAG=kd2qar/hamclock
BUILDER=kd2qar/hamclock-builder
NAME=hamclock

CAPABILITIES =  --cap-add=SYS_ADMIN

VOLUMES = \
	  --volume=/srv/hamclock/.hamclock:/srv/hamclock/.hamclock

#PUBLISH = -p  ${IP}:53:53/udp -p ${IP}:53:53/tcp -p ${IP}:953:953 -p ${IP2}:53:53/udp -p ${IP2}:53:53/tcp -p ${IP2}:953:953

IP=192.168.37.80
PORTS= -p ${IP}:8088:8080/tcp -p ${IP}:8091:8081/tcp -p${IP}:8092:8082/tcp  -p ${IP}:5999:5900/tcp 
#PORTS = -p 8088:8080

CPU=--cpus 0.5

DATE :=  $(shell date +%G%m%d%H%M)

LOG=--log-driver json-file --log-opt max-size=5m --log-opt max-file=1

all: build

build:
	@#docker build --pull -t ${BUILDER} ./hamclock-builder
	@#docker build --force-rm --progress plain  -t ${TAG}  . 
	@##docker image remove ${BUILDER}
	docker compose --progress plain build

stop:
	@#docker stop hamclock || true;
	docker compose down

remove: stop
	@#docker rm hamclock || true;

run:
	@#docker run --cpus=".2" ${LOG} --hostname=hamclock -d --privileged ${PORTS} ${ENV_VARS} ${CAPABILITIES} ${VOLUMES}  --name ${NAME} ${TAG} 
	docker compose up --build -d hamclock


