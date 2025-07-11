const std = @import("std");

pub fn Chess() type {
    return struct {
        bitboard: BitBoard,

        const Self = @This();

        pub fn init() Self {
            return Self{
                .bitboard = BitBoard{},
            };
        }

        pub const Pieces = union(enum) {
            pawn: Pawn,
            rook: Color,
            knight: Color,
            bishop: Color,
            queen: Color,
            king: King,
        };

        pub const Color = enum {
            black,
            white,
        };

        pub const Pawn = struct { // SPEICAL RULES: En passant, Promotion, Double move
            color: Color,
            hasMoved: bool,
            justMoved: bool,

            pub fn init(color: Color) Pawn {
                return Pawn{
                    .color = color,
                    .hasMoved = false,
                    .justMoved = false,
                };
            }
        };

        pub const King = struct { // SPEICAL RULES: Check, Checkmate, Castle
            color: Color,
            hasMoved: bool,
            pub fn init(color: Color) King {
                return King{
                    .color = color,
                    .hasMoved = false,
                };
            }
        };

        pub const BitBoard = struct {
            const RANK = 8;

            all_pieces: u64 = 0b1111_1111 << 8 | 0b1000_0001 | 0b0100_0010 | 0b0010_0100 | 0b0000_1000 |
                0b0001_0000 | 0b1111_1111 << RANK * 6 | 0b1000_0001 << RANK * 7 | 0b0100_0010 << RANK * 7 |
                0b0010_0100 << RANK * 7 | 0b0000_1000 << RANK * 7 | 0b0001_0000 << RANK * 7,

            white_pawns: u64 = 0b1111_1111 << 8,
            white_rooks: u64 = 0b1000_0001,
            white_knights: u64 = 0b0100_0010,
            white_bishops: u64 = 0b0010_0100,
            white_queen: u64 = 0b0000_1000,
            white_king: u64 = 0b0001_0000,
            white_pieces: u64 = 0b1111_1111 | 0b1000_0001 | 0b0100_0010 | 0b0010_0100 | 0b0000_1000 | 0b0001_0000,

            black_pawns: u64 = 0b1111_1111 << RANK * 6,
            black_rooks: u64 = 0b1000_0001 << RANK * 7,
            black_knights: u64 = 0b0100_0010 << RANK * 7,
            black_bishops: u64 = 0b0010_0100 << RANK * 7,
            black_queen: u64 = 0b0000_1000 << RANK * 7,
            black_king: u64 = 0b0001_0000 << RANK * 7,
            black_pieces: u64 = 0b1111_1111 << RANK * 6 | 0b1000_0001 << RANK * 7 | 0b0100_0010 << RANK * 7 |
                0b0010_0100 << RANK * 7 | 0b0000_1000 << RANK * 7 | 0b0001_0000 << RANK * 7,

            pieces_arr: [12]u64 = std.mem.zeroes([12]u64),

            const char_arr: [12]u8 = .{
                'p', 'r',
                'k', 'b',
                'q', 's',
                'P', 'R',
                'K', 'B',
                'Q', 'S',
            };

            pub fn bitboard_to_arr(self: BitBoard, pieces: [12]u64) [64]u8 {
                _ = self;
                const board_arr = blk: {
                    var board_arr: [64]u8 = std.mem.zeroes([64]u8);
                    for (pieces, 0..) |piece, i| {
                        var cnt: u8 = 0;
                        var cur: u64 = 1;
                        while (cnt < 64) {
                            if ((cur & piece) != 0) {
                                board_arr[cnt] = char_arr[i];
                            }

                            cnt += 1;
                            if (cnt == 64) break;
                            cur <<= 1;
                        }
                    }

                    for (board_arr, 0..) |e, i| {
                        if (e == 0) {
                            board_arr[i] = '-';
                        }
                    }
                    break :blk board_arr;
                };

                return board_arr;
            }

            pub fn drawBitBoard(self: BitBoard) void {
                const board_arr = self.bitboard_to_arr(self.pieces_arr);

                for (0..board_arr.len) |i| {
                    if ((i + 1) % 8 == 0) {
                        std.debug.print("{c}\n", .{board_arr[i]});
                    } else {
                        std.debug.print("{c} ", .{board_arr[i]});
                    }
                }
            }

            pub fn draw_attack(pos: u64, attackboard: u64) void {
                var cur: u64 = 1;
                var board_arr: [64]u8 = std.mem.zeroes([64]u8);
                for (&board_arr) |*e| {
                    if (pos & cur != 0) {
                        e.* = 'P';
                    } else if (attackboard & cur != 0) {
                        e.* = 'o';
                    } else {
                        e.* = '-';
                    }
                    cur <<= 1;
                }

                for (0..board_arr.len) |i| {
                    if ((i + 1) % 8 == 0) {
                        std.debug.print("{c}\n", .{board_arr[i]});
                    } else {
                        std.debug.print("{c} ", .{board_arr[i]});
                    }
                }
            }

            pub fn calculate_occupied(self: BitBoard) u64 {
                const all_pieces: u64 = self.white_pawns | self.white_rooks | self.white_knights |
                    self.white_bishops | self.white_queen | self.white_king | self.black_pawns |
                    self.black_rooks | self.black_knights | self.black_bishops | self.black_queen |
                    self.black_king;

                return all_pieces;
            }

            pub fn calculate_white(self: BitBoard) u64 {
                const white_pieces: u64 = self.white_pawns | self.white_rooks | self.white_knights |
                    self.white_bishops | self.white_queen | self.white_king;
                return white_pieces;
            }
            pub fn calculate_black(self: BitBoard) u64 {
                const black_pieces: u64 = self.black_pawns | self.black_rooks | self.black_knights |
                    self.black_bishops | self.black_queen | self.black_king;
                return black_pieces;
            }

            pub fn calculate_array(self: *BitBoard) void {
                self.pieces_arr[0] = self.white_pawns;
                self.pieces_arr[1] = self.white_rooks;
                self.pieces_arr[2] = self.white_knights;
                self.pieces_arr[3] = self.white_bishops;
                self.pieces_arr[4] = self.white_queen;
                self.pieces_arr[5] = self.white_king;

                self.pieces_arr[6] = self.black_pawns;
                self.pieces_arr[7] = self.black_rooks;
                self.pieces_arr[8] = self.black_knights;
                self.pieces_arr[9] = self.black_bishops;
                self.pieces_arr[10] = self.black_queen;
                self.pieces_arr[11] = self.black_king;
            }

            const a_file: u64 = 0x0101_0101_01010101;
            const h_file: u64 = 0x8080_8080_8080_8080;
            const top_file: u64 = 0xFF00_0000_0000_0000;
            const bot_file: u64 = 0x0000_0000_0000_00FF;

            pub fn attacks(self: *const BitBoard, pos_in: u64, piece: Pieces) u64 {
                const org_pos = pos_in;
                var pos = org_pos;

                switch (piece) {
                    .rook => {
                        const boundries: [4]u64 = .{ h_file, top_file, a_file, bot_file };
                        const dirs = [4]i8{ 1, RANK, -1, -RANK }; // {right, up} with << and {left, down} with >>
                        var attack_field: u64 = pos;

                        for (dirs, boundries) |dir, boundry| {
                            pos = org_pos;
                            while (boundry & pos == 0) {
                                if (dir > 0) pos <<= @as(u4, @intCast(dir)) else pos >>= @as(u4, @intCast(-dir));

                                if (self.all_pieces & pos != 0) { //piece_collision
                                    if (piece.rook == Color.white and (self.black_pieces & pos) != 0) { //white
                                        attack_field |= pos;
                                        break;
                                    } else if (piece.rook == Color.black and (self.white_pieces & pos) != 0) { //black
                                        attack_field |= pos;
                                        break;
                                    } else {
                                        break;
                                    }
                                }
                                attack_field |= pos;
                            }
                        }
                        return attack_field;
                    },
                    .bishop => {
                        const dirs: [4]i8 = .{ RANK + 1, -(RANK + 1), RANK - 1, -RANK + 1 }; //UPR, DOR, UPL, DOL
                        const boundries: [4]u64 = .{
                            top_file | h_file,
                            bot_file | h_file,
                            top_file | a_file,
                            bot_file | a_file,
                        };

                        var attack_field: u64 = 0;
                        var cnt: u8 = 0;
                        for (dirs, boundries) |dir, boundry| { // INFINITE LOOP AT POS 8 !!!
                            if ((boundry & pos) != 0) continue;
                            pos = org_pos;
                            cnt = 0;
                            while ((boundry & pos) == 0) {
                                cnt += 1;
                                if (cnt > 254) break;
                                if (dir > 0) pos <<= @as(u4, @intCast(dir)) else pos >>= @as(u4, @intCast(-dir));

                                if ((boundry & pos) != 0) break;

                                if (self.all_pieces & pos != 0) { //piece_collision
                                    const is_enemy = (piece.bishop == Color.white and (self.black_pieces & pos != 0) or
                                        (piece.bishop == Color.black and (self.white_pieces & pos) != 0));
                                    if (is_enemy) attack_field |= pos;
                                    break;
                                }
                                attack_field |= pos;
                            }
                        }
                        return attack_field;
                    },
                    else => return 0,
                }
            }
        };
    };
}

test {
    const chessType = Chess();
    var chess = chessType.init();

    const black = chess.bitboard.calculate_black();
    const white = chess.bitboard.calculate_white();
    _ = black;
    _ = white;

    chess.bitboard.calculate_array();
    std.debug.print("\n", .{});
    chess.bitboard.drawBitBoard();
    std.debug.print("\n", .{});

    const chesstest = Chess(){ // get a clean board when testing attacks of pieces
        .bitboard = std.mem.zeroes(chessType.BitBoard),
    };

    //const rookattack = chesstest.bitboard.attacks(0b1 << 0, chessType.Pieces{ .rook = .white });
    //chessType.BitBoard.draw_attack(0b1 << 0, rookattack);

    //for (0..64) |i| {
    //    const bishopattack = chesstest.bitboard.attacks(@as(u64, 0b1) << @as(u6, @intCast(i)), chessType.Pieces{ .bishop = .white });
    //    chessType.BitBoard.draw_attack(@as(u64, 0b1) << @as(u6, @intCast(i)), bishopattack);
    //    std.time.sleep(std.time.ns_per_s);
    //}

    const bishopattack = chesstest.bitboard.attacks(@as(u64, 0b1) << 8, chessType.Pieces{ .bishop = .white });
    chessType.BitBoard.draw_attack(@as(u64, 0b1) << 8, bishopattack);
}
