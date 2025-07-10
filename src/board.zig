const rl = @import("raylib");
const chessRules = @import("chess.zig");

const PADDING: u32 = 80;

pub fn ChessBoard(screenWidth: u32, screenHeight: u32) anyerror!type {
    const BOARD_SIZE = 8;

    const WVH: bool = if (screenWidth > screenHeight) true;

    const boardSize = if (WVH) screenHeight - PADDING else screenWidth - PADDING;

    return struct {
        boardSize: u32,
        boardPos: rl.Vector2,
        cellGrid: CellGrid,
        pieces: [12]PieceTexture,
        chess: chessRules.Chess(BOARD_SIZE),

        const Self = @This();

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

            const chess = chessRules.Chess(BOARD_SIZE).initBase();
            const cellGrid = CellGrid.init(boardPos, &chess, pieces);

            return Self{
                .boardSize = boardSize,
                .boardPos = boardPos,
                .cellGrid = cellGrid,
                .pieces = pieces,
                .chess = chess,
            };
        }

        pub fn deinit(self: Self) void {
            for (self.pieces) |piece| {
                rl.unloadTexture(piece.texture);
            }
        }

        pub fn drawBoard(self: *const Self) void {
            for (0..BOARD_SIZE) |i| {
                for (0..BOARD_SIZE) |j| {
                    self.cellGrid.cellGrid[i][j].draw();
                }
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
                    const cellSizeF = @as(f32, @floatFromInt(boardSize / BOARD_SIZE));

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

            pub fn pieceTexFromEnumPiece(pieces: [12]PieceTexture, piece: chessRules.Chess(BOARD_SIZE).Pieces) ?PieceTexture {
                switch (piece) {
                    .king => {
                        if (piece.king.color == .white) {
                            return pieces[0];
                        } else {
                            return pieces[6];
                        }
                    },
                    .queen => {
                        if (piece.queen == .white) {
                            return pieces[1];
                        } else {
                            return pieces[7];
                        }
                    },
                    .rook => {
                        if (piece.rook == .white) {
                            return pieces[2];
                        } else {
                            return pieces[8];
                        }
                    },
                    .bishop => {
                        if (piece.bishop == .white) {
                            return pieces[3];
                        } else {
                            return pieces[9];
                        }
                    },
                    .knight => {
                        if (piece.knight == .white) {
                            return pieces[4];
                        } else {
                            return pieces[10];
                        }
                    },
                    .pawn => {
                        if (piece.pawn.color == .white) {
                            return pieces[5];
                        } else {
                            return pieces[11];
                        }
                    },
                    .none => return null,
                }
            }
        };

        const CellGrid = struct {
            cellGrid: [BOARD_SIZE][BOARD_SIZE]Cell,

            pub fn init(boardPos: rl.Vector2, board: *const chessRules.Chess(BOARD_SIZE), pieceTexArr: [12]PieceTexture) CellGrid {
                const cellSize = boardSize / BOARD_SIZE;
                const cellGrid = blk: {
                    var cellGrid: [BOARD_SIZE][BOARD_SIZE]Cell = undefined;
                    for (0..BOARD_SIZE) |i| {
                        for (0..BOARD_SIZE) |j| {
                            const pieceEnum = board.board[i][j];

                            const pieceTex = PieceTexture.pieceTexFromEnumPiece(pieceTexArr, pieceEnum);

                            const pos = rl.Vector2.add(boardPos, rl.Vector2{
                                .x = @as(f32, @floatFromInt(cellSize * i)),
                                .y = @as(f32, @floatFromInt(cellSize * j)),
                            });

                            const cellColor = blk2: {
                                var cellColor: rl.Color = undefined;

                                if (i % 2 == 0) {
                                    if (j % 2 == 0) {
                                        cellColor = rl.Color.dark_green;
                                    } else {
                                        cellColor = rl.Color.white;
                                    }
                                } else {
                                    if (j % 2 == 0) {
                                        cellColor = rl.Color.white;
                                    } else {
                                        cellColor = rl.Color.dark_green;
                                    }
                                }
                                break :blk2 cellColor;
                            };

                            cellGrid[i][j] = Cell.init(pieceTex, pieceEnum, pos, cellColor);
                        }
                    }
                    break :blk cellGrid;
                };

                return CellGrid{
                    .cellGrid = cellGrid,
                };
            }
        };

        const Cell = struct {
            pieceTex: ?PieceTexture,
            piece: chessRules.Chess(BOARD_SIZE).Pieces,
            pos: rl.Vector2,
            color: rl.Color,

            pub fn init(pieceTex: ?PieceTexture, piece: chessRules.Chess(BOARD_SIZE).Pieces, pos: rl.Vector2, color: rl.Color) Cell {
                return Cell{
                    .pieceTex = pieceTex,
                    .piece = piece,
                    .pos = pos,
                    .color = color,
                };
            }
            pub fn draw(self: *const Cell) void {
                const cellSize = boardSize / BOARD_SIZE;
                if (self.pieceTex) |pieceTex| {
                    rl.drawRectangleV(self.pos, rl.Vector2.init(cellSize, cellSize), self.color);
                    pieceTex.draw(self.pos);
                } else {
                    rl.drawRectangleV(self.pos, rl.Vector2.init(cellSize, cellSize), self.color);
                }
            }
        };
    };
}

test {
    const screenWidth = 1680;
    const screenHeight = 1320;

    rl.initWindow(screenWidth, screenHeight, "Chess");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    const chessType = try ChessBoard(screenWidth, screenHeight);
    const chessVar = try chessType.init();
    defer chessVar.deinit();
}
