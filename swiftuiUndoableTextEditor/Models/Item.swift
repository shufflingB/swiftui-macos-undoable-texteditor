//
//  Item.swift
//  mockCode
//
//  Created by Jonathan Hume on 30/08/2022.
//
import Combine
import SwiftUI

class Item: ObservableObject, Identifiable, Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }

    @Published var note: UndoableString
    @Published var title: String
    let id: UUID = UUID()


    init(text: String, title: String) {
        self.note = UndoableString(text: text, checkpointAfter: 2, withActionName: "Block")
        self.title = title
    }
}

