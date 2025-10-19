const std = @import("std");

const Self = @This();

const Class = union(enum) {
    decimal: DecimalClass,
    literal: LiteralClass,

    fn getFromString(str: []const u8) Class {
        if (std.mem.eql(u8, str, "\\d")) {
            return .{ .decimal = DecimalClass{} };
        }

        return .{ .literal = LiteralClass.init(str[0]) };
    }

    fn match(self: Class, char: u8) bool {
        switch (self) {
            inline else => |class| return class.match(char),
        }
    }
};

const DecimalClass = struct {
    fn match(_: DecimalClass, char: u8) bool {
        if (char >= '0' and char <= '9') {
            return true;
        }

        return false;
    }
};

test DecimalClass {
    var class = DecimalClass{};
    try std.testing.expect(class.match('6'));
    try std.testing.expect(!class.match('j'));
}

const LiteralClass = struct {
    character: u8,

    fn init(char: u8) LiteralClass {
        return .{ .character = char };
    }

    fn match(self: LiteralClass, char: u8) bool {
        if (char == self.character) {
            return true;
        }

        return false;
    }
};

test LiteralClass {
    var class = LiteralClass.init('f');
    try std.testing.expect(class.match('f'));
    try std.testing.expect(!class.match('j'));
}

pattern: Class,

pub fn init(pattern: []const u8) Self {
    return .{
        .pattern = Class.getFromString(pattern),
    };
}

pub fn match(self: *Self, input: []const u8) bool {
    for (input) |char| {
        if (self.pattern.match(char)) {
            return true;
        }
    }

    return false;
}

test match {
    var matcher_obj = Self.init("j");
    try std.testing.expect(matcher_obj.match("fulljar"));
    try std.testing.expect(!matcher_obj.match("hello"));

    matcher_obj = Self.init("\\d");
    try std.testing.expect(matcher_obj.match("full3jar"));
    try std.testing.expect(!matcher_obj.match("hello"));
}
