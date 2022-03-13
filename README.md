
# Duration Editor plugin for MuseScore 3.x
**Duration Editor** is an plugin for MuseScore that allows to change the notes entry paradigm of MuseScore – being rhythm first, melody second – into **Melody first, rhythm second**. 
Where MuseScore works in a *vertical* approach (inserting a note in a measure will insert a rest in all the other staves at the same segment, deleting a note ("time-delete") in a measure will delete the same amount of time in all the other staves) **Duration Editor** works in *horizontal* approach. Every modification done in a measure is limited to the current staff, not impacting the other staves.

## Demo ##
![Duration Editor in action](/demo/demo.gif)

## New in 1.2.0 ##
* _Add Tie_ feature: 
	* select a rest, and the "Add tie" button will copy the previous chord into that rest and tie them together.
	* select a chord, and the "Add tie" button will copy it to an immediately following rest and tie them together.
## Features ##
All those feature are working 
* at the **measure** and **staff-level** (except the _Add tie_ function which is cross-measure), 
* without impacting the next notes of the measure (they will be moved accordingly), 
* without impacting the other staves

### Features ###
* Change any note duration, 
* Change/Add/Remove the notes dots
* Insert rests
* Delete notes 
* Add ties between chords and following rests
* All the actions are undoable (see remark below)

## NOTE that this plugin is BETA ##
1. Due to the “sensible” nature of MuseScore’s API, and although having been thoroughly tested, you may fall into some limit cases where the plugin crashes MuseScore. No such cases have been detected since the version 1.0.1, but there is no warranty or whatsoever.
2. All the actions are undoable. It will require up-to 2-3 undos before completely undo a action.

## And if you like this note-entry paradigm... ##
The goal of that plugin is to demonstrate that there is another note-entry paradigm needed/possible in MuseScore.
The ultimate goal is to have this paradigm available natively in MuseScore without any plugin.
If you like that approach, don't hesitate to the drop a message on the [MuseScore forum](https://musescore.org/en/node/321244) about you liking this way of working. 


## IMPORTANT
NO WARRANTY THE PROGRAM IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW THE AUTHOR WILL BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF THE AUTHOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.


