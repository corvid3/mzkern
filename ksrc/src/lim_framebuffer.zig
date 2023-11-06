// lim_framebuffer.zig
// basic kernel framebuffer access
// currently planned to be used directly by the kernel to write to the screen
// planned in the fuar future to be used by the SYSCOUT driver
//      to write characters to the screen

const limine = @import("limine");
const etc = @import("etc.zig");

pub export var fb_req align(8) = limine.FramebufferRequest{};
var resp: *limine.FramebufferResponse = undefined;
var cur_fb: *limine.Framebuffer = undefined;

/// if we cannot initialize the framebuffer, we halt the system
pub fn static_init() void {
    if (fb_req.response == null) etc.perma_halt();
    resp = fb_req.response.?;

    if (resp.framebuffer_count < 1) etc.perma_halt();
    set_framebuffer(0);
}

/// change the current framebuffer being written to
pub fn set_framebuffer(idx: usize) void {
    cur_fb = resp.framebuffers()[idx];
}

pub inline fn put_pixel(x: usize, y: usize, color: u32) void {
    const where = x + y * cur_fb.width;
    const data_ptr: [*]u32 = @alignCast(@ptrCast(cur_fb.address));
    data_ptr[where] = color;
}

pub fn clear_screen(color: u32) void {
    for (0..cur_fb.height) |y|
        for (0..cur_fb.width) |x|
            put_pixel(y, x, color);
}
