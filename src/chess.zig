const std = @import("std");

pub fn Chess() type {
    const RANK = 8;
    return struct {
        bitboard: BitBoard,
        game: Game,

        const Self = @This();

        pub fn init() Self {
            return Self{
                .bitboard = BitBoard{},
                .game = Game.init(),
            };
        }

        pub const Game = struct {
            turn: Color,
            kings: [2]King,
            pawns: [16]Pawn,

            pub fn init() Game {
                const pawns = blk: {
                    var pawns: [16]Pawn = undefined;
                    for (0..pawns.len) |i| {
                        if (i < 8) {
                            const pos: u64 = 0b1 << 8 + @as(u6, @intCast(i));
                            pawns[i] = .pawn{.init(.white, pos)};
                        } else {
                            const pos: u64 = 0b1 << 6 * RANK - 8 + @as(u6, @intCast(i));
                            pawns[i] = .pawn{.init(.black, pos)};
                        }
                    }
                    break :blk pawns;
                };

                return Game{
                    .turn = .white,
                    .kings = .{ .init(.white), .init(.black) },
                    .pawns = pawns,
                };
            }
        };

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
            hasMoved: bool,
            justMoved: bool,
            pos: u64,
            color: Color,

            pub fn init(color: Color, pos: u64) Pawn {
                return Pawn{
                    .hasMoved = false,
                    .justMoved = false,
                    .pos = pos,
                    .color = color,
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
            const white_pawns: u64 = 0b1111_1111 << 8;
            const white_rooks: u64 = 0b1000_0001;
            const white_knights: u64 = 0b0100_0010;
            const white_bishops: u64 = 0b0010_0100;
            const white_queen: u64 = 0b0001_0000;
            const white_king: u64 = 0b0000_1000;

            const black_pawns: u64 = 0b1111_1111 << RANK * 6;
            const black_rooks: u64 = 0b1000_0001 << RANK * 7;
            const black_knights: u64 = 0b0100_0010 << RANK * 7;
            const black_bishops: u64 = 0b0010_0100 << RANK * 7;
            const black_queen: u64 = 0b0001_0000 << RANK * 7;
            const black_king: u64 = 0b0000_1000 << RANK * 7;

            white_pieces: u64 = white_pawns | white_rooks | white_knights | white_bishops | white_queen | white_king,
            black_pieces: u64 = black_pawns | black_rooks | black_knights | black_bishops | black_queen | black_king,
            all_pieces: u64 = black_pawns | black_rooks | black_knights | black_bishops | black_queen | black_king | white_pawns | white_rooks | white_knights | white_bishops | white_queen | white_king,

            pieces_arr: [12]u64 = std.mem.zeroes([12]u64),

            const char_arr: [12]u8 = .{
                'p', 'r',
                'k', 'b',
                'q', 's',
                'P', 'R',
                'K', 'B',
                'Q', 'S',
            };

            pub fn bitboard_to_arr(self: BitBoard, pieces: [12]u64) [8][8]u8 { // column, row
                _ = self;
                const board_arr = blk: {
                    var board: [8][8]u8 = undefined;

                    for (0..64) |i| {
                        const row = @as(u8, @intCast(i / 8));
                        const col = @as(u8, @intCast(i % 8));

                        var found = false;

                        for (pieces, 0..) |piece, idx| {
                            if ((piece & (@as(u64, 1) << @as(u6, @intCast(i)))) != 0) {
                                board[row][col] = char_arr[idx];
                                found = true;
                                break;
                            }
                        }

                        if (!found) {
                            board[row][col] = '-';
                        }
                    }
                    break :blk board;
                };

                return board_arr;
            }

            pub fn drawBitBoard(self: BitBoard) void {
                const board_arr = self.bitboard_to_arr(self.pieces_arr);

                for (0..8) |i| {
                    for (0..8) |j| {
                        const k = 7 - i;
                        if ((j + 1) % 8 == 0) {
                            std.debug.print("{c}\n", .{board_arr[k][j]});
                        } else {
                            std.debug.print("{c} ", .{board_arr[k][j]});
                        }
                    }
                }
            }

            pub fn draw_attack(attackboard: u64) void {
                var board: [8][8]u8 = undefined;

                for (0..64) |i| {
                    const row = @as(u8, @intCast(i / 8));
                    const col = @as(u8, @intCast(i % 8));

                    if ((attackboard & (@as(u64, 1) << @as(u6, @intCast(i)))) != 0) {
                        board[row][col] = 'o';
                    } else {
                        board[row][col] = '-';
                    }
                }

                for (0..8) |i| {
                    for (0..8) |j| {
                        const k = 7 - i;
                        if ((j + 1) % 8 == 0) {
                            std.debug.print("{c}\n", .{board[k][j]});
                        } else {
                            std.debug.print("{c} ", .{board[k][j]});
                        }
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
            const b_file = a_file << 1;
            const g_file = h_file >> 1;
            const row2 = 0x0000_0000_0000_FF00;
            const row7 = 0x00FF_0000_0000_0000;

            pub fn attacks(self: *const BitBoard, pos_in: u64, piece: Pieces) u64 {
                switch (piece) {
                    .rook => return self.rook_attacks(pos_in, piece.rook),
                    .bishop => return self.bishop_attacks(pos_in, piece.bishop),
                    .queen => return self.queen_attacks(pos_in, piece.queen),
                    .knight => return self.knight_attacks(pos_in, piece.knight),
                    .pawn => return self.pawn_attacks(pos_in, piece.pawn),
                    .king => return self.king_attacks(pos_in, piece.king),
                }
            }
            fn rook_attacks(self: *const BitBoard, pos_in: u64, color: Color) u64 {
                const boundries: [4]u64 = .{ h_file, top_file, a_file, bot_file };
                const dirs = [4]i8{ 1, RANK, -1, -RANK }; // {right, up} with << and {left, down} with >>
                //
                var pos = pos_in;
                var attack_field: u64 = 0;
                for (dirs, boundries) |dir, boundary| {
                    pos = pos_in;
                    while ((boundary & pos) == 0 and pos != 0) {
                        if (dir > 0) pos <<= @as(u6, @intCast(dir)) else pos >>= @as(u6, @intCast(-dir));
                        if (pos == 0) break;

                        if (self.all_pieces & pos != 0) { //piece_collision
                            const is_enemy = self.isEnemy(pos, color);
                            if (is_enemy) attack_field |= pos;
                            break;
                        }
                        attack_field |= pos;
                    }
                }
                return attack_field;
            }

            fn bishop_attacks(self: *const BitBoard, pos_in: u64, color: Color) u64 {
                const dirs: [4]i8 = .{ RANK + 1, RANK - 1, -RANK - 1, -RANK + 1 };
                const boundries: [4]u64 = .{
                    top_file | h_file, //NE
                    top_file | a_file, //NW
                    bot_file | a_file, //BW
                    bot_file | h_file, //BE
                };

                var pos = pos_in;
                var attack_field: u64 = 0;
                for (dirs, boundries) |dir, boundary| {
                    pos = pos_in;
                    while ((boundary & pos) == 0 and pos != 0) {
                        if (dir > 0) pos <<= @as(u6, @intCast(dir)) else pos >>= @as(u6, @intCast(-dir));
                        if (pos == 0) break;

                        if (self.all_pieces & pos != 0) { //piece_collision
                            const is_enemy = self.isEnemy(pos, color);
                            if (is_enemy) attack_field |= pos;
                            break;
                        }
                        attack_field |= pos;
                    }
                }
                return attack_field;
            }

            fn queen_attacks(self: *const BitBoard, pos_in: u64, color: Color) u64 {
                return self.bishop_attacks(pos_in, color) | self.rook_attacks(pos_in, color);
            }

            fn knight_attacks(self: *const BitBoard, pos_in: u64, color: Color) u64 {
                const boundaries: [8]u64 = .{
                    b_file | a_file | bot_file, // LD
                    g_file | h_file | top_file, // RU
                    top_file | row7 | h_file, // UR
                    top_file | row7 | a_file, // UL
                    b_file | a_file | top_file, // LU
                    g_file | h_file | bot_file, // RD
                    row2 | bot_file | a_file, // DL
                    row2 | bot_file | h_file, // DR
                };

                const dirs: [8]i6 = .{
                    -RANK - 2,
                    RANK + 2,
                    2 * RANK + 1,
                    2 * RANK - 1,
                    RANK - 2,
                    -RANK + 2,
                    -2 * RANK - 1,
                    -2 * RANK + 1,
                };

                var pos = pos_in;
                var attack_field: u64 = 0;

                for (dirs, boundaries, 0..) |dir, boundary, i| {
                    pos = pos_in;
                    _ = i;
                    // if (i >= 7) break;
                    if ((boundary & pos) != 0) continue;
                    if (dir > 0) pos <<= @as(u6, @intCast(dir)) else pos >>= @as(u6, @intCast(-dir));
                    if (pos == 0) continue;

                    const is_enemy = self.isEnemy(pos, color);
                    if (is_enemy) {
                        attack_field |= pos;
                        continue;
                    }

                    attack_field |= pos;
                }
                return attack_field;
            }

            fn pawn_attacks(self: *const BitBoard, pos_in: u64, pawn: Pawn) u64 { // en passant
                const color = pawn.color;

                const boundariesDIAG: [2]u64 = if (color == .white) .{
                    top_file | a_file,
                    top_file | h_file,
                } else .{
                    bot_file | h_file,
                    bot_file | a_file,
                };

                const boundariesFORW: [2]u64 = if (color == .white) .{
                    top_file,
                    top_file | row7,
                } else .{
                    bot_file,
                    bot_file | row2,
                };

                const dirsDIAG: [2]i6 = if (color == .white) .{
                    RANK - 1, //left
                    RANK + 1,
                } else .{
                    -RANK + 1, //left (seen from piece)
                    -RANK - 1,
                };

                const dirsFORW: [2]i6 = if (color == .white) .{
                    RANK,
                    2 * RANK,
                } else .{
                    -RANK,
                    -2 * RANK,
                };

                var pos = pos_in;
                var attack_field: u64 = 0;
                for (dirsDIAG, boundariesDIAG) |dir, boundary| {
                    pos = pos_in;
                    if ((boundary & pos) != 0) continue;
                    if (dir > 0) pos <<= @as(u6, @intCast(dir)) else pos >>= @as(u6, @intCast(-dir));
                    if (pos == 0) continue;

                    const is_enemy = self.isEnemy(pos_in, color);
                    if (is_enemy) attack_field |= pos;
                    attack_field |= pos;
                }

                for (dirsFORW, boundariesFORW) |dir, boundary| { // något lurt med dubbelmovet.
                    pos = pos_in;
                    if ((boundary & pos) != 0) continue;
                    if (dir > 0) pos <<= @as(u6, @intCast(dir)) else pos >>= @as(u6, @intCast(-dir));
                    if (pos == 0) continue;

                    const has_piece: bool = (self.all_pieces & pos) != 0;
                    if (!has_piece) {
                        attack_field |= pos;
                        if (pawn.hasMoved) break;
                    } else break;
                }
                return attack_field;
            }

            fn king_attacks(self: *const BitBoard, pos_in: u64, king: King) u64 {
                const boundaries: [8]u64 = .{
                    h_file, // R
                    h_file | top_file, // UR
                    top_file, // U
                    top_file | a_file, // UL
                    a_file, // L
                    a_file | bot_file, // DL
                    bot_file, // D
                    bot_file | h_file, // DR
                };

                const dirs: [8]i8 = .{
                    1,
                    RANK + 1,
                    RANK,
                    RANK - 1,
                    -1,
                    -RANK - 1,
                    -RANK,
                    -RANK + 1,
                };
                const color = king.color;

                var pos = pos_in;
                var attack_field: u64 = 0;
                for (dirs, boundaries) |dir, boundary| {
                    pos = pos_in;
                    if ((boundary & pos) != 0) continue;
                    if (dir > 0) pos <<= @as(u6, @intCast(dir)) else pos >>= @as(u6, @intCast(-dir));
                    if (pos == 0) continue;

                    if (self.all_pieces & pos != 0) { //piece_collision
                        const is_enemy = self.isEnemy(pos, color);
                        if (is_enemy) attack_field |= pos;
                        break;
                    }
                    attack_field |= pos;
                }
                return attack_field;
            }

            fn isEnemy(self: *const BitBoard, pos: u64, color: Color) bool {
                return (color == Color.white and (self.black_pieces & pos != 0) or
                    (color == Color.black and (self.white_pieces & pos) != 0));
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

    {
        // const pawnattack = chesstest.bitboard.attacks(0b1 << 33, piece);
        // chessType.BitBoard.draw_attack(pawnattack);

        // const pawnattack = chesstest.bitboard.attacks(@as(u64, 0b1) << 34, piece);
        // chessType.BitBoard.draw_attack(pawnattack);
        {
            const king = chessType.King{
                .color = .white,
                .hasMoved = false,
            };
            const piece = chessType.Pieces{ .king = king };

            // const kingattack = chesstest.bitboard.attacks(0b1 << 14, piece);
            // chessType.BitBoard.draw_attack(kingattack);

            for (0..64) |i| {
                const kingattack = chesstest.bitboard.attacks(@as(u64, 0b1) << @as(u6, @intCast(i)), piece);
                _ = kingattack;
                // std.debug.print("\x1b[2J\x1b[H", .{});
                // chessType.BitBoard.draw_attack(kingattack);
                // std.time.sleep(500 * std.time.ns_per_ms);
            }
        }

        {
            const pawn = chessType.Pawn{
                .color = .white,
                .hasMoved = false,
                .justMoved = false,
            };
            const piece = chessType.Pieces{ .pawn = pawn };

            for (0..64) |i| {
                const pawnattack = chesstest.bitboard.attacks(@as(u64, 0b1) << @as(u6, @intCast(i)), piece);
                _ = pawnattack;
                // std.debug.print("\x1b[2J\x1b[H", .{});
                // chessType.BitBoard.draw_attack(pawnattack);
                // std.time.sleep(100 * std.time.ns_per_ms);
            }
        }

        // chessType.BitBoard.draw_attack(h_file | g_file);
        // const rookattack = chesstest.bitboard.attacks(0b1 << 35, chessType.Pieces{ .rook = .white });
        // chessType.BitBoard.draw_attack(rookattack);
    }

    for (0..64) |i| {
        const bishopattack = chesstest.bitboard.attacks(@as(u64, 0b1) << @as(u6, @intCast(i)), chessType.Pieces{ .bishop = .white });
        _ = bishopattack;
    }

    for (0..64) |i| {
        const rookattack = chesstest.bitboard.attacks(@as(u64, 0b1) << @as(u6, @intCast(i)), chessType.Pieces{ .rook = .white });
        // chessType.BitBoard.draw_attack(rookattack);
        // std.time.sleep(220 * std.time.ns_per_ms);
        _ = rookattack;
    }

    for (0..64) |i| {
        const queenattack = chesstest.bitboard.attacks(@as(u64, 0b1) << @as(u6, @intCast(i)), chessType.Pieces{ .queen = .white });
        _ = queenattack;
        // chessType.BitBoard.draw_attack(queenattack);
        // std.time.sleep(800 * std.time.ns_per_ms);
    }

    //const bishopattack = chesstest.bitboard.attacks(@as(u64, 0b1) << 8, chessType.Pieces{ .bishop = .white });
    //chessType.BitBoard.draw_attack(@as(u64, 0b1) << 8, bishopattack);
}
