# This is a minimal Ubuntu image that preinstalls requirements upon Docker build
FROM rcarmo/ubuntu-python:3.7-onbuild-amd64

ADD . /app
WORKDIR /app
EXPOSE 8000
USER nobody
ENV PORT=8000
CMD python app.py
