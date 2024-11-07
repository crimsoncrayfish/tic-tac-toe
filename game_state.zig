const std = @import("std");
const assert = std.debug.assert;
const conway = @import("./conways_law.zig");
const stdout = std.io.getStdOut().writer();

pub const GameState = struct {
    grid: [][]bool = undefined,
    last_frame: [][]bool = undefined,
    row_count: u8 = 0,
    row_length: u8 = 0,

    pub fn init(rows: u8, cols: u8, allocator: *const std.mem.Allocator) !GameState {
        const grid = try allocator.alloc([]bool, rows);
        for (grid) |*row| {
            row.* = try allocator.alloc(bool, cols);
            for (row.*) |*col| {
                col.* = false;
            }
        }
        const last = try allocator.alloc([]bool, rows);
        for (last) |*row| {
            row.* = try allocator.alloc(bool, cols);
            for (row.*) |*col| {
                col.* = false;
            }
        }
        return GameState{ .grid = grid, .last_frame = last, .row_count = rows, .row_length = cols };
    }
    pub fn seed_state(self: *const GameState, seed: u64) void {
        self.assert_allocated();
        var prng = std.rand.DefaultPrng.init(seed);
        const random = prng.random();
        for (self.grid) |*row| {
            for (row.*) |*cell| {
                cell.* = random.boolean();
            }
        }
    }
    pub fn assert_allocated(self: *const GameState) void {
        assert(self.grid.len == self.row_count);

        for (self.grid) |*row| {
            assert(row.*.len == self.row_length);
        }
    }
    pub fn deinit(self: *const GameState, allocator: *const std.mem.Allocator) void {
        for (self.grid) |*row| {
            allocator.free(row.*);
        }
        allocator.free(self.grid);
        for (self.last_frame) |*row| {
            allocator.free(row.*);
        }
        allocator.free(self.last_frame);
    }
    pub fn set_state(self: *const GameState, grid: [][]bool) void {
        self.grid = grid;
    }
    pub fn dbg_print(self: *const GameState, include_coords: bool) void {
        std.debug.print("-------------------\n", .{});
        for (0..self.row_count) |row| {
            for (0..self.row_length) |col| {
                if (include_coords) {
                    std.debug.print("[x={0},y={1}]{2} ", .{ col, row, self.grid[row][col] });
                } else if (self.grid[row][col]) {
                    std.debug.print("{s} ", .{"o"});
                } else {
                    std.debug.print("{s} ", .{"x"});
                }
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("-------------------\n", .{});
    }
    pub fn update_last_frame(self: *const GameState) void {
        for (0..self.row_count) |row_number| {
            assert(self.last_frame[row_number].len == self.grid[row_number].len);
            for (0..self.row_length) |col_number| {
                self.last_frame[row_number][col_number] = self.grid[row_number][col_number];
            }
        }
    }
    pub fn next(self: *const GameState) !void {
        assert(self.last_frame.len == self.grid.len);
        self.update_last_frame();
        for (self.grid, 0..) |*row, row_number| {
            for (row.*, 0..) |*item, col_number| {
                const count = self.count_siblings_for_index(@intCast(col_number), @intCast(row_number));
                const next_state = conway.apply_conways_law(item.*, count);
                item.* = next_state;
            }
        }
    }
    pub fn count_siblings_for_index(self: *const GameState, col_index: u8, row_index: u8) u8 {
        const i_row_index: i16 = @intCast(row_index);
        const i_col_index: i16 = @intCast(col_index);

        assert(row_index < self.row_length);
        assert(col_index < self.row_count);

        var count: u8 = 0;
        var row_mod: i16 = -1;
        while (row_mod <= 1) : (row_mod += 1) {
            var col_mod: i16 = -1;
            while (col_mod <= 1) : (col_mod += 1) {
                const row: i16 = wrap_number(i_row_index + row_mod, 0, self.row_count);
                const col: i16 = wrap_number(i_col_index + col_mod, 0, self.row_length);

                assert(col >= 0);
                assert(row >= 0);
                assert(col < self.row_length);
                assert(row < self.row_count);
                // NOTE: Dont count self
                if (!((col_mod == 0) and (row_mod == 0))) {
                    if (self.last_frame[@intCast(row)][@intCast(col)]) {
                        count = count + 1;
                    }
                }
            }
        }

        return count;
    }

    fn wrap_number(value: i16, min: u8, max: u8) i16 {
        var new_value = value;
        if (value < min) {
            new_value = @intCast(max);
            new_value -= 1;
        } else if (value >= max) {
            new_value = min;
        }
        return new_value;
    }
};

test "count siblings" {
    const allocator = &std.testing.allocator;

    var gs = try GameState.init(5, 5, allocator);
    defer gs.deinit(allocator);

    gs.grid[1][1] = true;
    gs.grid[1][3] = true;
    gs.grid[4][3] = true;
    gs.update_last_frame();
    try std.testing.expectEqual(1, gs.count_siblings_for_index(0, 0));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(1, 0));
    try std.testing.expectEqual(3, gs.count_siblings_for_index(2, 0));
    try std.testing.expectEqual(2, gs.count_siblings_for_index(3, 0));
    try std.testing.expectEqual(2, gs.count_siblings_for_index(4, 0));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(0, 1));
    try std.testing.expectEqual(0, gs.count_siblings_for_index(1, 1));
    try std.testing.expectEqual(2, gs.count_siblings_for_index(2, 1));
    try std.testing.expectEqual(0, gs.count_siblings_for_index(3, 1));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(4, 1));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(0, 2));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(1, 2));
    try std.testing.expectEqual(2, gs.count_siblings_for_index(2, 2));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(3, 2));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(4, 2));
    try std.testing.expectEqual(0, gs.count_siblings_for_index(0, 3));
    try std.testing.expectEqual(0, gs.count_siblings_for_index(1, 3));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(2, 3));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(3, 3));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(4, 3));
    try std.testing.expectEqual(0, gs.count_siblings_for_index(0, 4));
    try std.testing.expectEqual(0, gs.count_siblings_for_index(1, 4));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(2, 4));
    try std.testing.expectEqual(0, gs.count_siblings_for_index(3, 4));
    try std.testing.expectEqual(1, gs.count_siblings_for_index(4, 4));
}

test "next state" {
    const allocator = &std.testing.allocator;

    var gs = try GameState.init(5, 5, allocator);
    defer gs.deinit(allocator);

    gs.grid[1][1] = true;
    gs.grid[1][3] = true;
    gs.grid[2][2] = true;
    try gs.next();

    try std.testing.expectEqual(false, gs.grid[0][0]);
    try std.testing.expectEqual(false, gs.grid[0][1]);
    try std.testing.expectEqual(false, gs.grid[0][2]);
    try std.testing.expectEqual(false, gs.grid[0][3]);
    try std.testing.expectEqual(false, gs.grid[0][4]);
    try std.testing.expectEqual(false, gs.grid[1][0]);
    try std.testing.expectEqual(false, gs.grid[1][1]);
    try std.testing.expectEqual(true, gs.grid[1][2]);
    try std.testing.expectEqual(false, gs.grid[1][3]);
    try std.testing.expectEqual(false, gs.grid[1][4]);
    try std.testing.expectEqual(false, gs.grid[2][0]);
    try std.testing.expectEqual(false, gs.grid[2][1]);
    try std.testing.expectEqual(true, gs.grid[2][2]);
    try std.testing.expectEqual(false, gs.grid[2][3]);
    try std.testing.expectEqual(false, gs.grid[2][4]);
    try std.testing.expectEqual(false, gs.grid[3][0]);
    try std.testing.expectEqual(false, gs.grid[3][1]);
    try std.testing.expectEqual(false, gs.grid[3][2]);
    try std.testing.expectEqual(false, gs.grid[3][3]);
    try std.testing.expectEqual(false, gs.grid[3][4]);
    try std.testing.expectEqual(false, gs.grid[4][0]);
    try std.testing.expectEqual(false, gs.grid[4][1]);
    try std.testing.expectEqual(false, gs.grid[4][2]);
    try std.testing.expectEqual(false, gs.grid[4][3]);
    try std.testing.expectEqual(false, gs.grid[4][4]);
}

test "init, seed and deinit" {
    const allocator = &std.testing.allocator;

    const gs = try GameState.init(5, 5, allocator);
    defer gs.deinit(allocator);
    gs.seed_state(1);

    try std.testing.expectEqual(true, gs.grid[0][0]);
    try std.testing.expectEqual(true, gs.grid[0][1]);
    try std.testing.expectEqual(false, gs.grid[0][2]);
    try std.testing.expectEqual(false, gs.grid[0][3]);
    try std.testing.expectEqual(false, gs.grid[0][4]);
    try std.testing.expectEqual(true, gs.grid[1][0]);
    try std.testing.expectEqual(true, gs.grid[1][1]);
    try std.testing.expectEqual(true, gs.grid[1][2]);
    try std.testing.expectEqual(false, gs.grid[1][3]);
    try std.testing.expectEqual(false, gs.grid[1][4]);
    try std.testing.expectEqual(true, gs.grid[2][0]);
    try std.testing.expectEqual(true, gs.grid[2][1]);
    try std.testing.expectEqual(false, gs.grid[2][2]);
    try std.testing.expectEqual(true, gs.grid[2][3]);
    try std.testing.expectEqual(false, gs.grid[2][4]);
    try std.testing.expectEqual(true, gs.grid[3][0]);
    try std.testing.expectEqual(false, gs.grid[3][1]);
    try std.testing.expectEqual(true, gs.grid[3][2]);
    try std.testing.expectEqual(false, gs.grid[3][3]);
    try std.testing.expectEqual(false, gs.grid[3][4]);
    try std.testing.expectEqual(true, gs.grid[4][0]);
    try std.testing.expectEqual(false, gs.grid[4][1]);
    try std.testing.expectEqual(true, gs.grid[4][2]);
    try std.testing.expectEqual(false, gs.grid[4][3]);
    try std.testing.expectEqual(true, gs.grid[4][4]);
}
