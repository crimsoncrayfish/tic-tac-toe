const std = @import("std");
const stdout = std.io.getStdOut().writer();
const Pool = std.Thread.Pool;
const WaitGroup = std.Thread.WaitGroup;

const ArgsT = struct { l: *std.Thread.Mutex, id: usize };

pub fn main() u8 {
    var my_pool: Pool = undefined;
    const cpu_count: u8 = 5;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    my_pool.init(Pool.Options{ .allocator = allocator, .n_jobs = cpu_count }) catch {
        return 3;
    };
    defer my_pool.deinit();

    var lock = std.Thread.Mutex{};

    var value: u8 = 0;
    const max: u8 = 10;
    while (value < max) : (value += 1) {
        my_pool.spawn(printHelloWithLocks, .{ArgsT{ .l = &lock, .id = value }}) catch {
            return 3;
        };
    }
    var wait_group: WaitGroup = undefined;
    wait_group.reset();

    my_pool.waitAndWork(&wait_group);

    wait_group.wait();
    return 0;
}

fn printHelloBuffed() !void {
    var buffer = std.io.bufferedWriter(stdout);
    var bufOut = buffer.writer();
    try bufOut.print("Hellp\n", .{});
    try buffer.flush();
}

fn printHelloWithLocks(args: ArgsT) void {
    args.l.lock();
    _ = stdout.print("T: {0}\n", .{args.id}) catch {};
    args.l.unlock();
    std.time.sleep(@as(u64, 1000));
    args.l.lock();
    _ = stdout.print("T: {0}\n", .{args.id}) catch {};
    args.l.unlock();
    std.time.sleep(@as(u64, 1000));
    args.l.lock();
    _ = stdout.print("T: {0}\n", .{args.id}) catch {};
    args.l.unlock();
}
