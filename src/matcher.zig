const std = @import("std");

const Self = @This();

pub const MatcherError = error{
    MalformedClass,
    UnsupportedClass,
};

const Class = union(enum) {
    decimal: DecimalClass,
    word: WordClass,
    positive_group: PositiveGroupClass,
    literal: LiteralClass,

    fn getFromString(str: []const u8) !Class {
        if (str.len < 1) {
            return MatcherError.MalformedClass;
        }

        switch (str[0]) {
            '\\' => {
                if (str.len < 2) {
                    return MatcherError.MalformedClass;
                }

                switch (str[1]) {
                    'd' => return .{ .decimal = DecimalClass{} },
                    'w' => return .{ .word = WordClass{} },
                    else => return MatcherError.UnsupportedClass,
                }
            },
            '[' => {
                const group_end = std.mem.indexOfScalar(u8, str[1..], ']') orelse return MatcherError.MalformedClass;

                return .{ .positive_group = try PositiveGroupClass.init(str[1 .. group_end + 1]) };
            },
            else => return .{ .literal = LiteralClass.init(str[0]) },
        }

        return MatcherError.MalformedClass;
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

const WordClass = struct {
    fn match(_: WordClass, char: u8) bool {
        if ((char >= 'A' and char <= 'Z') or (char >= 'a' and char <= 'z') or (char >= '0' and char <= '9') or char == '_') {
            return true;
        }

        return false;
    }
};

const PositiveGroupClass = struct {
    charset: std.bit_set.IntegerBitSet(256),

    fn init(chars: []const u8) !PositiveGroupClass {
        var charset = std.bit_set.IntegerBitSet(256).initEmpty();

        for (chars) |char| {
            charset.set(char);
        }

        return .{
            .charset = charset,
        };
    }

    fn match(self: PositiveGroupClass, char: u8) bool {
        return self.charset.isSet(char);
    }
};

test PositiveGroupClass {
    var pg_class = try PositiveGroupClass.init("asdf");

    try std.testing.expect(pg_class.match('a'));
    try std.testing.expect(pg_class.match('s'));
    try std.testing.expect(pg_class.match('d'));
    try std.testing.expect(pg_class.match('f'));

    try std.testing.expect(!pg_class.match('x'));
    try std.testing.expect(!pg_class.match('z'));
}

test WordClass {
    var class = WordClass{};
    try std.testing.expect(class.match('R'));
    try std.testing.expect(!class.match('+'));
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

pub fn init(pattern: []const u8) !Self {
    return .{
        .pattern = try Class.getFromString(pattern),
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
    var matcher_obj = try Self.init("j");
    try std.testing.expect(matcher_obj.match("fulljar"));
    try std.testing.expect(!matcher_obj.match("hello"));

    matcher_obj = try Self.init("\\d");
    try std.testing.expect(matcher_obj.match("full3jar"));
    try std.testing.expect(!matcher_obj.match("hello"));

    matcher_obj = try Self.init("\\w");
    try std.testing.expect(matcher_obj.match("---hello---"));
    try std.testing.expect(!matcher_obj.match("-+^^^$"));

    matcher_obj = try Self.init("[abc]");
    try std.testing.expect(matcher_obj.match("hello_ab_wordl"));
    try std.testing.expect(matcher_obj.match("fcz"));
    try std.testing.expect(!matcher_obj.match("hello"));
}
