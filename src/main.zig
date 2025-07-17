const rl = @import("raylib");
const chessBoard = @import("board.zig");
const std = @import("std");

pub fn main() anyerror!void {
    const screenWidth = 1640;
    const screenHeight = 840;

    rl.initWindow(screenWidth, screenHeight, "chess");
    defer rl.closeWindow();

    const chessType = try chessBoard.ChessBoard(screenWidth, screenHeight);
    var chessVar = try chessType.init();
    defer chessVar.deinit();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();

        chessVar.drawEmptyBoard();
        chessVar.drawBoard();
        try chessVar.player.attackPiece(&chessVar);

        defer rl.endDrawing();

        rl.clearBackground(rl.Color.init(97, 95, 91, 255));
    }
}
