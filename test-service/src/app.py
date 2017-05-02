#!/usr/bin/env python3

""" Web server """

from logging.config import dictConfig
from os import environ
from datetime import datetime
from multiprocessing import cpu_count
from mako.template import Template
from sanic import Sanic
from sanic.exceptions import FileNotFound, NotFound
from sanic.response import json, text, html
from aioredis import create_redis
from socket import gethostname
from random import seed
from logging import getLogger, DEBUG

dictConfig({
    "version": 1,
    "formatters": {
        "http": {
            "format" : 'timestamp=%(asctime)s pid=%(process)d level=%(levelname)s uri=%(message)s',
            "datefmt": "%Y-%m-%dT%H:%M:%SZ"
        },
        "service": {
            "format" : 'timestamp=%(asctime)s level=%(levelname)s %(message)s',
            "datefmt": "%Y-%m-%dT%H:%M:%SZ"
        }
    },
    "handlers": {
        "console": {
            "class"    : "logging.StreamHandler",
            "formatter": "service",
            "level"    : "DEBUG",
            "stream"   : "ext://sys.stdout"
        }
    },
    "loggers": {
        "sanic.static": {
            "level"   : "INFO",
            "handlers": ["console"]
        }
    },
    "root": {
        "level"   : "INFO",
        "handlers": ["console"]
    }
})


log = getLogger()
app = Sanic(__name__)
layout = Template(filename='views/layout.tpl')
redis = None
shared_counter = environ.get('REDIS_COUNTER', 'rcarmo/stateful-service')
request_count = 0
compute_time = 0

@app.route('/', methods=['GET'])
async def homepage(req):
    global request_count
    request_count = request_count + 1
    shared_count = 0
    heading = "Stateless Front-End"
    if redis:
        await redis.inc(shared_counter)
        shared_count = int(await redis.get(shared_counter))
        heading = "Shared State Front-End"
    return html(layout.render(request=req,
                              heading=heading,
                              hostname=gethostname(),
                              requests=request_count,
                              shared_count=shared_count,
                              timestr=datetime.now().strftime("%H:%M:%S.%f")))


@app.route('/hostname')
async def get_name(req):
    global request_count
    request_count = request_count + 1
    if redis:
        await redis.inc(shared_counter)
    return text(gethostname())

@app.route('/count')
async def get_count(req):
    global request_count
    return text(str(request_count))

@app.route('/shared_count')
async def get_count(req):
    if redis:
        return text(redis.get(shared_counter))
    return text('No shared count available', status=404)

@app.route('/metrics')
async def prometheus_metrics(req):
    global request_count, compute_time
    shared_count = 0
    if redis:
        shared_count = int(await redis.get(shared_counter))
    return text('instance_compute_time %d\ninstance_requests_count %d\nshared_requests_count %d' % (compute_time, request_count, shared_count)) 

@app.route('/reset')
async def reset_count(req):
    global request_count, compute_time
    request_count = compute_time = 0
    return text('Instance count reset')

@app.route('/reset_shared')
async def reset_shared_count(req):
    await redis.set(shared_counter, 0)
    return text('Shared count reset')

def make_pi(digits):
    """Compute digits of Pi"""
    q, r, t, k, m, x = 1, 0, 1, 1, 3, 3
    for j in range(digits):
        if 4 * q + r - t < m * t:
            yield m
            q, r, t, k, m, x = 10*q, 10*(r-m*t), t, k, (10*(3*q+r))//t - 10*m, x
        else:
            q, r, t, k, m, x = q*k, (2*q+r)*x, t*x, k+1, (q*(7*k+2)+r*x)//(t*x), x+2

@app.route('/compute/<a:int>,<b:int>')
async def compute_for_random_interval(a,b):
    return text(compute_for_time(randint(a,b)))

@app.route('/compute/<ms:int>')
async def compute_for_time(ms):
    global compute_time
    result = []
    now = time()
    limit = (now + (ms/1000.0))
    for i in make_pi(10000000):
        result.append(str(i))
        if time() >= limit:
            break
    compute_time = compute_time + ms
    return text("".join(result))

app.static('/', './static')


@app.listener('after_server_start')
async def init_connections(sanic, loop):
    """Bind the database and Redis client to Sanic's event loop."""

    global redis
    redis_server = environ.get('REDIS_SERVER', None)
    if redis_server:
         redis = await create_redis((redis_server, 6379), encoding='utf-8', loop=loop)
    seed()


if __name__ == '__main__':
    log.debug("Beginning run.")
    HTTP_PORT = int(environ.get('PORT', 8000))
    DEBUG = 'true' == environ.get('DEBUG', 'false').lower()
    app.run(host='0.0.0.0', port=HTTP_PORT, workers=cpu_count(), debug=DEBUG)
