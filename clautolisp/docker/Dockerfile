FROM --platform=linux/amd64 debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG CCL_VERSION=1.13
ARG QUICKLISP_URL=https://beta.quicklisp.org/quicklisp.lisp

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV HOME=/root
ENV XDG_CACHE_HOME=/root/.cache

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      make \
      m4 \
      sbcl \
      tar \
      xz-utils \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone --depth 1 --branch "v${CCL_VERSION}" https://github.com/Clozure/ccl.git ccl \
 && curl -fsSL -o /tmp/linuxx86.tar.gz \
      "https://github.com/Clozure/ccl/releases/download/v${CCL_VERSION}/linuxx86.tar.gz" \
 && tar -xzf /tmp/linuxx86.tar.gz -C /opt/ccl \
 && printf '%s\n' '#!/bin/sh' 'exec /opt/ccl/lx86cl64 "$@"' > /usr/local/bin/ccl \
 && chmod +x /usr/local/bin/ccl \
 && rm -f /tmp/linuxx86.tar.gz

RUN mkdir -p /root/.cache /root/quicklisp /tmp/quicklisp

RUN curl -fsSL -o /tmp/quicklisp.lisp "${QUICKLISP_URL}" \
 && sbcl --noinform --no-userinit --non-interactive \
      --load /tmp/quicklisp.lisp \
      --eval '(quicklisp-quickstart:install :path #P"/root/quicklisp/")' \
      --eval '(sb-ext:quit)' \
 && sbcl --noinform --no-userinit --non-interactive \
      --eval '(load #P"/root/quicklisp/setup.lisp")' \
      --eval '(ql:quickload "fiveam" :silent t)' \
      --eval '(sb-ext:quit)' \
 && ccl --no-init --quiet \
      --eval '(load #P"/root/quicklisp/setup.lisp")' \
      --eval '(ql:quickload "fiveam" :silent t)' \
      --eval '(ccl:quit)' \
 && rm -f /tmp/quicklisp.lisp

WORKDIR /workspace
