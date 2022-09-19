//
//  UndoableString_UndoManager.swift
//  UnitTests
//
//  Created by Jonathan Hume on 16/09/2022.
//
@testable import swiftuiUndoableTextEditor
import XCTest

final class UndoableStringWithExternalUndoManager: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_undoIntegrationWithExternalUndoManager() throws {
        let extUm = UndoManager()

        let textInitial = "Original text"
        let t = UndoableString(text: textInitial)

        let textChange1 = "First changed text"
        t.text = textChange1

        UndoableString.saveBlockUndoInfo(to: t, extUndoMgr: nil)
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertFalse(t.undoManager.canRedo)

        UndoableString.pushBlockUndoInfo(from: t, to: extUm)

        XCTAssertTrue(extUm.canUndo,
                      "After the edit block undo information has been restored the external UM indicates it can Undo")
        XCTAssertFalse(extUm.canRedo,
                       "But cannot Redo")

        extUm.undo()
        XCTAssertEqual(t.text, textInitial,
                       "And after triggering the external UM's undo method ")
        XCTAssertFalse(t.undoManager.canUndo)
        XCTAssertTrue(t.undoManager.canRedo)
        XCTAssertFalse(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        extUm.redo()
        XCTAssertEqual(t.text, textChange1,
                       "And after triggering the external UM's redo method ")
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertFalse(t.undoManager.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertFalse(extUm.canRedo)
    }

    func __test_multipleUndoableOperationsIntegrationWithExternalUndoManager(jiggle: Bool = false) throws {
        let extUm = UndoManager()

        let textInitial = "Original text"
        let t = UndoableString(text: textInitial)
        print("#")
        print("#   Simulating series of externally triggered checkpoint captures")
        print("#")

        // Make 1st change and make undoable via the external UM
        print("\n####### Checkpoint 1 - from original => 1st change")
        let textChange1 = "1st changed text"
        t.text = textChange1
        UndoableString.saveBlockUndoInfo(to: t, extUndoMgr: nil)
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertFalse(t.undoManager.canRedo)

        // Make 2nd change and make undoable via the external UM
        print("\n####### Checkpoint 2 - from 1st => 2nd change")
        let textChange2 = "2nd changed text"
        t.text = textChange2
        UndoableString.saveBlockUndoInfo(to: t, extUndoMgr: nil)
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertFalse(t.undoManager.canRedo)

        // Make 3rd change and make undoable via the external UM
        print("\n####### Checkpoint 3 - from 2nd => 3rd change")
        let textChange3 = "3rd changed text"
        t.text = textChange3
        UndoableString.saveBlockUndoInfo(to: t, extUndoMgr: nil)
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertFalse(t.undoManager.canRedo)

        print("#")
        print("#   Push undoable's undo stack onto an external UndoManager ")
        print("#")
        UndoableString.pushBlockUndoInfo(from: t, to: extUm)

        // Check the undoManagers are in agreeement
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertFalse(t.undoManager.canRedo)
        XCTAssertTrue(extUm.canUndo,
                      "After the edit block undo information has been restored the  external UM indicates it can Undo")
        XCTAssertFalse(extUm.canRedo, "But cannot Redo")

//        let jiggle = false
        print("#")
        print("#   About to undo changes with redo jiggle = \(jiggle) in the middle ")
        print("#")
        // Undo and check reversion of the last/3rd change to the 2nd change
        print("\n####### 1st Undo from change 3 => 2 ")
        extUm.undo()
        XCTAssertEqual(t.text, textChange2,
                       "And after triggering the external UM's undo method ")
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertTrue(t.undoManager.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        // Undo and check reversion of the 2nd change to the 1st

        print("\n####### 2nd Undo from change 2 => 1 ")
        extUm.undo()
        XCTAssertEqual(t.text, textChange1,
                       "And after triggering the external UM's Undo method ")
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertTrue(t.undoManager.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        if jiggle {
            // Check a mid-stack redo and undo jiggle to make sure stay in alignment
            // ---- Redo first
            print("\n#######  Jiggle - Redo from change 1 => 2 ")
            extUm.redo()
            XCTAssertEqual(t.text, textChange2)
            XCTAssertTrue(t.undoManager.canUndo)
            XCTAssertTrue(t.undoManager.canRedo)
            XCTAssertTrue(extUm.canUndo)
            XCTAssertTrue(extUm.canRedo)

            // --- Then Undo the Redo
            print("#######  Jiggle - Undo from change 2 => 1 ")
            extUm.undo()
            XCTAssertEqual(t.text, textChange1)
            XCTAssertTrue(t.undoManager.canUndo)
            XCTAssertTrue(t.undoManager.canRedo)
            XCTAssertTrue(extUm.canUndo)
            XCTAssertTrue(extUm.canRedo)
        }

        // Undo and check reversion of the 1st change to the initial state

        print("\n#######  Undo from change 1 => Initial ")
        extUm.undo()
        XCTAssertEqual(t.text, textInitial,
                       "And after triggering the external UM's undo method ")
        XCTAssertFalse(t.undoManager.canUndo)
        XCTAssertTrue(t.undoManager.canRedo)
        XCTAssertFalse(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        // Now walk back up the Redo stack as final check on things getting out of sync
        print("#")
        print("#   About to walk back up the undo stack ")
        print("#")
        print("\n#######  Redo from change Initial => change 1 ")
        extUm.redo()
        XCTAssertEqual(t.text, textChange1)
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertTrue(t.undoManager.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        print("\n#######  Redo from change change 1 => change 2 ")
        extUm.redo()
        XCTAssertEqual(t.text, textChange2)
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertTrue(t.undoManager.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        print("\n#######  Redo from change change 2 => change 3 ")
        extUm.redo()
        XCTAssertEqual(t.text, textChange3)
        XCTAssertTrue(t.undoManager.canUndo)
        XCTAssertFalse(t.undoManager.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertFalse(extUm.canRedo)
    }

    func test_multipleUndoableOperationsIntegrationWithExternalUndoManager_NoJiggle() throws {
        try __test_multipleUndoableOperationsIntegrationWithExternalUndoManager(jiggle: false)
    }

    func test_multipleUndoableOperationsIntegrationWithExternalUndoManager_WithJiggle() throws {
        try __test_multipleUndoableOperationsIntegrationWithExternalUndoManager(jiggle: true)
    }
}
