import AppKit
import CorkCore
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var boardStore: BoardStore

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        self.boardStore = coordinator.boardStore
    }

    var body: some View {
        Button(coordinator.isBoardVisible ? "Hide Cork" : "Show Cork") {
            coordinator.toggleBoard()
        }
        .keyboardShortcut("b", modifiers: [.command, .option])

        Divider()

        ForEach(boardStore.boards) { board in
            Button {
                boardStore.selectBoard(board.id)
                coordinator.showBoard()
            } label: {
                if board.id == boardStore.selectedBoardID {
                    Label(board.name, systemImage: "checkmark")
                } else {
                    Text(board.name)
                }
            }
        }

        Divider()

        Button("Quit Cork") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
