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
            // Punch a watchdog timer that when it expires triggers saving a checkpoint save
            /// If don't have timer stashing checkpoints then if/when the checkpoint is saved by an external trigger that actual block that is
            /// undoable could be very large an not very user friendly i.e. they could have entered loads, and their only undo choice could end up being
            /// revert or keep the lot.
            // print("Text getting set to newValue \(newValue)")
            guard let holdOffActionName = holdOffActionName, internalOriginChange == false else {
                return
            }
            
            if let holdOffTimer = holdOffTimer {
                holdOffTimer.invalidate()
            }
            holdOffTimer = Timer.scheduledTimer(withTimeInterval: holdOff , repeats: false) { _ in
                print("Timer based undoable checkpoint triggered")
                
                Self.makeTextUndoable(
                    toLastCheckpoint: self.textLastCheckpointed,
                    fromCurrent: self.text,
                    withUString: self,
                    usingUndoManager: self.timerTriggeredUm,
                    settingActionName: holdOffActionName,
                    opType: .undo,
                    updateLastCheckPoint: false
                )
            }
        }
    }

    let id = UUID()
    let passThroughTgtUm = UndoManager()
    internal var textLastCheckpointed: String
    
    private let holdOff: Double
    internal let timerTriggeredUm = UndoManager()
    internal var holdOffTimer: Timer?
    private let holdOffActionName: String?
    internal var internalOriginChange: Bool = false
    

    init(text: String, checkpointAfter: Double = 3, withActionName: String? = nil ) {
        _text = Published(initialValue: text)
        textLastCheckpointed = text
        /// Without the default groupsByEvent == true , end up with multiple undo's  getting undone the first time undo is used, i.e. it handles all of the registerUndo as if they were
        /// just a single one.
        /// https://stackoverflow.com/questions/47988403/how-will-undomanager-run-loop-grouping-be-affected-in-different-threading-contex
        passThroughTgtUm.groupsByEvent = false
        timerTriggeredUm.groupsByEvent = false
        self.holdOff = checkpointAfter
        self.holdOffActionName = withActionName
    }

    var hasUnCheckpointedChanges: Bool {
        text != textLastCheckpointed
    }

    func textLastCheckpointedUpdate(_ newValue: String) {
        textLastCheckpointed = text
    }

    func textUpdate(_ newValue: String) {
        internalOriginChange = true
        text = newValue
        internalOriginChange = false
    }

    func textRewindUndo() {
        internalOriginChange = true
        while passThroughTgtUm.canUndo {
            passThroughTgtUm.undo()
        }
        internalOriginChange = false
    }

    func textReplayRedo(perform: (_ redoneText: String) -> Void) {
        internalOriginChange = true
        while passThroughTgtUm.canRedo {
            passThroughTgtUm.redo()
            perform(text)
        }
        internalOriginChange = false
    }

    func makeTextUndoableToNewCheckpoint(withActionName: String) {
        Self.makeTextUndoable(
            toLastCheckpoint: textLastCheckpointed,
            fromCurrent: text,
            withUString: self,
            usingUndoManager: self.passThroughTgtUm,
            settingActionName: withActionName,
            opType: .undo,
            updateLastCheckPoint: true
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
        usingUndoManager undoManager: UndoManager,
        settingActionName actionName: String,
        opType: RevertType,
        updateLastCheckPoint: Bool
    ) {
        guard text != textLastCheckpoint else {
            print("makeTextUndoable: No changes to register how to undo to last checkpointed baseline value")
            return
        }

        /// Register the undo;
        print("makeTextUndoable: Registering \(opType) for current text '\(text)' to last checkpointed text '\(textLastCheckpoint)'")
        undoManager.beginUndoGrouping()
        undoManager.registerUndo(withTarget: uString) { tt in
            print("UndoableString#UndoManager: running \(opType) closure from makeTextUndoable. Will revert text from  '\(text)' to '\(textLastCheckpoint)'")
            tt.textUpdate(textLastCheckpoint)
            makeTextUndoable(
                toLastCheckpoint: text, // <-- this and next swap position for Redo
                fromCurrent: textLastCheckpoint,
                withUString: tt,
                usingUndoManager: undoManager,
                settingActionName: actionName,
                opType: opType == .undo ? .redo : .undo,
                updateLastCheckPoint: updateLastCheckPoint
            )
        }
        undoManager.setActionName(actionName)
        undoManager.endUndoGrouping()
        
        if updateLastCheckPoint {
            uString.textLastCheckpointedUpdate(text)
        }
    }
}
