const std = @import("std");
const GS = @import("./game_state.zig");
const print = std.debug.print;
const c = @cImport({
    @cInclude("signal.h");
});

pub fn main() void {
    std.debug.print("Start\n", .{});
    uncookec_term_windows() catch {
        std.debug.print("Failed\n", .{});
    };
    std.debug.print("End\n", .{});
}
const STD_INPUT_HANDLE: i32 = -10;
const ENABLE_LINE_INPUT = @as(u32, 0x0002);
const ENABLE_ECHO_INPUT = @as(u32, 0x0004);
fn uncookec_term_windows() !void {
    const kernel32 = std.os.windows.kernel32;
    const hConsole = kernel32.GetStdHandle(std.os.windows.STD_INPUT_HANDLE);

    var mode: u32 = 0;
    if (hConsole) |hConsoleNotNull| {
        if (kernel32.GetConsoleMode(hConsoleNotNull, &mode) == 0) {
            return error.UnableToGetConsoleMode;
        }

        // Disable input line mode and echo input

        mode &= ~(@as(u32, ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT));
        if (kernel32.SetConsoleMode(hConsoleNotNull, mode) == 0) {
            return error.UnableToSetConsoleMode;
        }
    }
}
fn uncooked_term_c() !void {
    var tty: std.fs.File = try std.fs.cwd().openFile("./dev/tty", .{ .mode = std.fs.File.OpenMode.read_write });
    defer tty.close();
    var termios = std.c.termios{};
    try std.c.tcgetattr(tty.handle, &termios);
}
fn run_game() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator();
    defer _ = gpa.deinit();

    var gs = try GS.GameState.init(15, 15, allocator);
    defer gs.deinit(allocator) catch {};

    std.debug.print("\x1b[2J", .{});
    std.debug.print("\x1b[?25l", .{});

    gs.seed_state(109);
    while (true) {
        std.time.sleep(500000000);
        try gs.next();
        std.debug.print("\x1b[H", .{});
        gs.dbg_print(false);
    }
}
fn signal_handler() !void {
    std.debug.print("\x1b[?25h", .{});
    std.process.exit(0);
}
