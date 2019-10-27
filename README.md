# Zig robots.txt Docker image

[![Build Status](https://travis-ci.org/mstroecker/zig-robotstxt.svg?branch=master)](https://travis-ci.org/mstroecker/zig-robotstxt)
[![Docker Pulls](https://img.shields.io/docker/pulls/mstroecker/zig-robotstxt)](https://hub.docker.com/r/mstroecker/zig-robotstxt)
[![](https://images.microbadger.com/badges/image/mstroecker/zig-robotstxt.svg)](https://microbadger.com/images/mstroecker/zig-robotstxt "Get your own image badge on microbadger.com")

This project implements a small(5.7 KB) and lightweight http-server, just serving a disallow-robots.txt file using the Zig programming language(https://ziglang.org/).

Run using docker run:

```bash
docker run -p 80:8080 mstroecker/zig-robotstxt
```
## Kubernetes Example

Kubernetes configuration example:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myservice
---
apiVersion: v1
kind: Service
metadata:
  name: robotstxt
  namespace: myservice
spec:
  type: LoadBalancer
  ports:
  - port: 81
    targetPort: http 
    name: http
  selector:
    app: robotstxt
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: robotstxt
  namespace: myservice
spec:
  replicas: 3
  selector:
    matchLabels:
      app: robotstxt
  template:
    metadata:
      labels:
        app: robotstxt
    spec:
      containers:
      - name: robotstxt
        image: mstroecker/zig-robotstxt
        ports:
        - containerPort: 8080
          name: http
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: robotstxt
  namespace: myservice
spec:
  rules:
    - host: localhost
      http:
        paths:
          - path: /robots.txt
            backend:
              serviceName: robotstxt
              servicePort: http

```

## Docker Compose Example

Compose configuration example with traefik:

```yaml
version: '3'
services:
  traefik:
    image: traefik:1.7
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
