//
//  UndoableString_ExternalUndoManager.swift
//  swiftuiUndoableTextEditor
//
//  Created by Jonathan Hume on 19/09/2022.
//
import SwiftUI

extension UndoableString {
    static func onFocusChanged(saveUndoInfoFor lastFocused: UndoableString?, restoreUndoInfoFor newFocused: UndoableString?, updatingSuiUm suiUm: UndoManager?) {
        Self.saveBlockUndoInfo(to: lastFocused, extUndoMgr: suiUm)

        Self.pushBlockUndoInfo(from: newFocused, to: suiUm)
    }

    static func saveBlockUndoInfo(to uString: UndoableString?, extUndoMgr: UndoManager?) {
        if let uString: UndoableString = uString // Did have focus => do we have to work with?
        {
            if uString.hasUnCheckpointedChanges == true {
                print("saveBlockUndoInfo: has user changes since last checkpoint to save")
                uString.makeTextUndoableToNewCheckpoint(withActionName: "Block")
            } else if extUndoMgr?.canRedo == true {
                print("saveBlockUndoInfo: Last focusedUString can redo but stuffed if know how to figure out the redo")
            } else {
                print("saveBlockUndoInfo: Last focusedUString text had no changes in this edit block, no undo information to store")
            }

        } else {
            /// Wasn't previously a focused item so nothing needs to be done in terms of storing how to undo any changes
            print("saveBlockUndoInfo: Last focusedUString, not undoable so nothing store for it")
        }
    }

    static func pushBlockUndoInfo(from uString: UndoableString?, to extUndoMgr: UndoManager?) {
        guard let uString: UndoableString = uString else {
            print("pushBlockUndoInfo: Undoable is nil, so nothing to push onto the external UndoManager")
            return
        }

        extUndoMgr?.removeAllActions()

        if uString.undoManager.canUndo {
            print("\npushBlockUndoInfo: About to rewind all undo's")
            uString.textRewindAllUndo()

            var count = 0
            print("\npushBlockUndoInfo: About to replay the redo's to load up the external UndoManager's undo stack")
            let originalGroupsByEvent = extUndoMgr?.groupsByEvent ?? true // True is the default value
            extUndoMgr?.groupsByEvent = false
            uString.textReplayAllRedo { _ in
                count += 1
                print("restoreBlockUndoInfo: replaying, redo \(count) registering pass-through undo and redo")
                Self.registerPassThroughRevert(from: extUndoMgr, to: uString, setActionName: "Block", opType: .undo)
            }
            extUndoMgr?.groupsByEvent = originalGroupsByEvent
        } else {
            print("pushBlockUndoInfo: New newFocusedUString has no undo registered for restoration")
        }
    }

    static func registerPassThroughRevert(
        from extUndoMgr: UndoManager?,
        to target: UndoableString,
        setActionName actionName: String,
        opType: RevertType
    ) {
        print("registerPassThroughRevert: \(opType) from the external UndoManager to the UndoableString#UndoManager")
        extUndoMgr?.beginUndoGrouping()
        extUndoMgr?.registerUndo(withTarget: target) { (tt: UndoableString) in
            print("external UndoManager running \(opType) pass-through closure from registerPassThroughRevert")
            if opType == .undo {
                tt.undoManager.undo()
                registerPassThroughRevert(from: extUndoMgr, to: tt, setActionName: actionName, opType: .redo)
            } else {
                tt.undoManager.redo()
                registerPassThroughRevert(from: extUndoMgr, to: tt, setActionName: actionName, opType: .undo)
            }
        }
        extUndoMgr?.setActionName(actionName)
        extUndoMgr?.endUndoGrouping()
    }
}
