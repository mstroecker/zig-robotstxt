# ---- BUILDER ----

FROM alpine:3.10 AS builder

RUN apk add binutils gcc 
RUN wget -q https://ziglang.org/download/0.4.0/zig-linux-x86_64-0.4.0.tar.xz -O zig.tar.xz \
    && echo "fb1954e2fb556a01f8079a08130e88f70084e08978ff853bb2b1986d8c39d84e  zig.tar.xz" \
    | sha256sum -c \
    && mkdir /zig && tar -C /zig -xvf zig.tar.xz
WORKDIR /build
COPY . /build
RUN /zig/*/zig build -Drelease-small=true && find /build && cp zig-cache/o/*/build robotstxt && strip robotstxt

# ------ APP ------

FROM scratch
COPY --from=builder /build/robotstxt /
CMD ["/robotstxt"]
