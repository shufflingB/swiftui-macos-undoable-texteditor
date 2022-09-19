//
//  SideBar.swift
//  mockCode
//
//  Created by Jonathan Hume on 30/08/2022.
//

import SwiftUI

extension Main {
    struct SideBar: View {
        @EnvironmentObject var appModel: AppModel
        @Binding var selection: UUID?

        var body: some View {
            return List($appModel.items, selection: $selection) { $item in
                Text("\(String(item.title))")
                    .accessibilityIdentifier("SideBarRow\(appModel.getIdx(item.id))")
            }
        }
    }
}
