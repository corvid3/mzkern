const std = @import("std");

// build script adapted from
//     limine-bootloader:limine-zig-template/kernel @ github
pub fn build(b: *std.Build) void {
    var target = std.zig.CrossTarget{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    };

    // Disable CPU features that require additional initialization
    // like MMX, SSE/2 and AVX. That requires us to enable the soft-float feature.
    const Features = std.Target.x86.Feature;
    target.cpu_features_sub.addFeature(@intFromEnum(Features.mmx));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.sse));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.sse2));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.avx));
    target.cpu_features_sub.addFeature(@intFromEnum(Features.avx2));
    target.cpu_features_add.addFeature(@intFromEnum(Features.soft_float));

    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSmall });
    const limine = b.dependency("limine", .{});
    const kernel = b.addExecutable(.{
        .name = "mzkern",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    kernel.code_model = .kernel;
    kernel.addModule("limine", limine.module("limine"));
    kernel.setLinkerScript(.{ .path = "linker.ld" });
    kernel.pie = true;

    b.installArtifact(kernel);
}
