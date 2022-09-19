//
//  Main_Detail.swift
//  mockCode
//
//  Created by Jonathan Hume on 30/08/2022.
//
import SwiftUI

extension Main {
    struct Detail: View {
        @EnvironmentObject var appModel: AppModel
        let displayId: UUID?
        @ObservedObject var otherItem: Item

        private var itemFromSidebarSelection: Item {
            guard let displayId = displayId else {
                return Item(text: "Dummy default: Selection.first == nil; should never see this",
                            title: "Bad Data Sentinel1")
            }

            guard let firstItemWithId: Item = appModel.items.first(where: { $0.id == displayId }) else {
                return Item(text: "Dummy default: Unable to find Item with matching id = \(displayId)",
                            title: "Bad Data Sentinel1")
            }
            return firstItemWithId
        }

        var body: some View {
            HStack {
                if displayId != nil {
                    DetailItem(
                        title: "1st View of Sidebar selected Item '\(itemFromSidebarSelection.title)'",
                        item: itemFromSidebarSelection
                    )
                    .accessibilityIdentifier("DetailBarItem1")
                    DetailItem(
                        title: "2nd View of Sidebar selected Item '\(itemFromSidebarSelection.title)'",
                        item: itemFromSidebarSelection
                    )
                    .accessibilityIdentifier("DetailBarItem2")
                } else {
                    Text("No items selected")
                        .frame(maxWidth: .infinity)
                }
                Spacer()
                DetailItem(
                    title: "Ever present view of other Item  '\(otherItem.title)'",
                    item: otherItem
                )
                .accessibilityIdentifier("DetailOther")
            }
        }
    }
}
