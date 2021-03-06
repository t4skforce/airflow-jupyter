.PHONY: all clean build run

all: clean build run

DEBUG ?= false

clean:
	@echo "cleaning things"
	docker kill airlowlab && echo "stopped container" || /bin/true
	docker rm airlowlab && echo "removed container" || /bin/true
	docker rmi t4skforce/jupyterlab-airflow:latest && echo "removed container image" || /bin/true
	docker rmi `docker images --filter "dangling=true" -q --no-trunc` && echo "removed unused images" || /bin/true

build:
	@echo "building things"
	docker build --force-rm -t jupyterlab-airflow:latest --build-arg DEBUG=${DEBUG} .

dive:
	@echo "building things"
	dive jupyterlab-airflow:latest

run:
	@echo "runing things"
	docker run --name airlowlab -p 127.0.0.1:10000:8000 -it --rm jupyterlab-airflow
