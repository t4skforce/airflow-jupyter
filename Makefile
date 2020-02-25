.PHONY: all clean build run

all: clean build run

DEBUG ?= false

clean:
	@echo "cleaning things"
	docker kill airlowlab && echo "stopped container" || /bin/true
	docker rm airlowlab && echo "removed container" || /bin/true
	docker rmi t4skforce/jupyterlab-airflow:latest && echo "removed container image" || /bin/true
	docker rm `docker container ls -a --filter status=exited --filter status=created | awk '{print $$1}' | tail -n +2` && echo "removed build containers" || /bin/true
	docker rmi `docker images --filter "dangling=true" -q --no-trunc` && echo "removed unused images" || /bin/true

build:
	@echo "building things"
	docker build -t jupyterlab-airflow:latest --build-arg DEBUG=${DEBUG} .

dive:
	@echo "building things"
	dive build -t jupyterlab-airflow:latest --build-arg DEBUG=${DEBUG} .

run:
	@echo "runing things"
	docker run --name airlowlab -p 127.0.0.1:8888:8888 -it --rm jupyterlab-airflow
