const std = @import("std");
const matcher = @import("matcher.zig");

pub fn main() !void {
    var buffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3 or !std.mem.eql(u8, args[1], "-E")) {
        std.debug.print("Expected first argument to be '-E'\n", .{});
        std.process.exit(1);
    }

    const pattern = args[2];
    var input_matcher = try matcher.init(pattern);

    var input_buffer: [128]u8 = undefined;
    var input_stdin_reader = std.fs.File.stdin().reader(&input_buffer);
    const input_reader = &input_stdin_reader.interface;
    const input_slice = try input_reader.takeDelimiterExclusive('\n');

    // std.debug.print("input bytes read: {s}\n", .{input_slice});

    if (input_matcher.match(input_slice)) {
        std.process.exit(0);
    } else {
        std.process.exit(1);
    }
}
