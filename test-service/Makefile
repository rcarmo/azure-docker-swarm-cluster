export PORT=8000
build-container:
	docker build -t rcarmo/demo-frontend-stateless src

run:
	docker run -d -p 8000:8000 -e DEMO_SETTING="my app setting" rcarmo/demo-frontend-stateless

rmi:
	docker rmi -f rcarmo/demo-frontend-stateless

shell:
	docker run -p 8000:8000 -e DEMO_SETTING="my app setting" -ti rcarmo/demo-frontend-stateless /bin/bash

push:
	docker push rcarmo/demo-frontend-stateless

clean-all-images:
	#docker stop $(docker ps -a -q)
	#docker rm $(docker ps -a -q)
	docker rmi $(docker images -a -q)

test:
	curl -v http://localhost:$(PORT)/{hostname,count} -w "\n"
	curl -v http://localhost:$(PORT)/compute/{100,200,300} -w "\n"
