const etc = @import("etc.zig");
const fb = @import("lim_framebuffer.zig");
const limine = @import("limine");
const consts = @import("const.zig");
const ktext = @import("ktext.zig");
const serial = @import("serial.zig");

pub export var revision_tag: [3]u64 align(8) = .{ 0xf9562b2d5c95a6c8, 0x6a7b384944536bdc, 1 };

pub export var stack_size_req: limine.StackSizeRequest = .{
    .stack_size = consts.MIBI * 32,
};

fn _init() void {
    fb.static_init();
    ktext.static_init();
}

export fn _start() callconv(.SysV) noreturn {
    serial.wline("KERN: running init scripts");
    _init();
    serial.wline("KERN: all inits ran successfully");
    fb.clear_screen(0x00ff0000);
    ktext.write_string("kernel initailization complete", consts.GREEN, consts.BLACK);

    // fb.whiteout();

    etc.perma_halt();
}
