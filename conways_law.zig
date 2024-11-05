const std = @import("std");

pub fn apply_conways_law(current_state: bool, neigbours_count: u8) bool {
    if (!current_state) {
        const has_3_neighbours = neigbours_count == 3;
        return has_3_neighbours;
    }
    switch (neigbours_count) {
        0, 1 => return false,
        2, 3 => return true,
        else => return false,
    }
}

test "calculate next state" {
    try std.testing.expect(apply_conways_law(true, 0) == false);
    try std.testing.expect(apply_conways_law(true, 1) == false);
    try std.testing.expect(apply_conways_law(true, 2) == true);
    try std.testing.expect(apply_conways_law(true, 3) == true);
    try std.testing.expect(apply_conways_law(true, 4) == false);
    try std.testing.expect(apply_conways_law(true, 5) == false);
    try std.testing.expect(apply_conways_law(true, 6) == false);
    try std.testing.expect(apply_conways_law(true, 7) == false);
    try std.testing.expect(apply_conways_law(true, 8) == false);

    try std.testing.expect(apply_conways_law(false, 0) == false);
    try std.testing.expect(apply_conways_law(false, 1) == false);
    try std.testing.expect(apply_conways_law(false, 2) == false);
    try std.testing.expect(apply_conways_law(false, 3) == true);
    try std.testing.expect(apply_conways_law(false, 4) == false);
    try std.testing.expect(apply_conways_law(false, 5) == false);
    try std.testing.expect(apply_conways_law(false, 6) == false);
    try std.testing.expect(apply_conways_law(false, 7) == false);
    try std.testing.expect(apply_conways_law(false, 8) == false);
}
