const Track = union(enum) {
    circular: Field,
    rectangular: Field,
};

const Field = enum {
    grass,
    concrete,
};

const std = @import("std");

test {
    const track: Track = .{ .rectangular = Field.concrete };
    std.debug.print("{any}\n", .{track});

    const tal1: u32 = 8;
    const tal2: u32 = 4;
    const tal3 = tal1 / tal2;
    _ = tal3;

    const a = 0b0110;
    const b = 0b1001;

    std.debug.print("{b}\n", .{a | b});

    const arr: u8[12] = .{
        'r', 'R', // rook
        'h', 'H', // knight
        'b', 'B', // bishop
        'q', 'Q', // queen
        'k', 'K', // king
        'p', 'P', // pawn
    };

    std.debug.print("{d}\n", .{c});
}
