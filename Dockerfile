# ---- BUILDER ----

FROM alpine:3.10 AS builder

RUN apk add binutils gcc 
RUN wget -q https://ziglang.org/download/0.5.0/zig-linux-x86_64-0.5.0.tar.xz -O zig.tar.xz \
    && echo "43e8f8a8b8556edd373ddf9c1ef3ca6cf852d4d09fe07d5736d12fefedd2b4f7  zig.tar.xz" \
    | sha256sum -c \
    && mkdir /zig && tar -C /zig -xvf zig.tar.xz
WORKDIR /build
COPY . /build
RUN /zig/*/zig build -Drelease-small=true && find /build && cp zig-cache/bin/robotstxt robotstxt && strip robotstxt

# ------ APP ------

FROM scratch
COPY --from=builder /build/robotstxt /
CMD ["/robotstxt"]
