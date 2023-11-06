// serial.zig
//     write bytes to the serial port

const std = @import("std");

pub inline fn wbyte(val: u8) void {
    const port = 0x3f8;
    outb(port, val);
}

/// write a formatted hex int
pub fn winth(int: usize) void {
    var intc = int;
    var str: [32]u8 = undefined;
    var idx: isize = 0;

    while (intc > 0) : (idx += 1) {
        str[@intCast(idx)] = @truncate(intc & 0x0F);
        intc >>= 4;
    }

    idx -= 1;
    while (idx >= 0) : (idx -= 1) {
        const c = str[@intCast(idx)];
        if (c < 10) wbyte(c + '0') else wbyte(c + 'A' - 10);
    }
}

/// write a formatted dec int
pub fn wint(int: usize) void {
    var intc = int;
    var str: [32]u8 = undefined;
    var idx: isize = 0;

    while (intc > 0) : (idx += 1) {
        str[@intCast(idx)] = @truncate(intc % 10);
        intc /= 10;
    }

    idx -= 1;
    if (idx == -1) wbyte('0');

    while (idx >= 0) : (idx -= 1)
        wbyte(str[@intCast(idx)] + '0');
}

pub fn wstr(str: []const u8) void {
    for (str) |c|
        wbyte(c);
}

pub fn wline(str: []const u8) void {
    wstr(str);
    wstr("\r\n");
}

fn outb(port: u16, val: u8) void {
    asm volatile ("outb %[val], %[port]"
        :
        : [val] "{al}" (val),
          [port] "N{dx}" (port),
        : "memory"
    );
}
