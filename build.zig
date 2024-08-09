const std = @import("std");
const builtin = @import("builtin");

// This has been tested to work with zig 0.12.0
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});
    if (target.result.os.tag != .windows) @panic("Unsupported OS (check build.zig)");
    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const name = "h";

    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);

    exe.linkLibC();

    exe.addIncludePath(b.path("./include/"));
    exe.addIncludePath(b.path("./include/external"));
    exe.addIncludePath(b.path("./include/external/glfw/include"));

    exe.addObjectFile(b.path("./lib/raylib.lib"));
    // exe.addObjectFile(switch (target.result.os.tag) {
    // .windows => b.path("../zig-out/lib/raylib.lib"),
    // .linux => b.path("../zig-out/lib/libraylib.a"),
    // .macos => b.path("../zig-out/lib/libraylib.a"),
    // .emscripten => b.path("../zig-out/lib/libraylib.a"),
    // });
    exe.linkSystemLibrary("winmm");
    exe.linkSystemLibrary("gdi32");
    exe.linkSystemLibrary("opengl32");

    exe.defineCMacro("PLATFORM_DESKTOP", null);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
