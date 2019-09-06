# Zig robots.txt Docker image

[![Build Status](https://travis-ci.org/mstroecker/zig-robotstxt.svg?branch=master)](https://travis-ci.org/mstroecker/zig-robotstxt)
[![Docker Pulls](https://img.shields.io/docker/pulls/mstroecker/zig-robotstxt)](https://hub.docker.com/r/mstroecker/zig-robotstxt)

This project implements a small(~370 KB Docker Image) and lightweight http-server, just serving a disallow-robots.txt file using the Zig programming language(https://ziglang.org/).

Run using docker run:

```bash
docker run -p 80:8080 mstroecker/zig-robotstxt
```

Compose configuration example with traefik:

```yaml
version: '3'
services:
  traefik:
    image: traefik
    command:
      - "--docker"
      - "--docker.watch=true"
    ports:
      - "80:80"
    labels:
      traefik.enable: 'false'
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

  robotstxt:
    image: mstroecker/zig-robotstxt
    labels:
      - "traefik.port=8080"
      - "traefik.robotstxt.frontend.rule=Host:localhost;Path:/robots.txt"
```

Result message:

```http
HTTP/1.1 200 OK
Content-Length: 26

User-agent: *
Disallow: /

```