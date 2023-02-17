
# Duration Editor plugin for MuseScore 3.x
**Duration Editor** is an plugin for MuseScore that allows to change the notes entry paradigm of MuseScore – being rhythm first, melody second – into **Melody first, rhythm second**. 
Where MuseScore works in a *vertical* approach (inserting a note in a measure will insert a rest in all the other staves at the same segment, deleting a note ("time-delete") in a measure will delete the same amount of time in all the other staves) **Duration Editor** works in *horizontal* approach. Every modification done in a measure is limited to the current staff, not impacting the other staves.

## Demo ##
![Duration Editor in action](/demo/demo.gif)



## New in 1.3.0
### New
* Tuplets insert and removal: convert tuplets to regular consecutive notes/rests
* The _Tie_ function can tie back and forth, from a rest and from a note.

### Improved
* Core functions: better handling of non-4/4 measures
* Improved single voice / multi voice behaviour of all functions


## Features ##

### Features ###
* Change any note duration, 
* Change/Add/Remove the notes dots,
* Insert rests,
* Delete notes, 
* Add ties between chords and following rests (1.3.0), 
* Tuplets insert: convert consecutive notes/rests to tuplets (1.3.0),
* Tuplets removal: convert tuplets to consecutive notes/rests (1.3.0),
* Multi-voice or single-voice eidition (1.3.0)

### About the _Tie_ feature (1.3.0)
* select a rest, and the "Add tie" button will copy the previous chord (or the next chord, if no previous one) into that rest and tie them together.
* select a chord, and the "Add tie" button will copy it to an immediately previous rest (or the next rest, if no previous one) and tie them together.

### About the _Tuplet_ feature (1.3.0)
* select any range of consecutive chords/notes/rests, and the "Tuplet" button will transform these into a without impacting (i.e. adding rests) the following chord/notes.
* select any note of a tuplet, and the "Tuplet" button will replace the tuplet with its notes/rests without impacting (i.e. "eating") the following notes/rests.

### Remarks ###
* All those feature are working 
	* at the **measure** and **staff-level** (except the _Add tie_ function which is cross-measure), 
	* without impacting the next notes of the measure (they will be moved accordingly), 
	* without impacting the other staves
* All the actions are undoable. It will require up-to 2-5 undos before completely undoing a action.
* The _Insert and Remove tuplets_ as well as the _Single voice edition_ do not manage all the notes characteristics. Some of them might by lost when performing those actions. This is improved in 1.3.0

## Support of MS4.0
**NOT SUPPORTED**

MuseScore 4.0 support for plugin is minimal. Many functions are not supported for the time being or have changed. Dock plugins are not supported anymore. 
Therefore, this plugin does not work under MuseScore 4.0.


## Sponsorship ##
If you appreciate my plugins, you can support and sponsor their development on the following platforms:
[<img src="/support/Button-Tipeee.png" alt="Support me on Tipee" height="50"/>](https://www.tipeee.com/parkingb) 
[<img src="/support/paypal.jpg" alt="Support me on Paypal" height="55"/>](https://www.paypal.me/LaurentvanRoy) 
[<img src="/support/patreon.png" alt="Support me on Patreon" height="25"/>](https://patreon.com/parkingb)

And also check my **[Zploger application](https://www.parkingb.be/zploger)**, a tool for managing a library of scores, with extended MuseScore support.


## Attention ##
Due to the “sensible” nature of MuseScore’s API, and although having been thoroughly tested, you may fall into some limit cases where the plugin crashes MuseScore. No such cases have been detected since the version 1.0.1, but there is no warranty or whatsoever.

## Download and Install ##
Download the [last version](https://github.com/lgvr123/musescore-elementanalyser/releases).
For installation see [Plugins](https://musescore.org/en/handbook/3/plugins "handbook").

## And if you like this note-entry paradigm... ##
The goal of that plugin is to demonstrate that there is another note-entry paradigm needed/possible in MuseScore.
The ultimate goal is to have this paradigm available natively in MuseScore without any plugin.
If you like that approach, don't hesitate to the drop a message on the [MuseScore forum](https://musescore.org/en/node/321244) about you liking this way of working. 


## IMPORTANT
NO WARRANTY THE PROGRAM IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW THE AUTHOR WILL BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF THE AUTHOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.


