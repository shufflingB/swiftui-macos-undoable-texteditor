//
//  UndoableString.swift
//  mockCodeUITests
//
//  Created by Jonathan Hume on 11/09/2022.
//

import SwiftUI
class UndoableString: ObservableObject, Identifiable, Equatable {
    static func == (lhs: UndoableString, rhs: UndoableString) -> Bool {
        lhs.id == rhs.id
    }

    @Published var text: String {
        willSet {
            // TODO: Add punching watchdog timer that when it expires triggers saving a checkpoint save
            /// If don't have timer stashing checkpoints then if/when the checkpoint is saved by an external trigger that actual block that is
            /// undoable could be very large an not very user friendly i.e. they could have entered loads, and their only undo choice could end up being
            /// revert or keep the lot.
            // print("Text getting set to newValue \(newValue)")
        }
    }

    let id = UUID()
    let undoManager = UndoManager()
    private var textLastCheckpointed: String

    init(text: String) {
        _text = Published(initialValue: text)
        textLastCheckpointed = text
        /// Without the default groupsByEvent == true , end up with multiple undo's  getting undone the first time undo is used, i.e. it handles all of the registerUndo as if they were
        /// just a single one.
        /// https://stackoverflow.com/questions/47988403/how-will-undomanager-run-loop-grouping-be-affected-in-different-threading-contex
        undoManager.groupsByEvent = false
    }

    var hasUnCheckpointedChanges: Bool {
        text != textLastCheckpointed
    }

    func textLastCheckpointedUpdate(_ newValue: String) {
        textLastCheckpointed = text
    }

    func textUpdate(_ newValue: String) {
        text = newValue
    }

    func textRewindAllUndo() {
        while undoManager.canUndo {
            undoManager.undo()
        }
    }

    func textReplayAllRedo(perform: (_ redoneText: String) -> Void) {
        while undoManager.canRedo {
            undoManager.redo()
            perform(text)
        }
    }

    func makeTextUndoableToNewCheckpoint(withActionName: String) {
        Self.makeTextUndoable(
            toLastCheckpoint: textLastCheckpointed,
            fromCurrent: text,
            withUString: self,
            settingUm: withActionName,
            opType: .undo
        )
    }

    enum RevertType {
        case undo, redo
    }

    /// Not really necessary, but putting into a static function makes reasoning about the process a bit easier.
    static func makeTextUndoable(
        toLastCheckpoint textLastCheckpoint: String,
        fromCurrent text: String,
        withUString uString: UndoableString,
        settingUm actionName: String,
        opType: RevertType
    ) {
        guard text != textLastCheckpoint else {
            print("makeTextUndoable: No changes to register how to undo to last checkpointed baseline value")
            return
        }

        /// Register the undo;
        print("makeTextUndoable: Registering \(opType) for current text '\(text)' to last checkpointed text '\(textLastCheckpoint)'")
        uString.undoManager.beginUndoGrouping()
        uString.undoManager.registerUndo(withTarget: uString) { tt in
            print("UndoableString#UndoManager: running \(opType) closure from makeTextUndoable. Will revert text from  '\(text)' to '\(textLastCheckpoint)'")
            tt.textUpdate(textLastCheckpoint)
            makeTextUndoable(
                toLastCheckpoint: text, // <-- this and next swap position for Redo
                fromCurrent: textLastCheckpoint,
                withUString: tt,
                settingUm: actionName,
                opType: opType == .undo ? .redo : .undo
            )
        }
        uString.undoManager.setActionName(actionName)
        uString.undoManager.endUndoGrouping()
        uString.textLastCheckpointedUpdate(text)
    }
}

