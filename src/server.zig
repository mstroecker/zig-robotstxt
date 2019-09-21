const std = @import("std");
const warn = std.debug.warn;
const TypeId = @import("builtin").TypeId;

const c = @cImport({
    @cInclude("sys/socket.h");
    @cInclude("netinet/in.h");
    @cInclude("unistd.h");
    @cInclude("errno.h");
    @cInclude("string.h");
    @cInclude("errno-access.h");
    @cInclude("signal.h");
});

const SIG_ERR = @intToPtr(extern fn (c_int) void, std.math.maxInt(usize));
const SOCK_STREAM = if (@typeId(@typeOf(c.SOCK_STREAM)) == TypeId.Enum) @enumToInt(c.SOCK_STREAM) else c.SOCK_STREAM;

fn onError(what: []const u8, code: i32) void {
    onErrorNoExit(what, code);
    std.process.exit(1);
}

fn onErrorNoExit(what: []const u8, code: i32) void {
    const message = std.mem.toSliceConst(u8, c.strerror(c.get_errno()));
    warn("Command '{}' failed with code {}. Message: {}\n", what, code, message);
}

extern fn onSignal(signo: c_int) void {
    if (signo == c.SIGINT) {
        warn("Received signal 'SIGINT'. Exiting..\n");
        std.process.exit(0);
    } else {
        warn("Received unknown signal {}.\n", signo);
    }
}

pub fn main() void {
    if (c.signal(c.SIGINT, onSignal) == SIG_ERR) {
        onError("signal", @intCast(i32, @ptrToInt(SIG_ERR)));
    }

    const fd = c.socket(c.AF_INET, SOCK_STREAM, 0);
    if (fd == 0) {
        onError("socket", fd);
    }

    const opt: i32 = 1;
    const setSockOptCode = c.setsockopt(fd, c.SOL_SOCKET, c.SO_REUSEADDR | c.SO_REUSEPORT, @intToPtr(?*const c_void, @ptrToInt(&opt)), @sizeOf(@typeOf(opt)));

    if (setSockOptCode != 0) {
        onError("setsockopt", setSockOptCode);
    }

    const inAddr = c.in_addr{
        .s_addr = c.INADDR_ANY,
    };
    var address = c.sockaddr_in{
        .sin_family = c.AF_INET,
        .sin_addr = inAddr,
        .sin_port = c.htons(8080),
        .sin_zero = [_]u8{0} ** 8,
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
        const readCode = c.read(clientHandle, @ptrCast(?*c_void, &buffer[0]), buffer.len);
        if (readCode < 0) {
            onErrorNoExit("read", @intCast(i32, readCode));
            continue;
        }

        if (readCode == 0) {
            continue;
        }

        const bufStr = (&buffer)[0..@intCast(usize, readCode)];
        var lines = std.mem.separate(bufStr, "\r\n");
        const firstLine = lines.next();
        var userAgent: []const u8 = "";
        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "User-Agent")) {
                userAgent = line;
                break;
            }
        }
        warn("Access: {} | {}\n", firstLine, userAgent);

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
