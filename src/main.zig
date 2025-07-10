const rl = @import("raylib");
const chessBoard = @import("board.zig");

pub fn main() anyerror!void {
    rl.initWindow(1600, 800, "chess");
    defer rl.closeWindow();

    const screenWidth = 1640;
    const screenHeight = 840;

    const chessType = try chessBoard.ChessBoard(screenWidth, screenHeight);
    const chessVar = try chessType.init();
    defer chessVar.deinit();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();

        chessVar.drawBoard();

        defer rl.endDrawing();

        rl.clearBackground(rl.Color.init(97, 95, 91, 255));
    }
}
