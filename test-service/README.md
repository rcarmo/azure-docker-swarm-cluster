# rcarmo/demo-frontend-stateless

[![Docker Stars](https://img.shields.io/docker/stars/rcarmo/demo-frontend-stateless.svg)](https://hub.docker.com/r/rcarmo/demo-frontend-stateless)
[![Docker Pulls](https://img.shields.io/docker/pulls/rcarmo/demo-frontend-stateless.svg)](https://hub.docker.com/r/rcarmo/demo-frontend-stateless)
[![](https://images.microbadger.com/badges/image/rcarmo/demo-frontend-stateless.svg)](https://microbadger.com/images/rcarmo/demo-frontend-stateless "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/rcarmo/demo-frontend-stateless.svg)](https://microbadger.com/images/rcarmo/demo-frontend-stateless "Get your own version badge on microbadger.com")

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

## More Info

A pre-built image is available from [Docker Hub][dh] as [`rcarmo/demo-frontend-stateless`][dh]. 

The built-in application stack uses [`rcarmo/alpine-python`][ap], a small Python runtime atop Alpine Linux.

[ap]: https://github.com/rcarmo/alpine-python
[dh]:https://hub.docker.com/r/rcarmo/demo-frontend-stateless/
[d]: http://docker.com
