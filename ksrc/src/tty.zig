// tty.zig
// basic tty implementation
// stores screen information
// when tty is changed, clear the screen, and then update
// the screen with the current screen information
//
// should this be a userland driver/server? probably
// for now, keep it in the kernel

const TtyChar = struct {
    char: u8,
};

const Tty = struct {
    width: u16,
    height: u16,
    chars: [*]TtyChar,
};

// TODO: implement
// DEPENDS-ON: kernel memory management
pub fn create_tty() Tty {}
