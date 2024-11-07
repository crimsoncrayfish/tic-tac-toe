const std = @import("std");
test "random numbers" {
    var prng = std.rand.DefaultPrng.init(10);
    const rand = prng.random();

    const a = rand.float(f32);
    const b = rand.boolean();
    const c = rand.int(u8);
    const d = rand.intRangeAtMost(u8, 0, 255);

    _ = .{ a, b, c, d };
}
