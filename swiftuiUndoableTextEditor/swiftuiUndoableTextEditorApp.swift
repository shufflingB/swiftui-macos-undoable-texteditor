//
//  swiftuiUndoableTextEditorApp.swift
//  swiftuiUndoableTextEditor
//
//  Created by Jonathan Hume on 15/09/2022.
//

import SwiftUI

let dummyItems: Array<Item> = [
    Item(text: "zero", title: "Item 0"),
    Item(text: "one", title: "Item 1"),
    Item(text: "two", title: "Item 2"),
]


@main
struct MockCodeApp: App {
    @StateObject var appModel = AppModel(items: dummyItems)
    
    var body: some Scene {
        WindowGroup {
            Main()
                .environmentObject(appModel)
        }
    
        
    }
}
