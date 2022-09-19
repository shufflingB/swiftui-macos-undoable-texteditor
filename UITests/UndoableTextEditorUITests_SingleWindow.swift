//
//  mockCodeUITests.swift
//  mockCodeUITests
//
//  Created by Jonathan Hume on 06/09/2022.
//

import XCTest

final class UndoableTextEditorUITests_SingleWindow: XCTestCase {
    let app = XCUIApplication()

    //    static let appWindowPredicate = NSPredicate(format: "identifier LIKE %@", appWindowKey)

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        app.launch()
        if app.win2.exists {
            app.win2.click()
            app.menuCloseWindow.click()
        }
        app.win1.click()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        print("GETTING TORN DOWN")
    }

    func test0000_singleItemSingleViewSingleWindowUndo() throws {
        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "Given there are no outstanding undo operations for this item at the start of the test")

        let noteInitial = app.detail1_forSidebarItem.value as? String
        
        app.typeText("1")

        XCTAssertNotEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                          "Then when the note field is changed")

        
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "The Edit menu should update to show an option to Undo the change")

        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "Then after undoing the  note should be restored to its original value")

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "Then after undoing the Edit menu should not offer an option to Undo any further changes")
    }

    func test0010_singleItemTwoViewSingleWindowUndoInSecond() throws {
        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "Given there are no outstanding undo operations for this item at the start of the test")
        let noteInitial = app.detail1_forSidebarItem.value as? String

        app.typeText("1")
        XCTAssertNotEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                          "When the first view on the note field is changed")

        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "Then the Edit menu should show an option to undo")

        app.detail2_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "And the same Edit menu undo option should be visible on the second view")

        app.menuUndo.click()
        XCTAssertEqual(app.detail2_forSidebarItem.value as? String, noteInitial,
                       "And after undoing in the second view the note should be restored to its original value")

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "And the Edit menu should not offer an option to Undo any further changes for the second view")

        app.detail1_forSidebarItem.click()
        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "Or the original first view")
    }

    func test0020_singleItemMultiViewsSingleWindowSavesUndo() throws {
        /// Check that
        /// 1) The notes  undo stack is shared across view of the same data.
        /// 2) It is saved and restored when focus move elsewhere and back to it respectively
        /// 3) The pass-through to the notes works at least once.
        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()

        let noteInitial = app.detail1_forSidebarItem.value as? String
        let noteOther = app.detail3_otherItem.value as? String

        // Make change to first note in view 1
        app.typeText("1")
        let noteChanged = app.detail1_forSidebarItem.value as? String
        XCTAssertNotEqual(noteChanged, noteInitial,
                          "Then when the note field is changed in the first view in the window")
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "The Edit menu should update to show an option to Undo the change for that item")

        // Jump to the second view of the note
        app.detail2_forSidebarItem.click()
        XCTAssertEqual(app.detail2_forSidebarItem.value as? String, noteChanged,
                       "And that alteration is reflected in the second view onto it")
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "And Edit menu will provide the same Undo options for the item")

        // Jump to some other note
        app.detail3_otherItem.click()
        XCTAssertEqual(app.detail3_otherItem.value as? String, noteOther,
                       "But the other item's note remains unchanged")
        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "And its Edit menu should show there are no undo action for it")

        // Then back to a view displaying the first note
        app.detail2_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "And if jump back to one of the view on the first note it show Undo is available again")

        // Undo on first note
        app.menuUndo.click()
        XCTAssertEqual(app.detail2_forSidebarItem.value as? String, noteInitial,
                       "And triggering that Undo reverts the note to its original content")
        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "And updates the Edit menu to show no further abiltiy to Undo changes")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "But instead enables an option to Redo the undone change")

        // Redo on the first note
        app.menuRedo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteChanged,
                       "Then if that Redo is triggered the note gets set back to the changed value")
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "And the Edit menu changes to shows and ability to Undo the last redo")
        XCTAssertFalse(app.menuRedoShowsRedoable,
                       "But no further option for Redo options")
    }

    func test0040_singleItemMultiViewsSingleWindowSavesRedo() throws {
        /// Check that
        /// 1) The notes  undo stack redo is saved and restored when focus move elsewhere and back to it respectively
        /// 2) The pass-through to the notes works at least once.

        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()

        let noteInitial = app.detail1_forSidebarItem.value as? String

        // Make change to first note
        app.typeText("1")

        // Move focus to other note fieled
        app.detail3_otherItem.click()

        // Jump back to first
        app.detail2_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "When jump back to a note where a note was previously made it show Undo is available again")

        // Undo it
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "Undoing reverts the text to the original content")
        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "And removes Edit menu for Undos")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "But adds option to redo the change")

        // Jump out elsewhere
        app.detail3_otherItem.click()

        // Jump back
        app.detail2_forSidebarItem.click()

        // Verfiy Redo is available.
        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "When jumping back to a after previously undo changes for it the it should show there are not changes it can undo")

        XCTExpectFailure("As of 2022/09/10, no known approach to achieve with SwiftUI ")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And it has the ability redo the previous undo operation")
    }

    func test0050_twoSideBarItemsSingleWindowSingleViewUndo() throws {
        /// Check that
        /// 1) The notes  undo stack is saved and restored when focus move elsewhere by dint of changing the
        /// the item selected and back to it respectively (focus and selection are different things but can get knickers in a twist)
        /// 3) The pass-through to the note's undo manager works at least once.

        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()

        let noteInitial = app.detail1_forSidebarItem.value as? String
        app.typeText("1")
        let noteChanged = app.detail1_forSidebarItem.value as? String

        XCTAssertNotEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                          "When a note is changed")

        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "The Edit menu should should it is undoable")

        // Use the sidebar to load a different item's notes into the the date
        app.sideBarRow1.click()
        app.detail1_forSidebarItem.click()

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "And then when focus is moved to an unchanged note then there should be no option to Undo changes")

        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "But moving to original note restores the Edit menu's Undo options")

        // 1st Undo
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "And if that Undo is triggered the note is reverted to showing its original content")

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "The Edit menu will show no further undo's are available.")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And instead offers an option to Redo the change just undone")

        // 1st Redo
        app.menuRedo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteChanged,
                       "And if that Redo option is triggered the note will show the changed value again.")
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "The Edit menu will show the Undo option is available and")
        XCTAssertFalse(app.menuRedoShowsRedoable,
                       "And further Redo's are not")
    }

    func test0200_undosArePreservedAcrossMultipleItemViewChanges() throws {
        /// Check that
        /// 1) The notes  undo stack is saved and restored when focus move elsewhere  over repeasted note viewed changes
        /// and doesn't incorrectly save extra undo on move away event if notthing has been changed.
        /// 2) Undo works at least once at the end.
        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()

        let noteInitial = app.detail1_forSidebarItem.value as? String

        // Change the note
        app.typeText("1")

        let noteChanged1 = app.detail1_forSidebarItem.value as? String
        XCTAssertNotEqual(noteChanged1, noteInitial,
                          "When the note field is changed in the first view in the window")
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "The Edit menu should update to show an option to Undo the change for that item")

        // View other note
        app.detail3_otherItem.click()

        // Focus back on original but make no additional changes
        app.detail2_forSidebarItem.click()

        // Focus somewhere else
        app.sideBarRow1.click()
        app.detail1_forSidebarItem.click()

        // Move back to original and check we can only undo once
        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()

        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "After moving the focus away from the original note multiple times its Edit menu say it is Undoable")
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "And if that Undo is triggered the note is reverted to showing its original content")
        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "The Edit menu will show no further undo's are available.")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And instead it will offer an option to Redo the change just undone")
    }

    func test0500_undoMultipleSavedUndos() throws {
        /// Check that
        /// 1) Multiple undos are saved and popped off the stack correctly

        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()
        let noteInitial = app.detail1_forSidebarItem.value as? String

        // Make the first change to the note
        app.typeText("1")
        let noteChanged1 = app.detail1_forSidebarItem.value as? String
        XCTAssertNotEqual(noteChanged1, noteInitial,
                          "When the note field is changed in the first view in the window")

        // Move focus onto different note and back to the original note and make a second change
        app.detail3_otherItem.click()
        app.detail1_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "Then after returning focus to original note the menu shows it as Undoable")
        app.typeText("2")
//        let noteChanged2 = app.detail1_forSidebarItem.value as? String

        // Move focus onto different note and then back to the original note
        app.detail3_otherItem.click()
        app.detail1_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "Then after returning focus to original note for the second time the note is Undoable")

        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteChanged1,
                       "And when the second change is undone the text show the original changed text")

        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "And when the first change is undone the text show the original text")
        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "The Edit menu will show no further undo's are available.")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And instead it will offer an option to Redo the change just undone")

        // Move focus onto different note and back a final time
        app.detail3_otherItem.click()
        app.detail1_forSidebarItem.click()
        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "And if change focus away anf back the edit menu will remain showing no further undo's are available.")
    }

    func test0500_multipUndoRedoBehavior() throws {
        /// Check that
        /// 1) Saved undo's, have matching redo's that don't get themselves out of kliter when bounce back and forward between them

        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()
        let noteInitial = app.detail1_forSidebarItem.value as? String

        // Make the first change to the note
        app.typeText("1")
        let noteChanged1 = app.detail1_forSidebarItem.value as? String
        XCTAssertNotEqual(noteChanged1, noteInitial,
                          "When the note field is changed in the first view in the window")

        // Move focus onto different note and back to the original note
        app.detail3_otherItem.click()
        app.detail1_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "Then after returning focus to original note the menu shows it as Undoable")

        // 1st Undo
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "And if that Undo is triggered the note is reverted to showing its original content")

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "The Edit menu will show no further undo's are available.")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And instead offers an option to Redo the change just undone")

        // 1st Redo
        app.menuRedo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteChanged1,
                       "And if that Redo option is triggered the note will show the changed value again.")
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "The Edit menu will show the Undo option is available and")
        XCTAssertFalse(app.menuRedoShowsRedoable,
                       "And further Redo's are not")

        // 2nd Undo - Undoing the fits Redo
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "And if the Undo is triggered a 2nd time the note is reverted to showing its original content again")

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "The Edit menu will show no further undo's are available.")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And instead offers an option to Redo the change just undone")

        // 2nd Redo - Redoing the Undoing of the first Redo
        app.menuRedo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteChanged1,
                       "And if that Redo option is triggered a second time note will show the changed value once again.")
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "The Edit menu will show the Undo option is available and")
        XCTAssertFalse(app.menuRedoShowsRedoable,
                       "And further Redo's are not")
    }

    func test0500_multipleUndosCanBe() throws {
        /// Check that
        /// 1) Mutliple stask of undo's can be successfully undo

        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()
        let noteInitial = app.detail1_forSidebarItem.value as? String

        // Make the first change to the note
        app.typeText("1")
        let noteChanged1 = app.detail1_forSidebarItem.value as? String
        XCTAssertNotEqual(noteChanged1, noteInitial,
                          "When the note field is changed in the first view in the window")

        // Move focus onto different note and back to the original note
        app.detail3_otherItem.click()
        app.detail1_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "Then after returning focus to original note the menu shows it as Undoable")
        app.typeText("2")

        // For the second time move focus onto different note and back to the original note
        app.detail3_otherItem.click()
        app.detail1_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "And after again returning focus to original note the menu shows it as Undoable")

        // 1st Undo - Revert last change and take the contents back to te first changed contents
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteChanged1,
                       "And if that Undo is triggered the last change is undone and the note is reverted to showing its first changed content")

        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "The Edit menu will show annother undo is availabe to revert the original content")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And also offers an option to Redo the change just undone")

        // 2nd Undo - Undoing the fits Redo
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "And if the Undo is triggered a 2nd time the note is reverted to showing its original contents")

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "The Edit menu will show no further undo's are available.")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And instead offers an option to Redo the change just undone")
    }

    func test0700_differentUndosStacksForDifferentNotes() throws {
        /// Check that notes maintain their own independent undo stacks
        ///
        // Make a change to one item's notes
        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()
        let note1Initial = app.detail1_forSidebarItem.value as? String
        app.typeText("1")

        // Make a change another items notes
        app.sideBarRow1.click()
        app.detail1_forSidebarItem.click()
        let note2Initial = app.detail1_forSidebarItem.value as? String
        app.typeText("1")

        // Focus back on original
        app.sideBarRow0.click()
        app.detail1_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable)
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, note1Initial)

        // Move back to the other item's notes
        app.sideBarRow1.click()
        app.detail1_forSidebarItem.click()
        XCTAssertTrue(app.menuUndoShowsUndoable)
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, note2Initial)
    }
}
