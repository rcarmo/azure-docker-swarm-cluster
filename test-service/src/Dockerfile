# This is a minimal Apline image that preinstalls requirements upon Docker build
FROM rcarmo/alpine-python:3.6-onbuild

ADD . /app
WORKDIR /app
EXPOSE 8000
ENV PORT=8000
CMD python app.py
