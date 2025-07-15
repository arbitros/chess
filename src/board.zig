const rl = @import("raylib");
const chessRules = @import("chess.zig");
const Color = chessRules.Chess().Color;

const PADDING: u32 = 80;

pub fn ChessBoard(screenWidth: u32, screenHeight: u32) anyerror!type {
    const WVH: bool = if (screenWidth > screenHeight) true;
    const boardSize = if (WVH) screenHeight - PADDING else screenWidth - PADDING;
    const board_empty: bool = true;

    return struct {
        boardSize: u32,
        boardPos: rl.Vector2,
        piecesTexture: [12]PieceTexture,
        chess: chessRules.Chess(),
        bitboard_piece_array: [12]BitBoardPiece,

        const Self = @This();

        pub const PieceType = union(enum) {
            pawn: Color,
            rook: Color,
            knight: Color,
            bishop: Color,
            queen: Color,
            king: Color,
        };

        pub const BitBoardPiece = struct {
            bitboard: u64,
            piece_type: PieceType,
        };

        pub fn init() !Self {
            const pieces: [12]PieceTexture = blk: {
                var textures: [12]rl.Texture = undefined;
                textures[0] = try rl.loadTexture("textures/white-king.png");
                textures[1] = try rl.loadTexture("textures/white-queen.png");
                textures[2] = try rl.loadTexture("textures/white-rook.png");
                textures[3] = try rl.loadTexture("textures/white-bishop.png");
                textures[4] = try rl.loadTexture("textures/white-knight.png");
                textures[5] = try rl.loadTexture("textures/white-pawn.png");

                textures[6] = try rl.loadTexture("textures/black-king.png");
                textures[7] = try rl.loadTexture("textures/black-queen.png");
                textures[8] = try rl.loadTexture("textures/black-rook.png");
                textures[9] = try rl.loadTexture("textures/black-bishop.png");
                textures[10] = try rl.loadTexture("textures/black-knight.png");
                textures[11] = try rl.loadTexture("textures/black-pawn.png");

                var pieces: [12]PieceTexture = undefined;

                for (textures, 0..) |texture, i| {
                    const pieceTex = PieceTexture.init(texture);
                    if (pieceTex) |_pieceTex| {
                        pieces[i] = _pieceTex;
                    } else {
                        return error.LoadFileData;
                    }
                }

                break :blk pieces;
            };

            const boardPos = if (WVH) rl.Vector2{
                .x = (screenWidth - screenHeight) / 2 + PADDING / 4,
                .y = PADDING / 4,
            } else rl.Vector2{
                .x = PADDING / 4,
                .y = (screenHeight - screenWidth) / 2 + PADDING / 4,
            };

            const chess = chessRules.Chess().init(board_empty);

            const bitboard_piece_array = blk: {
                var pieces_arr: [12]BitBoardPiece = undefined;
                for (0..pieces_arr.len) |i| {
                    pieces_arr[i].bitboard = 0;
                }
                pieces_arr[0].piece_type = .{ .pawn = .white };
                pieces_arr[1].piece_type = .{ .rook = .white };
                pieces_arr[2].piece_type = .{ .knight = .white };
                pieces_arr[3].piece_type = .{ .bishop = .white };
                pieces_arr[4].piece_type = .{ .queen = .white };
                pieces_arr[5].piece_type = .{ .king = .white };

                pieces_arr[6].piece_type = .{ .pawn = .black };
                pieces_arr[7].piece_type = .{ .rook = .black };
                pieces_arr[8].piece_type = .{ .knight = .black };
                pieces_arr[9].piece_type = .{ .bishop = .black };
                pieces_arr[10].piece_type = .{ .queen = .black };
                pieces_arr[11].piece_type = .{ .king = .black };
                break :blk pieces_arr;
            };

            return Self{
                .boardSize = boardSize,
                .boardPos = boardPos,
                .pieces = pieces,
                .chess = chess,
                .bitboard_piece_array = bitboard_piece_array,
            };
        }

        pub fn deinit(self: Self) void {
            for (self.pieces) |piece| {
                rl.unloadTexture(piece.texture);
            }
        }

        pub fn drawEmptyBoard(self: *const Self) void {
            const cellSize = self.boardSize / 8;
            for (0..64) |i| {
                const row = i / 8;
                const col = i % 8;
                const color: rl.Color = if (i % 2 == 0) rl.Color.init(251, 247, 245, 255) else rl.Color.init(159, 221, 67, 255);
                const pos = rl.Vector2.add(self.boardPos, rl.Vector2{ .x = col * cellSize, .y = row * cellSize });
                rl.drawRectangleV(pos, rl.Vector2{ .x = cellSize, .y = cellSize }, color);
            }
        }

        pub fn drawBoard(self: *const Self) void {
            self.updateBitboardPieceArray();
            const cellSize = self.boardSize / 8;
            for (self.bitboard_piece_array) |piece| {
                var bit: u64 = piece.bitboard;
                var curr = 0;
                while (bit != 0) {
                    curr = @ctz(bit) + 1;

                    const row = curr / 8;
                    const col = curr % 8;
                    const origin: rl.Vector2 = rl.Vector2.add(self.boardPos, .init(col * cellSize, row * cellSize));
                    const pieceTexture = PieceTexture.pieceTexFromEnumPiece(self, piece.piece_type);
                    pieceTexture.draw(origin);

                    // remove current bit and from bitboard and trail to next
                }
            }
        }
        fn updateBitboardPieceArray(self: *Self) void {
            const pieces_arr = self.chess.bitboard.pieces_arr;
            for (0..pieces_arr.len) |i| {
                self.bitboard_piece_array[i] = pieces_arr[i];
            }
        }

        const PieceTexture = struct {
            texture: rl.Texture,
            offset: rl.Vector2,
            scale: f32,

            pub fn init(texture: ?rl.Texture) ?PieceTexture {
                if (texture) |_texture| {
                    const widthF = @as(f32, @floatFromInt(_texture.width));
                    const heightF = @as(f32, @floatFromInt(_texture.height));
                    const cellSizeF = @as(f32, @floatFromInt(boardSize / 8));

                    const scale = if (widthF > heightF) 0.8 * cellSizeF / widthF else 0.8 * cellSizeF / heightF;

                    const scaledWidth = widthF * scale;
                    const scaledHeight = heightF * scale;

                    const offset = blk: {
                        const offsetWidth = (cellSizeF - scaledWidth) / 2;
                        const offsetHeight = (cellSizeF - scaledHeight) / 2;
                        const offset = rl.Vector2{ .x = offsetWidth, .y = offsetHeight };
                        break :blk offset;
                    };

                    return PieceTexture{
                        .texture = _texture,
                        .offset = offset,
                        .scale = scale,
                    };
                } else {
                    return null;
                }
            }

            pub fn draw(self: *const PieceTexture, origin: rl.Vector2) void {
                const pos = rl.Vector2.add(origin, self.offset);
                rl.drawTextureEx(self.texture, pos, 0.0, self.scale, .white);
            }

            pub fn pieceTexFromEnumPiece(self: Self, piece: PieceType) PieceTexture {
                switch (piece) {
                    .king => {
                        if (piece.king == .white) {
                            return self.piecesTexture[0];
                        } else {
                            return self.piecesTexture[6];
                        }
                    },
                    .queen => {
                        if (piece.queen == .white) {
                            return self.piecesTexture[1];
                        } else {
                            return self.piecesTexture[7];
                        }
                    },
                    .rook => {
                        if (piece.rook == .white) {
                            return self.piecesTexture[2];
                        } else {
                            return self.piecesTexture[8];
                        }
                    },
                    .bishop => {
                        if (piece.bishop == .white) {
                            return self.piecesTexture[3];
                        } else {
                            return self.piecesTexture[9];
                        }
                    },
                    .knight => {
                        if (piece.knight == .white) {
                            return self.piecesTexture[4];
                        } else {
                            return self.piecesTexture[10];
                        }
                    },
                    .pawn => {
                        if (piece.pawn == .white) {
                            return self.piecesTexture[5];
                        } else {
                            return self.piecesTexture[11];
                        }
                    },
                }
            }
        };
    };
}

test {
    const screenWidth = 1680;
    const screenHeight = 1320;
    //
    // rl.initWindow(screenWidth, screenHeight, "Chess");
    // defer rl.closeWindow();
    // rl.setTargetFPS(60);

    const chessType = try ChessBoard(screenWidth, screenHeight);
    const chessVar = try chessType.init();
    defer chessVar.deinit();
}
