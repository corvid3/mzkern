// bm.zig
// bare metal commands
// stuff like crashing, etc

const serial = @import("serial.zig");

pub inline fn perma_halt() noreturn {
    serial.wline("KERN: halting!");

    while (true)
        asm volatile ("hlt");
}
