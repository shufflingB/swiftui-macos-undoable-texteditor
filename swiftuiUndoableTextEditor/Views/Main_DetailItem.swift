//
//  DetailItem.swift
//  mockCode
//
//  Created by Jonathan Hume on 14/09/2022.
//

import SwiftUI

extension Main {
    struct DetailItem: View {
        let title: String
        @ObservedObject var item: Item
        var body: some View {
            VStack {
                Text(title)
                    .padding()
            
                DetailItemNote(uString: item.note)
                    .frame(maxWidth: 400)
                    .id(item.id)
                    .focusedValue(\.undoableStringKey, item.note)
            }
        }
    }
}
