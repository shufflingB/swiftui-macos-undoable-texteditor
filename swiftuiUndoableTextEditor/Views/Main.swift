//
//  Main.swift
//  mockCode
//
//  Created by Jonathan Hume on 30/08/2022.
//

import Combine
import SwiftUI

struct Main: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.undoManager) var suiUm: UndoManager?
    @Environment(\.controlActiveState) var ctrlState: ControlActiveState

    @State private var selection: UUID?
    
    @StateObject var otherRandomItem = Item(
        text: "Not in the sidebar list random other item's note",
        title: "Other item"
    )

    @FocusedValue(\.undoableStringKey) private var focusedUString: UndoableString?

    var body: some View {
        NavigationSplitView {
            SideBar(selection: $selection)
                .padding(.vertical)

        } detail: {
            Detail(displayId: selection, otherItem: otherRandomItem)
                .padding()
        }
        .onChange(of: ctrlState) { newCtrlState in
            print("oncChange, changed to = \(newCtrlState)")
            if newCtrlState == .inactive {
                UndoableString.saveBlockUndoInfo(to: focusedUString, extUndoMgr: suiUm)
            }

            if newCtrlState == .key {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    UndoableString.pushBlockUndoInfo(from: focusedUString, to: suiUm)
                }
            }
        }

        .onChange(of: focusedUString) { [lastFocusedUString = self.focusedUString] newFocusedUString in
            print("Got change of focusedUString old = \(String(describing: lastFocusedUString?.text)), new  \(String(describing: newFocusedUString?.text))")

            UndoableString.onFocusChanged(
                saveUndoInfoFor: lastFocusedUString,
                restoreUndoInfoFor: newFocusedUString,
                updatingSuiUm: suiUm
            )
        }
    }
}
