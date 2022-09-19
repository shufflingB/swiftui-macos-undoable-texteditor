//
//  Editor.swift
//  mockCode
//
//  Created by Jonathan Hume on 06/09/2022.
//
import SwiftUI

extension Main {
    struct DetailItemNote: View {
        @ObservedObject var uString: UndoableString
        
        var body: some View {
            TextEditor(text: $uString.text)
        }
    }
}
