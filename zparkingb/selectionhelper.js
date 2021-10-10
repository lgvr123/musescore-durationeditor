/**********************
/* Parking B - MuseScore - Selection helper
/* v1.0.0
/* v1.2.0 28/9/21 getChordsRestsFromCursor
/* v1.2.1 2/10/21 corrected name of checktVersion
/**********************************************/

// -----------------------------------------------------------------------
// --- Vesionning-----------------------------------------
// -----------------------------------------------------------------------

function checktVersion(expected) {
    return checkVersion(expected);
}
function checkVersion(expected) {
    var version = "1.2.1";

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
function getNotesFromSelection() {
    var selection = curScore.selection;
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
function getRestsFromSelection() {
    var selection = curScore.selection;
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
function getNotesRestsFromSelection() {
    var selection = curScore.selection;
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
function getChordsFromSelection() {
    var notes = getNotesFromSelection();
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
function getChordsRestsFromSelection() {
    var notes = getNotesRestsFromSelection();

    var chords = [];
    var prevChord;
    for (var i = 0; i < notes.length; i++) {
        var element = notes[i];

        if (element.type === Element.REST) {
            chords.push(element);
            prevChord = undefined;
        } else if (element.type === Element.NOTE) {
            var chord = element.parent;
            if (!prevChord || (prevChord !== chord)) {
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
function getSegmentsFromSelection() {
    // Les segments sur base des notes et accords
    var chords = getChordsRestsFromSelection();
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
function getFingeringsFromSelection() {
    var selection = curScore.selection;
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
function getNotesFromCursor(oneNoteBySegment) {
    var chords = getChordsFromCursor();
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
function getChordsFromCursor() {
    var score = curScore;
    var cursor = curScore.newCursor()
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
        lastTick = curScore.lastSegment.tick + 1;
    }
    lastStaff = cursor.track;
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
                debugV(40, "- segment -", "tick", segment.tick);
                debugV(40, "- segment -", "segmentType", segment.segmentType);
                debugV(40, "--element", "label", (element) ? element.name : "null");
                chords[chords.length] = element;
            }
        }
        cursor.next();
        segment = cursor.segment;
    }

    return chords;
}

function getChordsRestsFromCursor() {
    var score = curScore;
    var cursor = curScore.newCursor()
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
        lastTick = curScore.lastSegment.tick + 1;
    }
    lastStaff = cursor.track;
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
                debugV(40, "- segment -", "tick", segment.tick);
                debugV(40, "- segment -", "segmentType", segment.segmentType);
                debugV(40, "--element", "label", (element) ? element.name : "null");
                chords[chords.length] = element;
            }

        }
        cursor.next();
        segment = cursor.segment;
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
function getRestsFromCursor() {
    var score = curScore;
    var cursor = curScore.newCursor()
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
        lastTick = curScore.lastSegment.tick + 1;
    }
    lastStaff = cursor.track;
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
                debugV(40, "- segment -", "tick", segment.tick);
                debugV(40, "- segment -", "segmentType", segment.segmentType);
                debugV(40, "--element", "label", (element) ? element.name : "null");
                rests.push(element);
            }
        }
        cursor.next();
        segment = cursor.segment;
    }

    return rests;
}

function getChordsFromCursor() {
    var score = curScore;
    var cursor = curScore.newCursor()
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
        lastTick = curScore.lastSegment.tick + 1;
    }
    lastStaff = cursor.track;
    debugV(30, "> first", "tick", firstTick);
    debugV(30, "> first", "track", firstStaff);
    debugV(30, "> last", "tick", lastTick);
    debugV(30, "> last", "track", lastStaff);
    var chords = [];
    for (var track = firstStaff; track <= lastStaff; track++) {

        cursor.rewind(Cursor.SELECTION_START);
        var segment = cursor.segment;
        while (segment && (segment.tick < lastTick)) {
            var element;
            element = segment.elementAt(track);
            if (element && element.type == Element.CHORD) {
                debugV(40, "- segment -", "tick", segment.tick);
                debugV(40, "- segment -", "segmentType", segment.segmentType);
                debugV(40, "--element", "label", (element) ? element.name : "null");
                chords[chords.length] = element;
            }

            cursor.next();
            segment = cursor.segment;
        }
    }

    return chords;
}

/**
 * Get all the selected notes and rests based on the cursor.
 * Rem: This does not return any result in case of the rests and notes are selected inidvidually.
 * @param oneNoteBySegment : boolean. If true, only one note by segment will be returned.
 * @return Rest[] : each returned {@link Note} has the following properties:
 *      - element.type==Element.REST or Element.NOTE
 *
 */
function getNotesRestsFromCursor(oneNoteBySegment) {
    var score = curScore;
    var cursor = curScore.newCursor()
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
        lastTick = curScore.lastSegment.tick + 1;
    }
    lastStaff = cursor.track;
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
                debugV(40, "- segment -", "tick", segment.tick);
                debugV(40, "- segment -", "segmentType", segment.segmentType);
                debugV(40, "--element", "label", (element) ? element.name : "null");

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
        cursor.next();
        segment = cursor.segment;
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
function getSegmentsFromCursor() {
    var score = curScore;
    var cursor = curScore.newCursor()
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
        cursor.next();
        segment = cursor.segment;
    }

    return segments;
}

function getChordsRestsFromScore() {
    var score = curScore;
    var cursor = curScore.newCursor()
        var firstTick,
    firstStaff,
    lastTick,
    lastStaff;
    // start
    cursor.rewind(0);
    firstTick = cursor.tick;
    firstStaff = cursor.track;
    // end
    cursor.rewind(Cursor.SELECTION_END);
    lastTick = cursor.tick;
    if (lastTick == 0) { // dealing with some bug when selecting to end.
        lastTick = curScore.lastSegment.tick + 1;
    }
    lastStaff = cursor.track;
    debugV(30, "> first", "tick", firstTick);
    debugV(30, "> first", "track", firstStaff);
    var chords = [];

    cursor.rewind(Cursor.SELECTION_START);
    var segment = cursor.segment;
    while (segment) {
        for (var track = firstStaff; track <= lastStaff; track++) {
            var element;
            element = segment.elementAt(track);
            if (element && (element.type == Element.CHORD || element.type == Element.REST)) {
                debugV(40, "- segment -", "tick", segment.tick);
                debugV(40, "- segment -", "segmentType", segment.segmentType);
                debugV(40, "--element", "label", (element) ? element.name : "null");
                chords[chords.length] = element;
            }

        }
        cursor.next();
        segment = cursor.segment;
    }

    return chords;
}


function debugV(level, label, prop, value) {
    console.log(label + " " + prop + ":" + value);
}
