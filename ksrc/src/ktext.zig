// ktext.zig
// basic text writing to screen, part of kernel
// uses PSF fonts (eventually, read from the FS and pick an ideal font)
// in the future,
//     functionality (should) gets replaced by a userland driver post-boot
// TODO: write a userland server/driver in-situ replacement

const std = @import("std");
const fb = @import("lim_framebuffer.zig");
const etc = @import("etc.zig");
const serial = @import("serial.zig");

const SELECTED_PSF_FONT_LITERAL =
    @embedFile("./iso01.f16.psf");
export var SELECTED_PSF_FONT linksection(".data") = SELECTED_PSF_FONT_LITERAL.*;

/// the internal character map
/// NOTE: we can only handle 16 height bmaps right now,
///     as kernalloc isn't implemented
export var CHAR_MAP: [256 * 16]u8 = undefined;

/// from what i can gather, the width is a constant 8. height = charsize
const PSF_1_CHAR_WIDTH = 8;

const PSF_1_HEADER_MAGIC: u16 = 0x04 << 8 | 0x36;
/// does this table has 512 glyphs, if not then only 256
const PSF_1_MODE512: u8 = 0x01;
/// does this table has utf?
const PSF_1_MODEHASTAB: u8 = 0x02;
/// eq to hastab
const PSF_1_MODESEQ: u8 = 0x04;

const Psf1Header = packed struct {
    magic: u16,
    font_mode: u8,
    char_size: u8,
};

// TODO: the current iso font is psf1
const Psf2Header = packed struct {
    magic: u32,
    version: u32,
};

var xoff: usize = 0;
var yoff: usize = 0;

/// data | the start of the actual bitmap data
fn parse_256c_psf1_font(data: []const u8, height: usize) void {
    for (0..256) |coff| {
        for (0..height) |hof| {
            const byte: u8 = data[coff * height + hof];
            if (coff == 'A') {
                for (0..8) |i|
                    serial.wint((byte >> @truncate(i)) & 1);
                serial.wline("");
            }
            CHAR_MAP[coff * height + hof] = byte;
        }
    }
}

fn parse_selected_psf_font() void {
    const cur_ptr = SELECTED_PSF_FONT;

    const header = std.mem.bytesToValue(Psf1Header, @constCast(cur_ptr[0..4]));

    if (header.magic != PSF_1_HEADER_MAGIC) etc.perma_halt();

    // dont support 512 glyphs
    if ((header.font_mode & PSF_1_MODE512) > 0) etc.perma_halt();

    var start: []const u8 = cur_ptr[@sizeOf(Psf1Header)..];

    // dont support utf, skip it
    if ((header.font_mode & PSF_1_MODEHASTAB) > 0 or (header.font_mode & PSF_1_MODESEQ) > 0) {
        serial.wline("NOTE: ignoring utf8...");
    }

    const char_height = header.char_size;
    serial.wstr("font: char_height: ");
    serial.wint(char_height);
    serial.wline("");

    // // for now, we guarantee 256 chars because we fail on 512
    parse_256c_psf1_font(start, char_height);
}

pub inline fn write_char(c: u8, fg: u32, bg: u32) void {
    var offset: usize = @as(usize, c) * 16;
    const cv = CHAR_MAP[offset..];

    // per byte...
    for (0..16) |hidx| {
        const b = cv[hidx];
        // per bit...
        for (0..8) |widx| {
            const on = ((b >> @truncate(8 - widx)) & 1) == 1;
            var col: u32 = undefined;
            if (on) col = fg else col = bg;
            fb.put_pixel(8 * xoff + widx, 16 * yoff + hidx, col);
        }
    }

    if (c == '\n') {
        xoff = 0;
        yoff += 1;
        // TODO: scroll
    } else {
        xoff += 1;
    }
}

pub fn write_string(str: []const u8, fg: u32, bg: u32) void {
    for (str) |c| write_char(c, fg, bg);
}

pub fn static_init() void {
    parse_selected_psf_font();
}
