export PORT=8000
IMAGE_NAME=rcarmo/demo-frontend

build-container:
	docker build -t $(IMAGE_NAME) src

run:
	docker run -d -p 8000:8000 -e DEMO_SETTING="my app setting" $(IMAGE_NAME)

rmi:
	docker rmi -f $(IMAGE_NAME)

shell:
	docker run -p 8000:8000 -e DEMO_SETTING="my app setting" -ti $(IMAGE_NAME)

push:
	docker push $(IMAGE_NAME)

clean-all-images:
	#docker stop $(docker ps -a -q)
	#docker rm $(docker ps -a -q)
	docker rmi $(docker images -a -q)

test:
	curl -v http://localhost:$(PORT)/{hostname,count} -w "\n"
	curl -v http://localhost:$(PORT)/compute/{100,200,300} -w "\n"
