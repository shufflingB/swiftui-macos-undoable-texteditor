//
//  MockCodeTwoWindowUITests.swift
//  mockCodeUITests
//
//  Created by Jonathan Hume on 14/09/2022.
//

import XCTest

final class UndoableTextEditorUITests_TwoWindow: XCTestCase {
    let app = XCUIApplication()
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        app.launch()
        if app.win2.exists == false {
            app.menuNewWindow.click()
        }
        XCTAssertTrue(app.win1.exists && app.win2.exists,
                      "Given the application has at least two windows")
        
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test1500_keyWindowChangesPreserveUndoInASingleWindow() throws {
        /// Test that a change in one window doesn't get screwed over when the moment the keywindow status is moved elsewhere

        // Make change in the 1st window
        app.win1.click()
        app.sideBarRow(0, window: app.win1).click()
        app.detail1_forSidebarItem.click()
        let noteInitial = app.detail1_forSidebarItem.value as? String
        app.typeText("1")
        

        // Move keyWindow status to the other, 2nd window but make no changes
        app.win2.click()

        // Move back to the 1st window and verify that that is showing it has an undo
        app.win1.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "Then after returning key status to original window the menu shows the note is Undoable")

        // Move keyWindow status to the 2nd window againg but make no changes
        app.win2.click()

        // Move back to the 1st window again and verify that it is still showing it has an undo
        app.win1.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "Then after returning key status to original window a 2nd time the menu still shows the note is Undoable")

        // 1st Undo
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "And if that Undo is triggered the note is reverted to showing its original content")

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "The Edit menu will show no further undo's are available.")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And instead offers an option to Redo the change just undone")
    }

    func test1600_undoHistoryIsLoadedWhenANoteAppearsInANewDifferentWindow() throws {
        let win1 = app.win1
        
        if app.win2.exists {
            app.menuCloseWindow.click()
        }
        XCTAssertFalse(app.win2.exists,
                       "Given the application does not have a second window at the start")
        
        let win2 = app.win3  /// Identifiers don't get reused; so even in win2 is closed and then reopened it'll still get the
        /// the identifier of window 2

        // Make a change in the first window
        win1.click()
        app.sideBarRow(0, window: win1).click()
        app.detail1_forSidebarItem.click()
        let noteInitial = app.detail1_forSidebarItem.value as? String
        app.typeText("1")

        // Open a second window and see if we can undo the change there.
        app.menuNewWindow.click()
        XCTAssertTrue(win2.exists,
                      "After a note is change when a second window is opened")
        win2.click()
        app.sideBarRow(0, window: win2).click()
        app.detail1_forSidebarItem.click()

        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "Then the changed note should also be undoable in the second window")

        // 1st Undo
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "And if that Undo is triggered the note is reverted to showing its original content")

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "The Edit menu will show no further undo's are available.")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And instead offers an option to Redo the change just undone")
    }

    func test1700_undoHistoryIsLoadedWhenANoteAppearsInExistingDifferentWindow() throws {
        let win1 = app.win1
        let win2 = app.win2
        if win2.exists == false {
            app.menuNewWindow.click()
        }
        XCTAssertTrue(win2.exists,
                      "Given the application has a second window open at the start")

        // Set both windows up to viewing the same item
        win2.click()
        app.sideBarRow(0, window: win2).click()
        app.detail1_forSidebarItem.click()

        win1.click()
        app.sideBarRow(0, window: win1).click()
        app.detail1_forSidebarItem.click()

        // Make a change in window 1
        let noteInitial = app.detail1_forSidebarItem.value as? String
        app.typeText("1")

        // Check to see if the undo is available for the second window
        win2.click()
        app.detail1_forSidebarItem.click()

        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "Then the changed note should also be undoable in the second window")

        // 1st Undo
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteInitial,
                       "And if that Undo is triggered the note is reverted to showing its original content")

        XCTAssertFalse(app.menuUndoShowsUndoable,
                       "The Edit menu will show no further undo's are available.")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "And instead offers an option to Redo the change just undone")
    }

    func test1800_multipleUndoFromDifferentWindowsCanBeUndoneAndRedoneInAnyWindow() throws {
        let win1 = app.win1
        let win2 = app.win2
     
        // Set both windows up to viewing the same item
        win2.click()
        app.sideBarRow(0, window: win2).click()
        app.detail1_forSidebarItem.click()

        win1.click()
        app.sideBarRow(0, window: win1).click()
        app.detail1_forSidebarItem.click()

        // Make a change in window 1
//        let noteInitial = app.detail1_forSidebarItem.value as? String
        app.typeText("1")
        let noteChange1 = app.detail1_forSidebarItem.value as? String

        // Make a change in window 2
        win2.click()
        app.detail1_forSidebarItem.click()
        app.typeText("2")
//        let noteChange2 = app.detail1_forSidebarItem.value as? String

        // Back to first window and see if can undo the last of two changes
        win1.click()
        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "Then the changed note should be showing it is undoabl")

        // Undo last change
        app.menuUndo.click()
        XCTAssertEqual(app.detail1_forSidebarItem.value as? String, noteChange1,
                       "And after it is undo then the last change should be reverted")

        XCTAssertTrue(app.menuUndoShowsUndoable,
                      "The Edit menu will show undo remains available to remove the first change")
        XCTAssertTrue(app.menuRedoShowsRedoable,
                      "As well as providing and an offer to Redo the the last change from window 2")
    }
 
}
