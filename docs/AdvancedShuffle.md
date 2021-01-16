# Advanced Shuffle

Improved replacement for the deprecated Random Playlist plugin.
Provides three-level (per playlist - per group - per track) mixing of tracks with two modes for each level.

Functions
---
With enabled mixing of the plugin, a random playlist is selected first, then a random group in the playlist, then a random track in the group. Each level can be turned on or off independently of others. For example, if shuffling of playlists is turned off, then groups and tracks will be shuffled only in the current playlist, if shuffling of groups is turned off, groups will not be taken into account when shuffling tracks, if shuffling of tracks is turned off, the first track from the playlist or group will be selected.

Each level has two modes of operation: simple shuffle and list.
In the case of simple mixing at the level, a random element is selected that does not coincide with the current one.
Shuffling through a list creates a list of items from which they are selected one at a time, providing a unique, non-repeating sequence. Changing an element of the previous level occurs only after emptying the current list.

Controls
---
The plugin has an "enable-disable" switch associated with the "Miscellaneous" menu item and a hotkey for it, and also controls the state of the mixing built into the player and does not interfere if it is enabled. The plugin's state relative to the built-in shuffle is indicated by the color of the settings tab header.

[Back](../README.md)
