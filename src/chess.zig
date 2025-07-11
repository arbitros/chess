const std = @import("std");

pub fn Chess(BOARD_SIZE: u32) type {
    return struct {
        board: [BOARD_SIZE][BOARD_SIZE]Pieces, //row, column
        bitboard: BitBoard,

        const Self = @This();

        pub fn initBase() Self {
            if (BOARD_SIZE % 2 != 0) {
                @compileError("Board size must be divisible by 2");
            }
            const board: [BOARD_SIZE][BOARD_SIZE]Pieces = blk: {
                var board: [BOARD_SIZE][BOARD_SIZE]Pieces = undefined;
                for (0..BOARD_SIZE) |i| {
                    for (0..BOARD_SIZE) |j| {
                        if (i == BOARD_SIZE - 2) { //pawns
                            board[j][i] = Pieces{ .pawn = Pawn.init(Color.black) };
                        } else if (i == 1) {
                            board[j][i] = Pieces{ .pawn = Pawn.init(Color.white) };
                        } else if (i == 0) {
                            if (j == 0 or j == BOARD_SIZE - 1) { // rooks
                                board[j][i] = Pieces{ .rook = .white };
                            } else if ((j >= 1 and j <= BOARD_SIZE / 2 - 3) or (j >= BOARD_SIZE / 2 + 2 and j <= BOARD_SIZE - 2)) {
                                board[j][i] = Pieces{ .knight = .white };
                            } else if (j == BOARD_SIZE / 2 - 2 or j == BOARD_SIZE / 2 + 1) {
                                board[j][i] = Pieces{ .bishop = .white };
                            } else if (j == BOARD_SIZE / 2 - 1) {
                                board[j][i] = Pieces{ .queen = .white };
                            } else if (j == BOARD_SIZE / 2) {
                                board[j][i] = Pieces{ .king = King.init(Color.white) };
                            } else {
                                board[j][i] = Pieces.none;
                            }
                        } else if (i == BOARD_SIZE - 1) {
                            if (j == 0 or j == BOARD_SIZE - 1) { // rooks
                                board[j][i] = Pieces{ .rook = .black };
                            } else if ((j >= 1 and j <= BOARD_SIZE / 2 - 3) or (j >= BOARD_SIZE / 2 + 2 and j <= BOARD_SIZE - 2)) {
                                board[j][i] = Pieces{ .knight = .black };
                            } else if (j == BOARD_SIZE / 2 - 2 or j == BOARD_SIZE / 2 + 1) {
                                board[j][i] = Pieces{ .bishop = .black };
                            } else if (j == BOARD_SIZE / 2 - 1) {
                                board[j][i] = Pieces{ .queen = .black };
                            } else if (j == BOARD_SIZE / 2) {
                                board[j][i] = Pieces{ .king = King.init(Color.black) };
                            } else {
                                board[j][i] = Pieces.none;
                            }
                        } else {
                            board[j][i] = Pieces.none;
                        }
                    }
                }
                break :blk board;
            };

            return Self{
                .board = board,
                .bitboard = BitBoard{},
            };
        }

        pub fn print(self: *const Self) void {
            for (0..BOARD_SIZE) |i| {
                for (0..BOARD_SIZE) |j| {
                    switch (self.board[j][i]) {
                        .pawn => {
                            if (j == BOARD_SIZE - 1) {
                                std.debug.print("p\n", .{});
                            } else {
                                std.debug.print("p ", .{});
                            }
                        },
                        .rook => {
                            if (j == BOARD_SIZE - 1) {
                                std.debug.print("r\n", .{});
                            } else {
                                std.debug.print("r ", .{});
                            }
                        },
                        .none => {
                            if (j == BOARD_SIZE - 1) {
                                std.debug.print("-\n", .{});
                            } else {
                                std.debug.print("- ", .{});
                            }
                        },
                        .knight => std.debug.print("h ", .{}),
                        .bishop => std.debug.print("b ", .{}),
                        .queen => std.debug.print("q ", .{}),
                        .king => std.debug.print("k ", .{}),
                    }
                }
            }
        }

        pub const Pieces = union(enum) {
            pawn: Pawn,
            rook: Color,
            knight: Color,
            bishop: Color,
            queen: Color,
            king: King,
            none,
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

            pub fn bitboard_to_arr(pieces: [12]u64) [64]u8 {
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

            pub fn draw_attack(self: BitBoard, pos: u64, attack: u64) void {
                const board_arr = self.bitboard_to_arr(pieces);

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

            const a_file: u64 = 0x0101010101010101;
            const h_file: u64 = 0x8080808080808080;
            const top_file: u64 = 0xFF00000000000000;
            const bot_file: u64 = 0xFF;

            const boundries: [4]u64 = .{ h_file, top_file, a_file, bot_file };
            const dirs = [4]i8{ 1, RANK, -1, -RANK }; // {right, up} with << and {left, down} with >>

            pub fn attacks(self: *const BitBoard, pos_in: u64, piece: Pieces) u64 {
                var pos = pos_in;

                switch (piece) {
                    .rook => { // should be complete, test tomorrow!
                        var attack_field: u64 = pos;

                        for (dirs, boundries) |dir, boundry| {
                            while ((boundry & pos) == 0) {
                                if (dir > 0) pos <<= @as(u4, @intCast(dir)) else pos >>= @as(u4, @intCast(-dir));

                                if ((self.all_pieces & pos) != 0) { //piece_collision
                                    if (piece.rook == Color.white and (self.black_pieces & pos) != 0) { //white
                                        attack_field |= pos;
                                        pos = pos_in;
                                        break;
                                    } else if (piece.rook == Color.black and (self.white_pieces & pos) != 0) { //black
                                        attack_field |= pos;
                                        pos = pos_in;
                                        break;
                                    }
                                } else {
                                    attack_field |= pos;
                                }
                            }
                        }
                        return attack_field;
                    },
                    else => return 0,
                }
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
    };
}

test {
    const chessType = Chess(8);
    var chess = chessType.initBase();
    chess.print();
    const black = chess.bitboard.calculate_black();
    const white = chess.bitboard.calculate_white();
    const attack = chess.bitboard.attacks(0b1 << 21, chessType.Pieces{ .rook = .white });
    std.debug.print("{b}\n{b}\n{b}\n", .{ black, white, attack });

    chess.bitboard.calculate_array();
    std.debug.print("\n", .{});
    chess.bitboard.draw();
}
