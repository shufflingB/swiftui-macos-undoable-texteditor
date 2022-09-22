//
//  mockCodeUnitTests.swift
//  mockCodeUnitTests
//
//  Created by Jonathan Hume on 11/09/2022.
//
@testable import swiftuiUndoableTextEditor
import XCTest

class UndoableStringUnitTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_detectChanges() throws {
        let t = UndoableString(text: "Lorem")
        XCTAssertFalse(t.hasUnCheckpointedChanges)
        t.text = "Changed"
        XCTAssertTrue(t.hasUnCheckpointedChanges)
    }

    func test_noUndoUntilRegisterUndo() throws {
        let t = UndoableString(text: "Lorem")
        XCTAssertFalse(t.hasUnCheckpointedChanges)
        t.text = "Changed"
        XCTAssertTrue(t.hasUnCheckpointedChanges)
        XCTAssertFalse(t.passThroughTgtUm.canUndo)
    }

    func test_undoes() throws {
        let textInitial = "Lorem"
        let t = UndoableString(text: textInitial)

        t.text = "Changed"

        t.makeTextUndoableToNewCheckpoint(withActionName: "Typing")
        XCTAssertTrue(t.passThroughTgtUm.canUndo)

        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textInitial)
        XCTAssertFalse(t.passThroughTgtUm.canUndo)
    }

    func test_resetToBaselineAndReplay() throws {
        let textInitial = "Initial"
        let t = UndoableString(text: textInitial)

        t.text = "Change1"
        t.makeTextUndoableToNewCheckpoint(withActionName: "Action name 1")
        XCTAssertTrue(t.passThroughTgtUm.canUndo)

        t.text = "Change2"
        t.makeTextUndoableToNewCheckpoint(withActionName: "Action name 2")
        XCTAssertTrue(t.passThroughTgtUm.canUndo)

        let textFinal = "Change3"
        t.text = textFinal
        t.makeTextUndoableToNewCheckpoint(withActionName: "Action name 3")
        XCTAssertTrue(t.passThroughTgtUm.canUndo)

        t.textRewindUndo()
        XCTAssertEqual(t.text, textInitial)
        XCTAssertFalse(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)

        var lastCheck: String = ""
        var count = 0
        let extpectedCount = 3
        t.textReplayRedo(perform: { redoneStr in
            lastCheck = redoneStr
            count += 1

        })
        XCTAssertEqual(t.text, textFinal)
        XCTAssertEqual(lastCheck, textFinal)
        XCTAssertEqual(count, extpectedCount)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)
    }

    func test_redoes() throws {
        let textInitial = "Lorem"
        let t = UndoableString(text: textInitial)

        t.text = "Changed"
        let textChanged = t.text

        t.makeTextUndoableToNewCheckpoint(withActionName: "Typing")

        // 1st Undo
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textInitial,
                       "1st Undo the text should be its init value = \(textInitial)")
        XCTAssertFalse(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)

        // 1st Redo
        t.passThroughTgtUm.redo()
        XCTAssertEqual(t.text, textChanged,
                       "1st Redo the 1st Undo should be undone and the text its changed value  = \(textChanged)")
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)

        // 2nd Undo
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textInitial,
                       "2nd Undo the text should be back to its init value again = \(textInitial)")
        XCTAssertFalse(t.passThroughTgtUm.canUndo)
        XCTAssertTrue(t.passThroughTgtUm.canRedo)

        // 2nd Redo
        t.passThroughTgtUm.redo()
        XCTAssertEqual(t.text, textChanged,
                       "2nd Redo the and the should be its changed value again  = \(textChanged)")
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        XCTAssertFalse(t.passThroughTgtUm.canRedo)
    }

    func test_undoesMultipleStacked() throws {
        let textInitial = "Original text"
        let t = UndoableString(text: textInitial)

        let textChange1 = "First changed text"
        t.text = textChange1
        t.makeTextUndoableToNewCheckpoint(withActionName: "Some Action Name for textChange1")

        let textChange2 = "Second changed text"
        t.text = textChange2
        t.makeTextUndoableToNewCheckpoint(withActionName: "Some Action Name for textChange2")

        let textChange3 = "Third changed text"
        t.text = textChange3
        t.makeTextUndoableToNewCheckpoint(withActionName: "Some Action Name for textChange3")

        // Now verify can unwind changes with a bit of jiggle in the middle
        // Change 3 to 2
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textChange2)

        // Jiggle - Change 2 to Change 3 and then back to Change 2
        t.passThroughTgtUm.redo()
        XCTAssertEqual(t.text, textChange3)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textChange2)
        XCTAssertTrue(t.passThroughTgtUm.canUndo)

        // Change 2 to 1
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textChange1)

        // Change 1 to initial state
        XCTAssertTrue(t.passThroughTgtUm.canUndo)
        t.passThroughTgtUm.undo()
        XCTAssertEqual(t.text, textInitial)
        XCTAssertFalse(t.passThroughTgtUm.canUndo)
    }


}
