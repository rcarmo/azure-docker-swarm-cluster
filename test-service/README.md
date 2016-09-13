# rcarmo/demo-frontend-stateless

This [Docker][d] image provides a simple front-end application that is useful for testing load-balancing and auto-scaling solutions of various kinds.

The `stateless` part of the name denotes that while each instance maintains a request count to demonstrate load sharing among instances, the count is not preserved if the app is restarted, nor is there any back-end store to restore state upon restart.

## Endpoints

The app homepage provides a status display including the container hostname, request count and internal environment variable dump, and exposes a set of utility endpoints for statistics and generating CPU load:

* `/hostname` to obtain the hostname (requests to this URL and to the homepage are counted)
* `/count` to get the request count
* `/stats` for more detailed stats
* `/reset` to reset request and computation counters
* `/compute/100` to perform a computation during 100ms (approximately)
* `/compute/100,200` to perform a computation for a random interval between 100 and 200ms

/hostname to obtain the hostname
/count to get the request count.
/compute/100 to perform a computation during 100ms (approximately)
/compute/100,200 to perform a computation for a random interval between 100 and 200ms

## More Info

A pre-built image is available from [Docker Hub][dh] as [`rcarmo/demo-frontend-stateless`][dh]. 

The built-in application stack is built with [`rcarmo/alpine-python`][ap], a small Python runtime atop Alpine Linux.

[ap]: https://github.com/rcarmo/alpine-python
[dh]:https://hub.docker.com/r/rcarmo/demo-frontend-stateless/
[d]: http://docker.com