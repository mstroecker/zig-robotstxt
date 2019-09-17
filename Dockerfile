# ---- BUILDER ----

FROM alpine:3.10 AS builder

RUN apk add binutils gcc 
RUN wget -q https://ziglang.org/builds/zig-linux-x86_64-0.4.0+d291d3c8.tar.xz -O zig.tar.xz \
    && echo "3a2020a5d13a99e70b8d18933c3d88943b37b07159c63572a0f479454ad9b7eb  zig.tar.xz" \
    | sha256sum -c \
    && mkdir /zig && tar -C /zig -xvf zig.tar.xz
WORKDIR /build
COPY . /build
RUN /zig/*/zig build -Drelease-small=true && strip zig-cache/bin/robotstxt

# ------ APP ------

FROM scratch
COPY --from=builder /build/zig-cache/bin/robotstxt / 
CMD ["/robotstxt"]
