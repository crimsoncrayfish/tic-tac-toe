const std = @import("std");
const stdout = std.io.getStdOut().writer();
const GS = @import("./game_state.zig");
const print = std.debug.print;

pub fn main() !void {
    try stdout.print("Hellp me\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator();
    defer _ = gpa.deinit();

    var gs = try GS.GameState.init(5, 5, allocator);
    defer gs.deinit(allocator) catch {};
}
