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

1. Good undo management is something most existing app's on macOS provide.
2. As of 2022/09, SwiftUi's builtin in undo (and redo) for the main text editing component (`TextEditor`)  do not provide a ready API or documentation on how to achieve.

## How

### High-level
`UndoableString` object has a `String` property and a pass-through `UndoManager` for coupling into SwiftUI's per window `UndoManager`s

The `String` property is bound in the standard way to any `TextEditor` view's `text` parameter that is to interact with it. 

In operation, the user edits that bound `String` in the `TextEditor` making use of Apple's built-in `UndoManager` functionality as per normal.

The `UndoableString` object then creates its own independent, background undoable snapshots of the user's text when they:

1. Pause for a short while during editing, for example, as is reaching the end of a semantic block of text such as a word, sentence or paragraph.
2. Shift their focus away from the `TextEditor` view.

Both sets of snapshots are coalesced into `UndoableString`'s  pass-through `UndoManager` on focus shift events. 

Subsequently,  when any other `TextEditor` view that interacts with the `UndoableString` becomes active. The `UndoableString`'s stored undo operations are loaded into SwiftUI's built-in per-window instance of `UndoManager` as pass-throughs operations that connect to the `UndoableStrings` pass-through `UndoManager`

### More

The `UndoableString` class:
- Integrates 
	- A `String` property. 
	- Two instances of `UndoManager`:
		- One for capturing snapshots triggered by the editing activity watchdog timer
		- One for storing coalesced changes and for linking via pass-through to external `UndoManager`, such a SwiftUI's per window instances.
- Layers on top of these the functionality to enable:
	1. Watchdog timer driven checkpointing of changes to the `String` when user activity pauses.
	2. Checkpointing when a user's focus moves elsewhere.
	1. Creating a pass-through coupling from external `UndoManager`s to it's pass-through `UndoManager` when the user's focus moves back.

External changes in SwiftUI View instances of a `FocusedValue` and the window's `@Environment(\.controlActiveState)` variable are then used to trigger:

0. On the user moving their focus elsewhere away from the `TextEditor` that is interacting with the `UndoableString` instance to:
	1. Copy the the watchdog timer's snapshots `UndoManager` state into its main pass-through `UndoManager`
	1. Capture any remaining differences i.e. that that is not already captured by the timer mechanism, into main pass-through `UndoManager` as well.
2. On the user moving their focus back to interacting with the same `UndoableString` instance, then it:
	3. Builds an undo stack for SwiftUI's built-in per-window instance that passes-through to the `UndoableString`'s pass-through `UndoManager` instance.

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
