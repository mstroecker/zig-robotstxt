const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("hello", "hello.zig");
    exe.setBuildMode(mode);
    b.installArtifact(exe);
    const run = b.step("run", "Run the project");
    const run_cmd = exe.run();
    run.dependOn(&run_cmd.step);
}