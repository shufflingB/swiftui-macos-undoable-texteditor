//
//  ContentVM.swift
//  undoManagerOrideDefault
//
//  Created by Jonathan Hume on 23/08/2022.
//
import Foundation
import SwiftUI

class AppModel: ObservableObject {
    @Published var items: Array<Item>

    init(items: Array<Item>) {
        self.items = items
    }

    func getIdx(_ id: UUID) -> Int {
        return items.firstIndex(where: { $0.id == id }) ?? -43
    }
}
