//
//  XCUIApplication_helpers.swift
//  mockCodeUITests
//
//  Created by Jonathan Hume on 07/09/2022.
//

import XCTest
extension XCUIApplication {
    // "SwiftUI.ModifiedContent<mockCode.Main, SwiftUI._EnvironmentKeyWritingModifier<Swift.Optional<swiftuiUndoableTextEditor.AppModel>>>-1-AppWindow-1"
    // "SwiftUI.ModifiedContent<swiftuiUndoableTextEditor.Main, SwiftUI._EnvironmentKeyWritingModifier<Swift.Optional<swiftuiUndoableTextEditor.AppModel>>>-1-AppWindow-1"]
    // "swiftuiUndoableTextEditor.Main, SwiftUI._EnvironmentKeyWritingModifier<Swift.Optional<swiftuiUndoableTextEditor.AppModel>>>-1-AppWindow-2"
    static let appWindow1Predicate = NSPredicate(format: "identifier CONTAINS[c] %@", "-1-AppWindow-1")
    static let appWindow2Predicate = NSPredicate(format: "identifier CONTAINS[c] %@", "-1-AppWindow-2")
    static let appWindow3Predicate = NSPredicate(format: "identifier CONTAINS[c] %@", "-1-AppWindow-3")

    var win1: XCUIElement { windows.element(matching: Self.appWindow1Predicate) }
    var win2: XCUIElement { windows.element(matching: Self.appWindow2Predicate) }
    var win3: XCUIElement { windows.element(matching: Self.appWindow3Predicate) }

    var menuNewWindow: XCUIElement { menuBars.menuItems["menuAction:"] }
    var menuCloseWindow: XCUIElement { menuBars.menuItems["performClose:"] }

    var menuUndo: XCUIElement { menuBars.menuItems["undo:"] }
    static let NoUndoText = "Undo" ///  It's usually greyed out but can't detect that
    var menuUndoShowsUndoable: Bool {
        _ = menuUndo.waitForExistence(timeout: 3)
        return menuUndo.title == Self.NoUndoText ? false : true
    }

    var menuRedo: XCUIElement { menuBars.menuItems["redo:"] }
    static let NoRedoText = "Redo"
    var menuRedoShowsRedoable: Bool {
        _ = menuRedo.waitForExistence(timeout: 3)
        return menuRedo.title == Self.NoRedoText ? false : true
    }

    /// Have to have keyWindow in order for these to work without additional process bc they'll return mutliple entries otherwise
    var sideBarRow0: XCUIElement { outlines.staticTexts["SideBarRow0"] }
    var sideBarRow1: XCUIElement { outlines.staticTexts["SideBarRow1"] }

    func sideBarRow(_ row: Int, window win: XCUIElement) -> XCUIElement {
        win.outlines.staticTexts["SideBarRow\(row)"]
    }

    var detail1_forSidebarItem: XCUIElement { groups.containing(.staticText, identifier: "DetailBarItem1").children(matching: .scrollView).matching(identifier: "DetailBarItem1").element(boundBy: 0).children(matching: .textView).element }

    var detail2_forSidebarItem: XCUIElement { groups.containing(.staticText, identifier: "DetailBarItem2").children(matching: .scrollView).matching(identifier: "DetailBarItem2").element(boundBy: 0).children(matching: .textView).element }

    var detail3_otherItem: XCUIElement { groups.containing(.staticText, identifier: "DetailOther").children(matching: .scrollView).matching(identifier: "DetailOther").element(boundBy: 0).children(matching: .textView).element }

    func detail1_forSidebarItem(inWin win: XCUIElement) -> XCUIElement {
        win.groups.containing(.staticText, identifier: "DetailBarItem1").children(matching: .scrollView).matching(identifier: "DetailBarItem1").element(boundBy: 0).children(matching: .textView).element
    }
}
