from os import environ
from bottle import route, view, run, static_file
from socket import gethostname
from time import time
from datetime import datetime
from random import randint, seed

request_count = 0
compute_time = 0
seed()

@route('/')
@view('layout')
def homepage():
    global request_count
    request_count = request_count + 1
    return {'hostname': gethostname(), 'requests': request_count, 'timestr': datetime.now().strftime("%H:%M:%S.%f")}

@route('/hostname')
def get_name():
    global request_count
    request_count = request_count + 1
    return gethostname()

@route('/count')
def get_count():
    global request_count
    return str(request_count)

@route('/stats')
def get_count():
    global request_count, compute_time
    return "%s: %d requests, %d ms computed, time is %f" % (gethostname(), request_count, compute_time, time())

@route('/reset')
def get_count():
    global request_count, compute_time
    request_count = compute_time = 0
    return "Reset."

def make_pi(digits):
    """Compute digits of Pi"""
    q, r, t, k, m, x = 1, 0, 1, 1, 3, 3
    for j in range(digits):
        if 4 * q + r - t < m * t:
            yield m
            q, r, t, k, m, x = 10*q, 10*(r-m*t), t, k, (10*(3*q+r))//t - 10*m, x
        else:
            q, r, t, k, m, x = q*k, (2*q+r)*x, t*x, k+1, (q*(7*k+2)+r*x)//(t*x), x+2

@route('/compute/<a:int>,<b:int>')
def compute_for_random_interval(a,b):
    return compute_for_time(randint(a,b))

@route('/compute/<ms:int>')
def compute_for_time(ms):
    global compute_time
    result = []
    now = time()
    limit = (now + (ms/1000.0))
    for i in make_pi(10000000):
        result.append(str(i))
        if time() >= limit:
            break
    compute_time = compute_time + ms
    return "".join(result)

@route('<path:path>')
def static(path):
    return static_file(path, root='static')

if __name__ == '__main__':
    run(
        host    = environ.get('BIND_ADDRESS','0.0.0.0'),
        port    = int(environ.get('PORT','8000')),
        debug   = environ.get('DEBUG','False').lower() == 'true',
        server  = 'uvloop'
    )
