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
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)

        UndoableString.pushBlockUndoInfo(from: t, to: extUm)

        XCTAssertTrue(extUm.canUndo,
                      "After the edit block undo information has been restored the external UM indicates it can Undo")
        XCTAssertFalse(extUm.canRedo,
                       "But cannot Redo")

        extUm.undo()
        XCTAssertEqual(t.text, textInitial,
                       "And after triggering the external UM's undo method ")
        XCTAssertFalse(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)
        XCTAssertFalse(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        extUm.redo()
        XCTAssertEqual(t.text, textChange1,
                       "And after triggering the external UM's redo method ")
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)
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
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)

        // Make 2nd change and make undoable via the external UM
        print("\n####### Checkpoint 2 - from 1st => 2nd change")
        let textChange2 = "2nd changed text"
        t.text = textChange2
        UndoableString.saveBlockUndoInfo(to: t, extUndoMgr: nil)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)

        // Make 3rd change and make undoable via the external UM
        print("\n####### Checkpoint 3 - from 2nd => 3rd change")
        let textChange3 = "3rd changed text"
        t.text = textChange3
        UndoableString.saveBlockUndoInfo(to: t, extUndoMgr: nil)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)

        print("#")
        print("#   Push undoable's undo stack onto an external UndoManager ")
        print("#")
        UndoableString.pushBlockUndoInfo(from: t, to: extUm)

        // Check the undoManagers are in agreeement
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)
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
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        // Undo and check reversion of the 2nd change to the 1st

        print("\n####### 2nd Undo from change 2 => 1 ")
        extUm.undo()
        XCTAssertEqual(t.text, textChange1,
                       "And after triggering the external UM's Undo method ")
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        if jiggle {
            // Check a mid-stack redo and undo jiggle to make sure stay in alignment
            // ---- Redo first
            print("\n#######  Jiggle - Redo from change 1 => 2 ")
            extUm.redo()
            XCTAssertEqual(t.text, textChange2)
            XCTAssertTrue(t.passThroughTgtUm.canUndo)
            XCTAssertTrue(t.passThroughTgtUm.canRedo)
            XCTAssertTrue(extUm.canUndo)
            XCTAssertTrue(extUm.canRedo)

            // --- Then Undo the Redo
            print("#######  Jiggle - Undo from change 2 => 1 ")
            extUm.undo()
            XCTAssertEqual(t.text, textChange1)
            XCTAssertTrue(t.passThroughTgtUm.canUndo)
            XCTAssertTrue(t.passThroughTgtUm.canRedo)
            XCTAssertTrue(extUm.canUndo)
            XCTAssertTrue(extUm.canRedo)
        }

        // Undo and check reversion of the 1st change to the initial state

        print("\n#######  Undo from change 1 => Initial ")
        extUm.undo()
        XCTAssertEqual(t.text, textInitial,
                       "And after triggering the external UM's undo method ")
        XCTAssertFalse(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)
        XCTAssertFalse(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        // Now walk back up the Redo stack as final check on things getting out of sync
        print("#")
        print("#   About to walk back up the undo stack ")
        print("#")
        print("\n#######  Redo from change Initial => change 1 ")
        extUm.redo()
        XCTAssertEqual(t.text, textChange1)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        print("\n#######  Redo from change change 1 => change 2 ")
        extUm.redo()
        XCTAssertEqual(t.text, textChange2)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertTrue(extUm.canRedo)

        print("\n#######  Redo from change change 2 => change 3 ")
        extUm.redo()
        XCTAssertEqual(t.text, textChange3)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)
        XCTAssertTrue(extUm.canUndo)
        XCTAssertFalse(extUm.canRedo)
    }

    func test_multipleUndoableOperationsIntegrationWithExternalUndoManager_NoJiggle() throws {
        try __test_multipleUndoableOperationsIntegrationWithExternalUndoManager(jiggle: false)
    }

    func test_multipleUndoableOperationsIntegrationWithExternalUndoManager_WithJiggle() throws {
        try __test_multipleUndoableOperationsIntegrationWithExternalUndoManager(jiggle: true)
    }

    func test_timerTriggerCheckpointingDoesNotHappenBelowHoldOffPeriod() throws {
        let extUm = UndoManager()

        let holdOffTimeBeforeCheckpointing: Double = 2
        let timeBetweenChanges: Double = holdOffTimeBeforeCheckpointing - 1

        let textInitial = "Original text"
        let t = UndoableString(text: textInitial, checkpointAfter: holdOffTimeBeforeCheckpointing, withActionName: "Timer checkpointed changes")

        // Make change 1
        nonBlockingSleep(forAtLeast: timeBetweenChanges)
        t.text = textInitial + " and"

        // Make change 2
        nonBlockingSleep(forAtLeast: timeBetweenChanges)
        t.text = t.text + " some"

        // Make change 3
        nonBlockingSleep(forAtLeast: timeBetweenChanges)
        t.text = t.text + " other stuff"

        // Force a manual checkpoint to simulate a moving focus somewhere else
        nonBlockingSleep(forAtLeast: timeBetweenChanges)
        t.makeTextUndoableToNewCheckpoint(withActionName: "Typing changes")

        /// Simulate shifting focus elsewhere
        UndoableString.saveBlockUndoInfo(to: t, extUndoMgr: nil)

        XCTAssertNotEqual(t.text, textInitial)

        // Verify that because none of the time gaps between the changes exceeded the holdOff time all the changes
        // undo in a single go

        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textInitial)

        XCTAssertFalse(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)
    }

    func nonBlockingSleep(forAtLeast seconds: Double) {
        /// Using sleep doesn't work as it blocks the thread that the Timer runs on.
        /// https://stackoverflow.com/questions/59321364/swift-unit-testing-a-method-that-includes-timer
        ///
        let expectation = self.expectation(description: #function)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: seconds + 1)
    }

    func test_timerTriggerCheckpointingHappensWhenTheHoldOffTimeBetweenChangesIsExceeded() throws {
        let holdOffTimeBeforeCheckpointing: Double = 1
        let timeBetweenChanges: Double = holdOffTimeBeforeCheckpointing + 1 // NB: "+ 1"

        let textInitial = "zero"
        let t = UndoableString(text: textInitial, checkpointAfter: holdOffTimeBeforeCheckpointing, withActionName: "Timer checkpointed changes")

        // Make change 1
        print("Making change 1")
        let textChange1 = t.text + " one"
        t.text = textChange1
        nonBlockingSleep(forAtLeast: timeBetweenChanges)

        print("Making change 2")
        let textChange2 = t.text + " two"
        t.text = textChange2
        nonBlockingSleep(forAtLeast: timeBetweenChanges)

        print("Making change 3")
        let textChange3 = t.text + " three"
        t.text = textChange3
        nonBlockingSleep(forAtLeast: timeBetweenChanges)

        // Change 4 but without enough time for the timer to fire => check we catch anything else left over
        print("Making change 4 but not leaving time for timer to expire")
        let textChange4 = t.text + " & four"
        t.text = textChange4

        // Simulate a moving focus somewhere else
        print("Simulating moving focus away")
        UndoableString.saveBlockUndoInfo(to: t, extUndoMgr: nil)

        XCTAssertNotEqual(t.text, textInitial)

        // Verify that because all of the time gaps between changes exceeded the holdOff time each of them has been checkpointed
        // by the UndoableString's timer checkpointing mechanism.

        print("About to undo change 4")
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textChange3)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)

        // See if we can upset things with a redo jiggle
        print("Jiggling - redo change 4")
        nonBlockingSleep(forAtLeast: timeBetweenChanges)
        t.passThroughTgtUm.redo()
        XCTAssertEqual(t.text, textChange4)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)
        nonBlockingSleep(forAtLeast: timeBetweenChanges)

        print("Jiggling - undo change 4")
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textChange3)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)
        nonBlockingSleep(forAtLeast: timeBetweenChanges)

        // Undo change 3
        print("Undo change 3")
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textChange2)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)

        // Undo change 2
        print("Undo change 2")
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textChange1)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)

        // Undo change 1
        print("Undo change 1")
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textInitial)
        XCTAssertFalse(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)
    }
}
