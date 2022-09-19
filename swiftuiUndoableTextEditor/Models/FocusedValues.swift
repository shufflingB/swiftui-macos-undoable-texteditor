//
//  FocusedValues.swift
//  mockCodeUITests
//
//  Created by Jonathan Hume on 09/09/2022.
//

import SwiftUI

struct UndoableStringKey: FocusedValueKey {
    typealias Value = UndoableString
}

extension FocusedValues {
    var undoableStringKey: UndoableStringKey.Value? {
        get { self[UndoableStringKey.self] }
        set {
            self[UndoableStringKey.self] = newValue
        }
    }
}
