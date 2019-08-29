const std = @import("std");
const warn = std.debug.warn;

const c = @cImport({
  @cInclude("sys/socket.h");
  @cInclude("netinet/in.h");
  @cInclude("unistd.h");
  @cInclude("errno.h");
  @cInclude("string.h");
  @cInclude("errno-access.h");
  @cInclude("stdio.h");
});

fn onError(what: []const u8, code: i32) void {
    const stringPtr = c.strerror(c.get_errno());
    warn("{} ", what);
    const t = c.printf(c"failed %d message: %s\n", code, stringPtr);
    std.process.exit(1);
}

pub fn main() void {

  const fd = c.socket(c.AF_INET, @enumToInt(c.SOCK_STREAM), 0);
  if (fd == 0) {
    onError("socket", fd);
  }

  const opt:i32 = 1;
  const setSockOptCode = c.setsockopt(fd, c.SOL_SOCKET, c.SO_REUSEADDR | c.SO_REUSEPORT,
                            @intToPtr(?*const c_void, @ptrToInt(&opt)),
                            @sizeOf(@typeOf(opt))); 
  
  if (setSockOptCode != 0) {
    onError("setsockopt", setSockOptCode);
  }  

  // struct sockaddr_in address
  const inAddr = c.in_addr {
    .s_addr = c.INADDR_ANY, 
  };
  var address = c.sockaddr_in {
    .sin_family = c.AF_INET,
    .sin_addr = inAddr,
    .sin_port = c.htons(8080),
    .sin_zero = [_]u8{0,0,0,0,0,0,0,0},
  };

  const bindCode = c.bind(fd, @ptrCast([*c]const c.sockaddr, &address),
    @sizeOf(c.sockaddr_in));

  if (bindCode != 0) {
    onError("bind", bindCode);
  }

  const listenCode = c.listen(fd, 3);
  if (listenCode != 0) {
    onError("listen", listenCode);
  }
  var addrlen:c_uint = @sizeOf(c.sockaddr_in);
  const clientHandle = c.accept(fd, @ptrCast([*c] c.sockaddr, &address),
    &addrlen);

  if (clientHandle < 0) {
    onError("accept", clientHandle);
  }
  
  var buffer = [_]u8 {0} ** 1024;
  const readCode = c.read(clientHandle, @ptrCast(?*c_void, &buffer[0]), 1024);
  warn("message: {}", buffer);
  
  const sendCode = c.send(clientHandle, c"hello world", 10, 0);




}
