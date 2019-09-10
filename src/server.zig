const std = @import("std");
const warn = std.debug.warn;

const c = @cImport({
    @cInclude("sys/socket.h");
    @cInclude("netinet/in.h");
    @cInclude("unistd.h");
    @cInclude("errno.h");
    @cInclude("string.h");
    @cInclude("errno-access.h");
});

fn cStringToString(str: [*]u8) []u8 {
    const len = c.strlen(str);
    return str[0..len];
}

fn getFirstLine(str: []u8) []u8 {
    var i: u32 = 0;
    while (str[i] != '\n') {
        i = i + 1;
    }
    return str[0..i];
}

fn onError(what: []const u8, code: i32) void {
    onErrorNoExit(what, code);
    std.process.exit(1);
}

fn onErrorNoExit(what: []const u8, code: i32) void {
    const message = cStringToString(c.strerror(c.get_errno()));
    warn("Command '{}' failed with code {}. Message: {s}\n", what, code, message);
}

pub fn main() void {
    const fd = c.socket(c.AF_INET, @enumToInt(c.SOCK_STREAM), 0);
    if (fd == 0) {
        onError("socket", fd);
    }

    const opt: i32 = 1;
    const setSockOptCode = c.setsockopt(fd, c.SOL_SOCKET, c.SO_REUSEADDR | c.SO_REUSEPORT, @intToPtr(?*const c_void, @ptrToInt(&opt)), @sizeOf(@typeOf(opt)));

    if (setSockOptCode != 0) {
        onError("setsockopt", setSockOptCode);
    }

    // struct sockaddr_in address
    const inAddr = c.in_addr{
        .s_addr = c.INADDR_ANY,
    };
    var address = c.sockaddr_in{
        .sin_family = c.AF_INET,
        .sin_addr = inAddr,
        .sin_port = c.htons(8080),
        .sin_zero = [_]u8{ 0, 0, 0, 0, 0, 0, 0, 0 },
    };

    const bindCode = c.bind(fd, @ptrCast([*c]const c.sockaddr, &address), @sizeOf(c.sockaddr_in));
    if (bindCode != 0) {
        onError("bind", bindCode);
    }

    const listenCode = c.listen(fd, 3);
    if (listenCode != 0) {
        onError("listen", listenCode);
    }

    while (true) {
        var addrlen: c_uint = @sizeOf(c.sockaddr_in);
        const clientHandle = c.accept(fd, @ptrCast([*c]c.sockaddr, &address), &addrlen);
        defer {
            const closeCode = c.close(clientHandle);
            if (closeCode < 0) {
                onErrorNoExit("close", closeCode);
            }
        }

        if (clientHandle < 0) {
            onErrorNoExit("accept", clientHandle);
            continue;
        }

        var buffer = [_]u8{0} ** 1024;
        const readCode = c.read(clientHandle, @ptrCast(?*c_void, &buffer[0]), 1024);
        if (readCode < 0) {
            onErrorNoExit("read", @intCast(i32, readCode));
            continue;
        }

        const line = getFirstLine(cStringToString(&buffer));
        warn("Access: {}\n", line);

        const robotstxt =
            \\HTTP/1.1 200 OK
            \\Content-Length: 26
            \\
            \\User-agent: *
            \\Disallow: /
            \\
        ;
        const bytesSent = c.send(clientHandle, &robotstxt, robotstxt.len, 0);
        if (bytesSent < 0) {
            onErrorNoExit("send", @intCast(i32, bytesSent));
        }
    }
}
