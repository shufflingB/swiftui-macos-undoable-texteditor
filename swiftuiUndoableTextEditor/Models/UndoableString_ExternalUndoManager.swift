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
            if let t = uString.holdOffTimer  {
                t.invalidate()
            }
            
            if uString.timerTriggeredUm.canUndo {
                let textPreReplay = uString.text  /// Need this bc unwinding we loose it otherwise with rewinding and replaying
                
                /// Rewind the undo's
                uString.internalOriginChange = false
                //print("Rewinding timerTriggeredUm")
                while uString.timerTriggeredUm.canUndo { uString.timerTriggeredUm.undo() }
                
                //print("Redooing from timerTriggeredUm to passThroughTgtUm")
                /// Replay the redo's and push the changes onto the pass-throuh undoManager
                //print("Text at start = \(uString.text), last checkpointed = \(uString.textLastCheckpointed)")
                while uString.timerTriggeredUm.canRedo {
                    //print("===================================")
                    //print("Text Before REDO = \(uString.text),  last checkpointed = \(uString.textLastCheckpointed)\n")
                    uString.timerTriggeredUm.redo()
                    //print("Text After REDO = \(uString.text),  last checkpointed = \(uString.textLastCheckpointed)\n")
                    uString.makeTextUndoableToNewCheckpoint(withActionName: "Block")
                    //print("-----------------")
                }
                
                uString.timerTriggeredUm.removeAllActions()
                
                uString.textLastCheckpointedUpdate(uString.text)
                //print("Updated last checkpoint = \(uString.textLastCheckpointed)")
                uString.text = textPreReplay
                uString.internalOriginChange = false
            }
            
            
            if uString.hasUnCheckpointedChanges == true {
                print("saveBlockUndoInfo: has user changes since last checkpoint to save")
                uString.makeTextUndoableToNewCheckpoint(withActionName: "Block")
            } else if extUndoMgr?.canRedo == true {
                print("saveBlockUndoInfo: Last focusedUString can redo but stuffed if know how to figure out the redo")
            } else {
                print("saveBlockUndoInfo: Last focusedUString text had no additional changes in this edit block to save, no undo information to store")
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

        if uString.passThroughTgtUm.canUndo {
            print("\npushBlockUndoInfo: About to rewind all undo's")
            uString.textRewindUndo()

            var count = 0
            print("\npushBlockUndoInfo: About to replay the redo's to load up the external UndoManager's undo stack")
            let originalGroupsByEvent = extUndoMgr?.groupsByEvent ?? true // True is the default value
            extUndoMgr?.groupsByEvent = false
            uString.textReplayRedo { _ in
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
                tt.passThroughTgtUm.undo()
                registerPassThroughRevert(from: extUndoMgr, to: tt, setActionName: actionName, opType: .redo)
            } else {
                tt.passThroughTgtUm.redo()
                registerPassThroughRevert(from: extUndoMgr, to: tt, setActionName: actionName, opType: .undo)
            }
        }
        extUndoMgr?.setActionName(actionName)
        extUndoMgr?.endUndoGrouping()
    }
}
