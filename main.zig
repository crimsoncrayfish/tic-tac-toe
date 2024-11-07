const std = @import("std");
const GS = @import("./game_state.zig");
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator();
    defer _ = gpa.deinit();

    var gs = try GS.GameState.init(5, 5, allocator);
    defer gs.deinit(allocator) catch {};

    gs.seed_state(109);
    while (true) {
        std.time.sleep(1000000000);
        try gs.next();
        gs.dbg_print(false);
    }
}
