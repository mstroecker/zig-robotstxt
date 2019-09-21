const std = @import("std");
const Builder = std.build.Builder;
const Target = std.build.Target;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("robotstxt", "src/server.zig");
    exe.linkSystemLibrary("c");
    exe.setBuildMode(mode);
    exe.addIncludeDir("src");
    exe.strip = true;
    exe.single_threaded = true;
    exe.target = Target.parse("x86_64-linux-musl");
    //exe.target = Target.parse("x86_64-linux-libc");
    b.installArtifact(exe);
    const run = b.step("run", "Run the project");
    const run_cmd = exe.run();
    run.dependOn(&run_cmd.step);
}