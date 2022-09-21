#  macOS Undoable Text Editor Demo

## What

A small(ish), macOS only demo of a SwiftUI native implementation of a Xcode **'like'** text editing experience in SwiftUI

It uses checkpointing and a pass-through mechanism from SwiftUI's built in undo functionality to per-object instance `UndoManager`s to achieve:

1. Contextually separated undoable text stacks i.e. the user can undo editing changes from text X independently of those from text Y.
1. A coalescing, persistent undo stack for a given text regardless of the View or Window the user is interacting with that text in. So that, for instance if a user makes a changes to text X then:
    - Mutates a text Y elsewhere, before returning to text X; undoable options are restored for X on their return to working on text X (without mixing in those for Y).
    - Starts working on X in a different window; undoable options are loaded for text X in whatever other window they choose to work on it in.

![App running on macOS Ventura Beta screenshot](Screenshot.png "picture of demo app running on macOS Ventura Beta")

## Why?

As of 2022/09, SwiftUi's builtin in undo (and redo) for the main text editing component (`TextEditor`)  does not provide a ready API or documentation on how to achieve the level of editing undo sophistication most user's expect on macOS.  There's more on this on the Apple Developer forum [here](https://developer.apple.com/forums/thread/713185)

This app explores one way some of those limitations might be worked around.

## How
At a high-level the approach taken here is one whereby there is an `UndoableString` object that has a `String` property that is bound in the standard way to a `TextEditor` view's `text` parameter.

The user edits that `String` in a `TextEditor` making use of its nice, built-in `UndoManager` functionality as per normal.

When the user shifts their focus away from the `TextEditor` view, then at that instance, an undoable checkpoint of the `String` is triggered and captured by the `UndoableString`'s `UndoManager`. 

Subsequently, the `UndoableString`'s undo operations are loaded into SwiftUI's built-in per-window instance of `UndoManager` via a pass-through mechanism when other `TextEditor` views that interact with the `UndoableString` become active again.

*More*
 
Changes in a `FocusedValue` and the window's `@Environment(\.controlActiveState)` are used to trigger:

1. Checkpointing of the `UndoableString` on the user moving their focus elsewhere.
2. Creating/restoring a pass-through undo stack for SwiftUI's built-in per-window instance of `UndoManager` when they move their focus back.
 
The `UndoableString` class:
- Integrates its own instance of `UndoManager` and a `String` property. 
- Layers on top of these the functionality to enable:
	1. Checkpointing of changes to the `String` property and their undoing via its `UndoManager`.
	1. Rewinding and replaying all of its checkpoint'd changes.

Finally, an extension to the `UndoableString` class extends the functionallity to enable interaction with external `UndoManagers` (such as SwiftUI's per window instance) that:
1. As a convenience, saves changes and restores them when the user's focus in the UI changes.
2. Loads the external `UndoManager`'s with pass-through actions to the `UndoableString`'s  `UndoManager` undo actions.

## Running & Testing

1. The demo app has been built and tested on macOS Ventura (13.0 Beta) using Xcode 14.0.  

2. It should work on versions of macOS earlier than that but it has not been tested on those.

To explore how it works run the app. 

Then use the SideBar to select an Item from the demo data and make changes to its note and try undoing:
- Them in the same `TextEditor` area.
- A different `TextEditor` area displaying the same text in the same window.
- A different window.
- After making changes in a different note.

More on the expected behaviour can be understood from the App's Unit and UI tests.

## Known limitations

1. macOS only. While a similar approach might be possible for iPadOS, the current code base is unlikely to build or be testable for iPadOS without rework around the testing and use of `ControlActiveState` (ControlActiveState being macOS 10.15+ 
and Catalyst 13.0+ specific).

2. Undoable checkpointing currently only occurs when the user moves their focus either:
	
	1. Away from the Window, or
	
	2. To a different view in the same window. 

	This makes undo a rather coarse affair (the expectation being that in a production implementation a timer, or watchdog timer, would be used to trigger more regular checkpointing (I may add this shortly)).

3. Loading of the per-Window SwiftUI `UndoManager` is done by rewinding changes and then iteratively playing them forward to create the pass-through undo events. If there are a substantial number of the events registered for  the `UndoableString` this process might slow the UI. (Workaround - restrict number of undo events or possibly move to a more sophisticated pass-through that recursively loads the next one (thereby obviating the need to load them all up front))

4. The multi-window UI testing can get broken by the app starting with multiple windows. (Workaround - close all Windows and restart the app and ensure that it starts with only a single windows before running the UI tests) 

## Alternative approaches

### `NSViewRepresentable`
Empirically, the inability to share a per `String` `UndoManager`  between `TextEditor`'s that are rendering it, is one of the main challenges to providing a macOS like undo experience (this is what necessitates the somewhat convoluted, checkpointing and the reloading of undo state between `UndoManagers` in different `TextEditor` views).  

An alternative approach would be to abandon the use of `TextEditor` and instead wrap an `NSView` in a `NSViewRepresentable` and use a Coordinator object for it to supply an external `UndoManager` via the  `undoManager(for:)` delegate method.






