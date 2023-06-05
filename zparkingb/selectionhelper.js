/**********************
/* Parking B - MuseScore - Selection helper
/* v1.2.0 28/9/21 getChordsRestsFromCursor
/* v1.2.1 2/10/21 corrected name of checktVersion
/* v1.2.2 15/03/22 correction in getChordsRestsFromSelection
/* v1.2.3 16/03/22 better handling of absence of opened score
/* v1.3.0 18/06/22 Multiple track selection
/* v1.3.1 18/02/23 All socre-based selection function can receive an optional score
/* v1.3.1 30/03/23 Moved copy- and pasteSelection functions here
/**********************************************/

// -----------------------------------------------------------------------
// --- Vesionning-----------------------------------------
// -----------------------------------------------------------------------

function checktVersion(expected) {
    return checkVersion(expected);
}
function checkVersion(expected) {
    var version = "1.3.1";

	var aV = version.split('.').map(function (v) {return parseInt(v);});
	var aE = (expected && (expected != null)) ? expected.split('.').map(function (v) {return parseInt(v);}) : [99];
	if (aE.length == 0) aE = [99];

	for (var i = 0; (i < aV.length) && (i < aE.length); i++) {
		if (!(aV[i] >= aE[i])) return false;
	}

	return true;
}


// -----------------------------------------------------------------------
// --- Selection helper --------------------------------------------------
// -----------------------------------------------------------------------
/**
 * Get all the selected notes from the selection
 * @return Note[] : each returned {@link Note}  has the following properties:
 *      - element.type==Element.NOTE
 */
function getNotesFromSelection(score) {
    if (!score) score=curScore;
	if (score==null || score.selection==null) return [];
    var selection = score.selection;
    var el = selection.elements;
    var notes = [];
    var n = 0;
    for (var i = 0; i < el.length; i++) {
        var element = el[i];
        if (element.type == Element.NOTE) {
            notes[n++] = element;
        }

    }
    return notes;
}

/**
 * Get all the selected rest from the selection
 * @return Note[] : each returned {@link Rest}  has the following properties:
 *      - element.type==Element.REST
 */
function getRestsFromSelection(score) {
    if (!score) score=curScore;
	if (score==null || score.selection==null) return [];
    var selection = score.selection;
    var el = selection.elements;
    var rests = [];
    for (var i = 0; i < el.length; i++) {
        var element = el[i];
        if (element.type == Element.REST) {
            rests.push(element);
        }

    }
    return rests;
}

/**
 * Get all the selected notes and rests from the selection
 * @return Note[] : each returned {@link Rest}  has the following properties:
 *      - element.type==Element.REST or Element.NOTE
 */
function getNotesRestsFromSelection(score) {
    if (!score) score=curScore;
	if (score==null || score.selection==null) return [];
    var selection = score.selection;
    var el = selection.elements;
    var rests = [];
    for (var i = 0; i < el.length; i++) {
        var element = el[i];
        if ((element.type == Element.REST) || (element.type == Element.NOTE)) {
            rests.push(element);
        }

    }
    return rests;
}
/**
 * Get all the selected chords from the selection
 * @return Chord[] : each returned {@link Chord}  has the following properties:
 *      - element.type==Element.CHORD
 */
function getChordsFromSelection(score) {
    var notes = getNotesFromSelection(score);
    var chords = [];
    var prevChord;
    for (var i = 0; i < notes.length; i++) {
        var element = notes[i];
        var chord = element.parent;
        if (!prevChord || (prevChord !== chord)) {
            chords.push(chord);
        }
        prevChord = chord;
    }
    return chords;
}

/**
 * Get all the selected chords and rests from the selection
 * @return Chords[] : each returned {@link Rest}  has the following properties:
 *      - element.type==Element.REST or Element.CHORD
 */
function getChordsRestsFromSelection(score) {
    var notes = getNotesRestsFromSelection(score);

    var chords = [];
    var prevChord;
    for (var i = 0; i < notes.length; i++) {
        var element = notes[i];

        if (element.type === Element.REST) {
            chords.push(element);
            prevChord = undefined;
        } else if (element.type === Element.NOTE) {
            var chord = element.parent;
            if (!prevChord || (prevChord.track !== chord.track) || (prevChord.parent.tick !== chord.parent.tick)) { // 15/03
                chords.push(chord);
            }
            prevChord = chord;
        }
    }

    return chords;
}

/**
 * Get all the selected segments from the selection
 * @return Segment[] : each returned {@link Segment}  has the following properties:
 *      - element.type==Element.SEGMENT
 */
function getSegmentsFromSelection(score) {
    // Les segments sur base des notes et accords
    var chords = getChordsRestsFromSelection(score);
    var segments = [];
    var prevSeg;
    for (var i = 0; i < chords.length; i++) {
        var element = chords[i];
        var seg = element.parent;
        if (prevSeg && !prevSeg.is(seg)) {
            segments.push(seg);
        }
        prevChord = seg;
    }

    return segments;
}

/**
 * Reourne les fingerings sélectionnés
 * @return Fingering[] : each returned {@link Fingering}  has the following properties:
 *      - element.type==Element.FINGERING
 */
function getFingeringsFromSelection(score) {
    if (!score) score=curScore;
	if (score==null || score.selection==null) return [];
    var selection = score.selection;
    var el = selection.elements;
    var fingerings = [];
    for (var i = 0; i < el.length; i++) {
        var element = el[i];
        if (element.type == Element.FINGERING) {
            fingerings.push(element);
        }
    }
    return fingerings;
}

/**
 * Get all the selected notes based on the cursor.
 * Rem: This does not any result in case of the notes are selected inidvidually.
 * @param oneNoteBySegment : boolean. If true, only one note by segment will be returned.
 * @return Note[] : each returned {@link Note}  has the following properties:
 *      - element.type==Element.NOTE
 *
 */
function getNotesFromCursor(oneNoteBySegment, score) {
    var chords = getChordsFromCursor(score);
    var notes = [];
    for (var c = 0; c < chords.length; c++) {
        var chord = chords[c];
        var nn = chord.notes;
        for (var i = 0; i < nn.length; i++) {
            var note = nn[i];
            notes[notes.length] = note;
            if (oneNoteBySegment)
                break;
        }
    }
    return notes;
}

/**
 * Get all the selected chords based on the cursor.
 * Rem: This does not any result in case of the notes are selected inidvidually.
 * @return Chord[] : each returned {@link Note} has the following properties:
 *      - element.type==Element.CHORD
 *
 */
function getChordsFromCursor(score) {
    if (!score) score=curScore;
	if (score==null) return [];
    var cursor = score.newCursor();
    
    var firstTick,
    firstStaff,
    lastTick,
    lastStaff;
    // start
    cursor.rewind(Cursor.SELECTION_START);
    firstTick = cursor.tick;
    firstStaff = cursor.track;
    // end
    cursor.rewind(Cursor.SELECTION_END);
    lastTick = cursor.tick;
    if (lastTick == 0) { // dealing with some bug when selecting to end.
        lastTick = score.lastSegment.tick + 1;
    }
    lastStaff = cursor.track;
    console.log("getChordsFromCursor ** ");
    debugV(30, "> first", "tick", firstTick);
    debugV(30, "> first", "track", firstStaff);
    debugV(30, "> last", "tick", lastTick);
    debugV(30, "> last", "track", lastStaff);
    var chords = [];

    cursor.rewind(Cursor.SELECTION_START);
    var segment = cursor.segment;
    while (segment && (segment.tick < lastTick)) {
        for (var track = firstStaff; track <= lastStaff; track++) {
            var element;
            element = segment.elementAt(track);
            if (element && element.type == Element.CHORD) {
				debugSegment(segment, track);
                chords[chords.length] = element;
            }
        }
        // cursor.next();
        // segment = cursor.segment;
        segment = segment.next; // 18/6/22 : looping thru all segments, and only defined at the curso level (which is bound to track)
    }

    return chords;
}

function getChordsRestsFromCursor(score) {
    if (!score) score=curScore;
	if (score==null) return [];
    var cursor = score.newCursor();
        
    var firstTick,
    firstStaff,
    lastTick,
    lastStaff;
    // start
    cursor.rewind(Cursor.SELECTION_START);
    firstTick = cursor.tick;
    firstStaff = cursor.track;
    // end
    cursor.rewind(Cursor.SELECTION_END);
    lastTick = cursor.tick;
    if (lastTick == 0) { // dealing with some bug when selecting to end.
        lastTick = score.lastSegment.tick + 1;
    }
    lastStaff = cursor.track;
    console.log("getChordsRestsFromCursor ** ");
    debugV(30, "> first", "tick", firstTick);
    debugV(30, "> first", "track", firstStaff);
    debugV(30, "> last", "tick", lastTick);
    debugV(30, "> last", "track", lastStaff);
    var chords = [];

    cursor.rewind(Cursor.SELECTION_START);
    var segment = cursor.segment;
    while (segment && (segment.tick < lastTick)) {
        for (var track = firstStaff; track <= lastStaff; track++) {
            var element;
            element = segment.elementAt(track);
            if (element && (element.type == Element.CHORD || element.type == Element.REST)) {
				debugSegment(segment, track);
                chords[chords.length] = element;
            }
        }
        // cursor.next();
        // segment = cursor.segment;
        segment = segment.next; // 18/6/22 : looping thru all segments, and only defined at the curso level (which is bound to track)
    }

    return chords;
}

/**
 * Get all the selected rests based on the cursor.
 * Rem: This does not any result in case of the rests and notes are selected inidvidually.
 * @return Rest[] : each returned {@link Note} has the following properties:
 *      - element.type==Element.REST
 *
 */
function getRestsFromCursor(score) {
    if (!score) score=curScore;
	if (score==null) return [];
    var cursor = score.newCursor();
        
    var firstTick,
    firstStaff,
    lastTick,
    lastStaff;
    // start
    cursor.rewind(Cursor.SELECTION_START);
    firstTick = cursor.tick;
    firstStaff = cursor.track;
    // end
    cursor.rewind(Cursor.SELECTION_END);
    lastTick = cursor.tick;
    if (lastTick == 0) { // dealing with some bug when selecting to end.
        lastTick = score.lastSegment.tick + 1;
    }
    lastStaff = cursor.track;
    console.log("getRestsFromCursor ** ");
    debugV(30, "> first", "tick", firstTick);
    debugV(30, "> first", "track", firstStaff);
    debugV(30, "> last", "tick", lastTick);
    debugV(30, "> last", "track", lastStaff);
    var rests = [];

    cursor.rewind(Cursor.SELECTION_START);
    var segment = cursor.segment;
    while (segment && (segment.tick < lastTick)) {
        for (var track = firstStaff; track <= lastStaff; track++) {
            var element;
            element = segment.elementAt(track);
            if (element && element.type == Element.REST) {
				debugSegment(segment, track);
                chords[chords.length] = element;
            }
        }
        // cursor.next();
        // segment = cursor.segment;
        segment = segment.next; // 18/6/22 : looping thru all segments, and only defined at the curso level (which is bound to track)
    }

    return rests;
}


/**
 * Get all the selected notes and rests based on the cursor.
 * Rem: This does not return any result in case of the rests and notes are selected inidvidually.
 * @param oneNoteBySegment : boolean. If true, only one note by segment will be returned.
 * @return Rest[] : each returned {@link Note} has the following properties:
 *      - element.type==Element.REST or Element.NOTE
 *
 */
function getNotesRestsFromCursor(oneNoteBySegment,score) {
    if (!score) score=curScore;
	if (score==null) return [];
    var cursor = score.newCursor();
    
    var firstTick,
    firstStaff,
    lastTick,
    lastStaff;
    // start
    cursor.rewind(Cursor.SELECTION_START);
    firstTick = cursor.tick;
    firstStaff = cursor.track;
    // end
    cursor.rewind(Cursor.SELECTION_END);
    lastTick = cursor.tick;
    if (lastTick == 0) { // dealing with some bug when selecting to end.
        lastTick = score.lastSegment.tick + 1;
    }
    lastStaff = cursor.track;
    console.log("getNotesRestsFromCursor ** ");
    debugV(30, "> first", "tick", firstTick);
    debugV(30, "> first", "track", firstStaff);
    debugV(30, "> last", "tick", lastTick);
    debugV(30, "> last", "track", lastStaff);
    var rests = [];

    cursor.rewind(Cursor.SELECTION_START);
    var segment = cursor.segment;
    while (segment && (segment.tick < lastTick)) {
        for (var track = firstStaff; track <= lastStaff; track++) {
            var element;
            element = segment.elementAt(track);
            if (element && ((element.type == Element.REST) || (element.type == Element.CHORD))) {
				debugSegment(segment, track);

                if (element.type == Element.CHORD) {
                    // extracting the notes from the chord
                    var nn = element.notes;
                    for (var i = 0; i < nn.length; i++) {
                        var note = nn[i];
                        rests.push(note);
                        if (oneNoteBySegment)
                            break;
                    }

                } else {
                    rests.push(element);
                }
            }
        }
        // cursor.next();
        // segment = cursor.segment;
        segment = segment.next; // 18/6/22 : looping thru all segments, and only defined at the curso level (which is bound to track)
    }

    return rests;
}

/**
 * Get all the selected segments based on the cursor.
 * Rem: This does not return any result in case of the notes are selected inidvidually.
 * @return Segment[] : each returned {@link Note} has
 *      - element.type==Element.SEGMENT
 *
 */
function getSegmentsFromCursor(score) {
    if (!score) score=curScore;
	if (score==null) return [];
    var cursor = score.newCursor();
        
    cursor.rewind(Cursor.SELECTION_END);
    var lastTick = cursor.tick;
    cursor.rewind(Cursor.SELECTION_START);
    var firstTick = cursor.tick;
    debugV(30, "> first", "tick", firstTick);
    debugV(30, "> last", "tick", lastTick);
    var segment = cursor.segment;
    debugV(30, "> starting at", "tick", (segment) ? segment.tick : "NO SEGMENT");
    var segments = [];
    var s = 0;
    while (segment && (segment.tick < lastTick)) {
        segments[s++] = segment;
        // cursor.next();
        // segment = cursor.segment;
        segment = segment.next; // 18/6/22 : looping thru all segments, and only defined at the curso level (which is bound to track)
    }

    return segments;
}

function getChordsRestsFromScore(score) {
    if (!score) score=curScore;
	if (score==null) return [];
    var cursor = score.newCursor();
        
    var firstTick,
    firstStaff,
    lastTick,
    lastStaff;
    // start
    cursor.rewind(0);
    firstTick = cursor.tick;
    firstStaff = cursor.track;
    // end
    lastTick = score.lastSegment.tick + 1;
	lastStaff= score.ntracks;
    console.log("getChordsRestsFromScore ** ");
    debugV(30, "> first", "tick", firstTick);
    debugV(30, "> first", "track", firstStaff);
    debugV(30, "> last", "tick", lastTick);
    debugV(30, "> last", "track", lastStaff);
    var chords = [];

    cursor.rewind(0);
    var segment = cursor.segment;
    while (segment) {
        for (var track = firstStaff; track <= lastStaff; track++) {
            var element;
            element = segment.elementAt(track);
            if (element && (element.type == Element.CHORD || element.type == Element.REST)) {
				debugSegment(segment, track);
                chords[chords.length] = element;
            }

        }
        // cursor.next();
        // segment = cursor.segment;
        segment = segment.next; // 18/6/22 : looping thru all segments, and only defined at the curso level (which is bound to track)
    }

    return chords;
}

// -----------------------------------------------------------------------
// --- Local Copy/Paste -----------------------------------------
// -----------------------------------------------------------------------
/**
 * Copy segment by segment, track by track, the CHORDREST found a this segment.
 * Includes the annotations at this segment, as well as the notes and their properties
 */
function copySelection(chords) {
    logThis("Copying " + chords.length + " elements canidates");
    var targets = [];
    loopelements:
    for (var i = 0; i < chords.length; i++) {
        var current = chords[i];

        if (current.type === Element.NOTE) {
            logThis("!! note element in the selection. Using its parent's chord instead");
            current = current.parent;

            console.log("checking if the parent's chord has already been added in %1 elemnts".arg(targets.length));
            for (var c = 0; c < targets.length; c++) {
                var prev = targets[c];
                // 28/2/2023: Missing note
                // if ((prev.tick === current.parent.tick) && (prev.track === current.track)) {
                console.log("- Comparing %1/%2 vs. %3 at %4/%5".arg(current.parent.tick).arg(current.track).arg(prev.userName()).arg(prev.tick).arg(prev.track));
                console.log("  - type : %1 vs. Element.CHORD: %2".arg(prev.type).arg(Element.CHORD));
                if ((prev.type === Element.CHORD) && (prev.tick === current.parent.tick) && (prev.track === current.track)) {
                    logThis("dropping this note, because we have already added its parent's chord in the selection");
                    continue loopelements;
                }
            }
            logThis("Note found. Adding its parent's chord because this chord is not not been added");
        }

        logThis("Copying " + i + ": " + current.userName() + " - " + (current.duration ? current.duration.str : "null") + ", notes: " + (current.notes ? current.notes.length : 0));
        var target = {
            "_element": current,
            "type": current.type,
            "tick": current.parent.tick,
            "track": current.track,
            "duration": (current.duration ? {
                "numerator": current.duration.numerator,
                "denominator": current.duration.denominator,
            }
                 : null),
            "lyrics": current.lyrics,
            "graceNotes": current.graceNotes,
            "notes": undefined,
            "annotations": [],
            "_username": current.userName(),
            "userName": function () {
                return this._username;
            }
        };

        // If CHORD, then remember the notes. Otherwise treat as a rest
        if (current.type === Element.CHORD) {
            // target.notes = current.notes; // 26/2/23 current.notes n'est pas une Array donc c'est un peu chiant
            target.notes = [];
            for (var n = 0; n < current.notes.length; n++) {
                target.notes.push(current.notes[n]);
            }
        };

        // Searching for harmonies & other annotations
        var seg = current;
        while (seg && seg.type !== Element.SEGMENT) {
            seg = seg.parent
        }

        if (seg !== null) {
            var annotations = seg.annotations;
            //console.log(annotations.length + " annotations");
            if (annotations && (annotations.length > 0)) {
                var filtered = [];
                // annotations=annotations.filter(function(e) {
                // return (e.type === Element.HARMONY) && (e.track===current.track);
                // });
                for (var h = 0; h < annotations.length; h++) {
                    var e = annotations[h];
                    if (/*(e.type === Element.HARMONY) &&*/(e.track === current.track))
                        filtered.push(e);
                }
                annotations = filtered;
                target.annotations = annotations;
            } else
                annotations = []; // DEBUG
            logThis("--Annotations: " + annotations.length + ((annotations.length > 0) ? (" (\"" + annotations[0].text + "\")") : ""));
        }
        // Done
        targets.push(target);
        // logThis("--Lyrics: " + target.lyrics.length + ((target.lyrics.length > 0) ? (" (\"" + target.lyrics[0].text + "\")") : ""));
    }

    logThis("Ending was a copy of " + targets.length + " elements");

    return targets;

}

function pasteSelection(cursor, targets) {
    // startCmd(curScore, "pasteSelection"); // Non, on a déjà un startCmd dans restToChord
    logThis("Pasting "+targets.length+" elements at "+cursor.tick+"/"+cursor.track);
    for (var i = 0; i < targets.length; i++) {
        var target = targets[i];

        //var target = targets[i]._element; // TEST - DIRECTEMENT UTILISER LES NOTES MEMEORISEES --> KO (du moins sur les durées)
        var tick = cursor.tick;
        
        logThis("Pasting " + i + ": " + target.userName() + " - "+ target.duration.numerator + "/" + target.duration.denominator + ", notes: " + (target.notes ? target.notes.length : 0));

        // element level
        if (target.notes && target.notes.length > 0) {
            var pitches = [];
            for (var j = 0; j < target.notes.length; j++) {
                // pitches.push(target.notes[j].pitch);
                var n = {
                    "pitch": target.notes[j].pitch,
                    "tpc1": target.notes[j].tpc1,
                    "tpc2": target.notes[j].tpc2
                };
                pitches.push(n);
            }
            startCmd(curScore, "restToChord");
            logThis("- pasting the notes");
            NoteHelper.restToChord(cursor.element, pitches, true); // with keepRestDuration=true
            endCmd(curScore, "restToChord");
        }

        logThis("- adapting duration");
        // startCmd(curScore, "adapt duration"); //DEBUG
        cursor.rewindToTick(tick);
        // w/a setting to a duration < what we need, in order to be sure the duration will change 
        // (e.g. changing from 1/4 to 1/4 when the rest is not visible) won't make it appear. We need to do 1/4 -> (something else) -> 1/4
        cursorToDuration(cursor, durationTo64(target.duration)/2);
        cursorToDuration(cursor, durationTo64(target.duration));
        
        if ((target.lyrics && target.lyrics.length > 0) || (target.annotations && target.annotations.length > 0)) {
            var current = cursor.element;
            // debugO("Target", target,["lyrics","notes"],true);
            // lyrics
            startCmd(curScore, "adding the texts");
            logThis("- adding the lyrics: " + target.lyrics.length + " on " + current.userName());
            if (target.lyrics) {
                for (var j = 0; j < target.lyrics.length; j++) {
                    var lorig = target.lyrics[j];
                    logThis("-- adding a lyric: \"" + lorig.text + "\"");
                    // current.add(lorig); // no error but the lyric is not to be seen
                    var lnew = newElement(Element.LYRICS);
                    lnew.text = lorig.text;
                    current.add(lnew);
                }
            }

            // annotations
            logThis("- adding the annotations: " + target.annotations.length + " on " + current.userName());
            if (target.annotations) {
                for (var j = 0; j < target.annotations.length; j++) {
                    var lorig = target.annotations[j];
                    logThis("-- adding a " + lorig.userName() + ": \"" + lorig.text + "\"");
                    // current.add(lorig); // no error but the lyric is not to be seen
                    var lnew = newElement(lorig.type);
                    lnew.text = lorig.text;
                    cursor.add(lnew);
                    
                    // removing the former copied element
                    removeElement(lorig);
                }
            }
            endCmd(curScore, "adding the texts");
        }
        cursor.rewindToTick(tick);
        
        // Moving to next segment 
        moveNext(cursor); 
    }
    //endCmd(curScore, "pasteSelection");

}




// -----------------------------------------------------------------------
// --- Debug -----------------------------------------
// -----------------------------------------------------------------------

function debugV(level, label, prop, value) {
    console.log(label + " " + prop + ":" + value);
}

function debugSegment(segment, track, label) {
    var el = (segment !== null) ? segment.elementAt(track) : null;
    console.log((label ? (label + " ") : "") + "segment (" + ((segment !== null) ? segment.tick : "null") + ") =" +
        ((segment !== null) ? segment.segmentType : "null") +
        " (with " + ((el !== null) ? el.userName() : "null") +
        " on track " + track + ")");
}
