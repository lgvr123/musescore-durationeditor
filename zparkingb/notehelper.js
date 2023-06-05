/**********************
/* Parking B - MuseScore - Note helper
/*
/* Rem: Notes heads and Accidentals representation requires the use of the font 'Bravura Text'
/* 
/* ChangeLog:
/* 	- 22/7/21: Added restToNote and changeNote function
/*  - 25/7/21: Managing of transposing instruments
/*	- 5/9/21: v1.0.2 Improved support for transpositing instruments.
/*	- 13/03/22: v1.0.4 Extra parameter to keep the rest duration when adding notes and chords.
/*	- 13/03/22: v1.0.4 New restToChords function.
/*	- 18/03/22: v1.0.5 restToNote and New restToChords accept now tpc1 and tpc2 values.
/*  - 15/2/23: v2.0.0 using unicode for accidentals and heads instead of images
/*  - 26/2/23: v2.0.1 protection of methods
/*  - 26/2/23: v2.0.1 documentation
/*  - 5/3/23: v2.0.2 correct length across bars
/*  - 6/3/23: v2.0.2 some refactoring and documentation
/*  - 15/3/23: v2.0.2 changeNote: set the pitch note (I guess I assumed it was already set by the calling function, but this is more generic now).
/**********************************************/
// -----------------------------------------------------------------------
// --- Vesionning-----------------------------------------
// -----------------------------------------------------------------------

function checktVersion(expected) {
    return checkVersion(expected);
}
function checkVersion(expected) {
    var version = "2.0.2";

    var aV = version.split('.').map(function (v) {
        return parseInt(v);
    });
    var aE = (expected && (expected != null)) ? expected.split('.').map(function (v) {
        return parseInt(v);
    }) : [99];
    if (aE.length == 0)
        aE = [99];

    for (var i = 0; (i < aV.length) && (i < aE.length); i++) {
        if (!(aV[i] >= aE[i]))
            return false;
    }

    return true;
}
// -----------------------------------------------------------------------
// --- Processing-----------------------------------------
// -----------------------------------------------------------------------
/**
 * Add some propeprties to the note. Among others, the name of the note, in the format "C4" and "C#4", ...
 * The added properties:
 * - note.accidentalName : the name of the accidental
 * - note.accidentalText : the unicode representation of the accidental character
 * - note.headName = the name of the head;
 * - note.headText = the unicode representation of the head character;
 * - note.extname.fullname : "C#4"
 * - note.extname.name : "C4"
 * - note.extname.raw : "C"
 * - note.extname.octave : "4"
 * @param note The note to be enriched
 * @return /
 */
function enrichNote(note) {
    if(!note) { 
        console.warn("enrichNote: null arguments");
        return;
    }

    if (note.type != Element.NOTE) {
        console.warn("enrichNote: invalid note type. Expecting 'Note'. Received "+note.userName());
        return;
    }
    
    // accidental
    var id = note.accidentalType;
    console.log("SEARCHING FOR ACCIDENTAL TYPE = "+id);
    note.accidentalName = "UNKOWN";
    for (var i = 0; i < accidentals.length; i++) {
        var acc = accidentals[i];
        var val=eval("Accidental." + acc.name);
        console.log("checking "+acc.name + " = "+val +" ("+acc.text+")");
        if (id == val) {
            
            note.accidentalName = acc.name;
            note.accidentalText = acc.text;
            console.log("FOUND "+acc.name+", text: "+acc.text);
            break;
        }
    }

    // head
    var grp = note.headGroup ? note.headGroup : 0;
    note.headName = heads[0].name;
    note.headText = heads[0].text;
    for (var i = 1; i < heads.length; i++) { // starting at 1 because 0 is the generic one ("--")
        var head = heads[i];
        if (grp == eval("NoteHeadGroup." + head.name)) {
            note.headName = head.name;
            note.headText = head.text;
            break;
        }
    }

    // note name and octave
    var pitch = note.pitch;
    var tpitch = pitch + note.tpc2 - note.tpc1; // note displayed as if it has that pitch
    note.extname = pitchToName(tpitch, note.tpc2);
    note.pitchname = pitchToName(pitch, note.tpc1);
    return;

}

function pitchToName(npitch, ntpc) {
    var tpc = {
        'tpc': 14,
        'name': '?',
        'raw': '?',
        'pitch': 0,
    };

    var pitchnote = pitchnotes[npitch % 12];
    var noteOctave = Math.floor(npitch / 12) - 1;
    
    for (var i = 0; i < tpcs.length; i++) {
        var t = tpcs[i];
        if (ntpc == t.tpc) {
            tpc = t;
            break;
        }
    }

    if ((pitchnote == "A" || pitchnote == "B") && tpc.raw == "C") {
        noteOctave++;
    } else if (pitchnote == "C" && tpc.raw == "B") {
        noteOctave--;
    }

    return {
        "fullname": tpc.name + noteOctave,
        "name": tpc.raw + noteOctave,
        "raw": tpc.raw,
        "octave": noteOctave
    };

}

/**
 * Reconstructed a note pitch information based on the note name and its accidental
 * @param noteName the name of the note, without alteration. Eg "C4", and not "C#4"
 * @param accidental the <b>name</b> of the accidental to use. Eg "SHARP2"
 * @return a structure with pitch/tpc information
ret.pitch : the pitch of the note
ret.tpc: the value for the note tpc1 and tpc2
 */
function buildPitchedNote(noteName, accidental) {

    if(!noteName)  { 
        console.warn("buildPitchedNote: null arguments");
        return;
    }

    var name = noteName.substr(0, 1);
    var octave = parseInt(noteName.substr(1, 3));

    var a = accidental;
    
    if (!accidental || accidental=="") {
        a="NONE";
    } else {        
        for (var i = 0; i < equivalences.length; i++) {
            for (var j = 1; j < equivalences[i].length; j++) {
                if (accidental == equivalences[i][j]) {
                    a = equivalences[i][0];
                    break;
                }
            }
        }
    }

    // tpc
    var tpc = {
        'tpc': -1,
        'pitch': 0
    };
    for (var i = 0; i < tpcs.length; i++) {
        var t = tpcs[i];
        if (name == t.raw && a == t.accidental) {
            //console.log("found with "+t.name);
            tpc = t;
            break;
        }
    }

    if (tpc.tpc == -1) {
        // not found. it means that we have an "exotic" accidental
        for (var i = 0; i < tpcs.length; i++) {
            var t = tpcs[i];
            if (name == t.raw && 'NONE' == t.accidental) {
                //console.log("found with "+t.name + ' NONE');
                tpc = t;
                break;
            }
        }
    }

    if (tpc.tpc == -1) {
        // not found. Shouldn't occur
        tpc.tpc = 0;
    }

    // pitch
    //console.log("--" + tpc.pitch + "--");
    var pitch = (octave + 1) * 12 + ((tpc.pitch !== undefined) ? tpc.pitch : 0);

    var recompose = {
        "pitch": pitch,
        // we store the note as a label ("C4"), we want that note to *look* like a "C4" more than to *sound* like "C4".
        // ==> we force the representation mode by specifying tpc1 to undefined and specifying tpc2
        //"tpc1" : tpc.tpc,
        "tpc2": tpc.tpc
    };

    return recompose;
}

/**
 * Transform a rest into a single note.
 * @param rest: an element of type Element.REST to transform into a note
 * @param toNote: a note definition: int|note definition
 * * int: a pitch
 * * note definition: @see #changeNote 
 * @param keepRestDuration: duration|boolean|undefined 
 * * duration: on the form of duration.numerator, duration.denominator : the duration to force
 * * boolean==true: keep the rest duration
 * * boolean==false | undefined: the duration will be quarter
 *
 * @return an element of type Element.NOTE created on that rest
 * IMPORTANT REMARK: the returned element can be on the same segment's tick than the rest element or *after*
 * if the the requested duration for the note was larger than the available duration in the measure.
 * In that case, the function creates tied notes. The returned element is the last of those tied notes.
*/
function restToNote(rest, toNote, keepRestDuration) {
    if(!rest || !toNote)  { 
        console.warn("restToNote: null arguments");
        return;
    }

    if (rest.type != Element.REST) {
        console.warn("restToNote: invalid note type. Expecting 'Rest'. Received "+rest.userName());
        return;
    }

    var duration;

    var notes=[];
    notes.push((toNote === parseInt(toNote))?
        {
            "pitch": toNote,
            "concertPitch": false,
            "sharp_mode": true
        }:toNote);
        
    
    var chord=restToChord(rest, notes, keepRestDuration);
    
    if(chord.notes && chord.notes.length>0) return chord.notes[0];
    else return undefined;

}

/**
 * Transform a rest into a serie of notes (i.e. a chord).
 * @param rest: an element of type Element.REST to transform into a note
 * @param toNotes: an array of note definitions, defined by : int|note definition
 * * int: a pitch
 * * note definition: @see #changeNote 
 * @param keepRestDuration: duration|boolean|undefined 
 * * duration: on the form of duration.numerator, duration.denominator : the duration to force
 * * boolean==true: keep the rest duration
 * * boolean==false | undefined: the duration will be quarter
 *
 * @return an element of type Element.CHORD created on that rest 
 * IMPORTANT REMARK: the returned element can be on the same segment's tick than the rest element or *after*
 * if the the requested duration for the chord was larger than the available duration in the measure.
 * In that case, the function creates tied chords. The returned element is the last of those tied chords.
 */
function restToChord(rest, toNotes, keepRestDuration) {
    // checks
    if(!rest || !toNotes)  { 
        console.warn("restToChord: null arguments");
        return;
    }

    if (rest.type != Element.REST) {
        console.warn("restToChord: invalid note type. Expecting 'Rest'. Received "+rest.userName());
        return;
    }

    // notes to add
    var notes = toNotes.map(function (n) {
        if (n === parseInt(n)) {
            return {
                "pitch": n,
                "concertPitch": false,
                "sharp_mode": true
            };
        } else {
            return n;
        }
    });
    
    // duration to use
    var duration=undefined;
    if (typeof keepRestDuration === 'undefined') {
        console.log("keepRestDuration=undefined");
        duration = undefined;
    }
    else if (typeof keepRestDuration === 'boolean') {
        console.log("keepRestDuration=boolean: "+keepRestDuration);
        if (keepRestDuration) {
            duration = rest.duration;
        }

    } else {
        console.log("keepRestDuration provided. Using "+keepRestDuration);
        duration = keepRestDuration;
    }

    if (!duration) {
        duration=fraction(1,4);
        console.log("keepRestDuration undefined. Forcing a value");
    }
    console.log("Ending up with duration = "+(duration.str?duration.str:duration));
    
    // Adding the first note
    var toNote=toNotes[0];
    //console.log("==ON A REST==");
    var cur_time = rest.parent.tick; // getting rest's segment's tick
    var oCursor = curScore.newCursor();
    oCursor.track = rest.track;

    oCursor.setDuration(duration.numerator, duration.denominator);
    oCursor.rewindToTick(cur_time);
    oCursor.addNote(toNote.pitch);
    oCursor.rewindToTick(cur_time);
    
    var chord = oCursor.element;
    var note = chord.notes[0];

    console.log("Expected duration: %1, current duration %2".arg(duration?duration.str:"??").arg(chord.duration?chord.duration.str:"??"));

    changeNote(note, toNote);

   
    // adding the other notes
    for (var i = 1; i < notes.length; i++) {
        var dest = notes[i];
        //console.log("Dealing with note "+i+": "+dest.pitch);
        var cur_time = rest.parent.tick; // getting rest's segment's tick
        oCursor.rewindToTick(cur_time);
        oCursor.addNote(dest.pitch, true); // addToChord=true
        oCursor.rewindToTick(cur_time);
        var chord = oCursor.element;
        console.log(">>" + ((chord !== null) ? chord.userName() : "null") + " (" + ((chord !== null) ? chord.notes.length : "/") + ")");
        var note = chord.notes[i];

        //debugPitch(level_DEBUG,"Added note",note);

        NoteHelper.changeNote(note, dest);
    }

    var remaining=durationTo64(duration)-durationTo64(chord.duration);
    console.log("- expected: %1, actual: %2, remaining: %3".arg(durationTo64(duration)).arg(durationTo64(chord.duration)).arg(remaining));
    
    var success=true;
    while(success && remaining > 0) {
        var durG=fraction(remaining,64).str;
        success=oCursor.next();
        if(!success) {
            console.warn("Unable to move to the next element while searching for the remaining %1 duration".arg(durG));
            break;
        }
        var element = oCursor.element;
        if (element.type!=Element.CHORD)  {
            console.warn("Could not find a valid Element.CHORD element while searching for the remaining %1 duration (found %2)".arg(durG).arg(element.userName()));
            break;
        }
        chord=element;
        cur_time = oCursor.tick;
        remaining=remaining-durationTo64(chord.duration);
        console.log("- expected: %1, last: %2, remaining: %3".arg(durationTo64(duration)).arg(durationTo64(chord.duration)).arg(remaining));
        }

    return chord;
}

/**
 * @param toNote.pitch: the target pitch,
 * 
 * @param toNote.tpc1, toNote.tpc2 -- OR -- toNote.concertPitch, toNote.sharp_mode
 * * toNote.tpc1, toNote.tpc2 : the target tpc, if known beforehand
 * * toNote.concertPitch: true|false, false means the note must be dispalyed as having that pitch.
 * For a Bb instrument, a pitch=60 (C), with concertPitch=false will be displayed as a C but be played as Bb.
 * With concertPitch=true, it will be played as a C and therefor displayed as a D.
 * * toNote.sharp_mode: true|false The preference goes to sharp accidentals (true) or flat accidentals (false)
 */
function changeNote(note, toNote) {
    if(!note || !toNote) { 
        console.warn("changeNote: null arguments");
        return;
    }

    if (note.type != Element.NOTE) {
        console.warn("changeNote: invalid note type. Expecting 'Note'. Received "+note.userName());
        return;
    }
    
    note.pitch=toNote.pitch;

    if (toNote.tpc1 !== undefined && toNote.tpc1 !== undefined) {
		// tpc1 and tpc2 are defined ==> using them
        note.tpc1 = toNote.tpc1;
        note.tpc2 = toNote.tpc2;

    } else {
		// tpc1 and tpc2 are not defined ==> computing them

        var sharp_mode = (toNote.sharp_mode) ? true : false;
        var concertPitch = (toNote.concertPitch) ? true : false;

        //console.log("default is pitch: " + note.pitch + ", tpc: " + note.tpc1 + "/" + note.tpc2 + "/" + note.tpc);
        //console.log("requested is pitch: " + ((toNote.pitch === undefined) ? "undefined" : toNote.pitch) +
        //    ", tpc: " + ((toNote.tpc1 === undefined) ? "undefined" : toNote.tpc1) + "/" + ((toNote.tpc2 === undefined) ? "undefined" : toNote.tpc2));

        if (!concertPitch) {
            // We need to align the pitch, beacause the specified pitched is the score pitch and non the concert pitch²
            var dtpc = note.tpc2 - note.tpc1;
            var dpitch = deltaTpcToPitch(note.tpc1, note.tpc2);

            note.pitch += dpitch;

            // basic approach. This will be correct but not all the time nice
            note.tpc1 -= dtpc;
            note.tpc2 -= dtpc;

        }

        var tpc = getPreferredTpc(note.tpc1, sharp_mode);
        if (tpc !== null)
            note.tpc1 = tpc;

        //delta = toNote.pitch - 60;
        var tpc = getPreferredTpc(note.tpc2, sharp_mode);
        if (tpc !== null)
            note.tpc2 = tpc;

    }

    //console.log("After is pitch: " + note.pitch + ", tpc: " + note.tpc1 + "/" + note.tpc2 + "/" + note.tpc);

    return note;

}

function getPreferredTpc(tpc, sharp_mode) {
    var delta = tpcToPitch(tpc);

    var tpcs = (sharp_mode) ? sharpTpcs : flatTpcs;

    for (var t = 0; t < tpcs.length; t++) {
        if (tpcs[t].pitch == delta) {
            return tpcs[t].tpc;
            break;
        }
    }

    return null;

}

var pitchnotes = ['C', 'C', 'D', 'D', 'E', 'F', 'F', 'G', 'G', 'A', 'A', 'B'];

var tpcs = [new tpcClass(-1, 'F♭♭'),
    new tpcClass(0, 'C♭♭'),
    new tpcClass(1, 'G♭♭'),
    new tpcClass(2, 'D♭♭'),
    new tpcClass(3, 'A♭♭'),
    new tpcClass(4, 'E♭♭'),
    new tpcClass(5, 'B♭♭'),
    new tpcClass(6, 'F♭'),
    new tpcClass(7, 'C♭'),
    new tpcClass(8, 'G♭'),
    new tpcClass(9, 'D♭'),
    new tpcClass(10, 'A♭'),
    new tpcClass(11, 'E♭'),
    new tpcClass(12, 'B♭'),
    new tpcClass(13, 'F'),
    new tpcClass(14, 'C'),
    new tpcClass(15, 'G'),
    new tpcClass(16, 'D'),
    new tpcClass(17, 'A'),
    new tpcClass(18, 'E'),
    new tpcClass(19, 'B'),
    new tpcClass(20, 'F♯'),
    new tpcClass(21, 'C♯'),
    new tpcClass(22, 'G♯'),
    new tpcClass(23, 'D♯'),
    new tpcClass(24, 'A♯'),
    new tpcClass(25, 'E♯'),
    new tpcClass(26, 'B♯'),
    new tpcClass(27, 'F♯♯'),
    new tpcClass(28, 'C♯♯'),
    new tpcClass(29, 'G♯♯'),
    new tpcClass(30, 'D♯♯'),
    new tpcClass(31, 'A♯♯'),
    new tpcClass(32, 'E♯♯'),
    new tpcClass(33, 'B♯♯'),
];

function filterTpcs(sharp_mode) {

    var accidentals = sharp_mode ? ['NONE', 'SHARP', 'SHARP2'] : ['NONE', 'FLAT', 'FLAT2'];
    var preferredTpcs;

    // On ne garde que les tpcs correspondant au type d'accord et trié par type d'altération
    var preferredTpcs = tpcs.filter(function (e) {
        return accidentals.indexOf(e.accidental) >= 0;
    });

    preferredTpcs = preferredTpcs.sort(function (a, b) {
        var acca = accidentals.indexOf(a.accidental);
        var accb = accidentals.indexOf(b.accidental);
        if (acca != accb)
            return acca - accb;
        return a.pitch - b.pitch;
    });

    for (var i = 0; i < preferredTpcs.length; i++) {
        if (preferredTpcs[i].pitch < 0)
            preferredTpcs[i].pitch += 12;
        //console.log(root + " (" + mode + ") => " + sharp_mode + ": " + preferredTpcs[i].name + "/" + preferredTpcs[i].pitch);
    }

    return preferredTpcs;

}

var sharpTpcs = filterTpcs(true);
var flatTpcs = filterTpcs(false);

var accidentals = [{
        "name": "NONE",
        "text": ''
    }, {
        "name": "FLAT",
        "text": '\uE260'
    }, {
        "name": "NATURAL",
        "text": '\uE261'
    }, {
        "name": "SHARP",
        "text": '\uE262'
    }, {
        "name": "SHARP2",
        "text": '\uE263'
    }, {
        "name": "FLAT2",
        "text": '\uE264'
    }, {
        "name": "SHARP3",
        "text": '\uE265'
    }, {
        "name": "FLAT3",
        "text": '\uE266'
    }, {
        "name": "NATURAL_FLAT",
        "text": '\uE267'
    }, {
        "name": "NATURAL_SHARP",
        "text": '\uE268'
    }, {
        "name": "SHARP_SHARP",
        "text": '\uE269'
    }, {
        "name": "FLAT_ARROW_UP",
        "text": '\uE270'
    }, {
        "name": "FLAT_ARROW_DOWN",
        "text": '\uE271'
    }, {
        "name": "NATURAL_ARROW_UP",
        "text": '\uE272'
    }, {
        "name": "NATURAL_ARROW_DOWN",
        "text": '\uE273'
    }, {
        "name": "SHARP_ARROW_UP",
        "text": '\uE274'
    }, {
        "name": "SHARP_ARROW_DOWN",
        "text": '\uE275'
    }, {
        "name": "SHARP2_ARROW_UP",
        "text": '\uE276'
    }, {
        "name": "SHARP2_ARROW_DOWN",
        "text": '\uE277'
    }, {
        "name": "FLAT2_ARROW_UP",
        "text": '\uE278'
    }, {
        "name": "FLAT2_ARROW_DOWN",
        "text": '\uE279'
    }, {
        "name": "ARROW_DOWN",
        "text": '\uE27B'
    }, {
        "name": "ARROW_UP",
        "text": '\uE27A'
    }, {
        "name": "MIRRORED_FLAT",
        "text": '\uE280'
    }, {
        "name": "MIRRORED_FLAT2",
        "text": '\uE281'
    }, {
        "name": "SHARP_SLASH",
        "text": '\uE282'
    }, {
        "name": "SHARP_SLASH4",
        "text": '\uE283'
    }, {
        "name": "FLAT_SLASH2",
        "text": '\uE440'
    }, {
        "name": "FLAT_SLASH",
        "text": '\uE442'
    }, {
        "name": "SHARP_SLASH3",
        "text": '\uE446'
    }, {
        "name": "SHARP_SLASH2",
        "text": '\uE447'
    }, {
        "name": "DOUBLE_FLAT_ONE_ARROW_DOWN",
        "text": '\uE2C0'
    }, {
        "name": "FLAT_ONE_ARROW_DOWN",
        "text": '\uE2C1'
    }, {
        "name": "NATURAL_ONE_ARROW_DOWN",
        "text": '\uE2C2'
    }, {
        "name": "SHARP_ONE_ARROW_DOWN",
        "text": '\uE2C3'
    }, {
        "name": "DOUBLE_SHARP_ONE_ARROW_DOWN",
        "text": '\uE2C4'
    }, {
        "name": "DOUBLE_FLAT_ONE_ARROW_UP",
        "text": '\uE2C5'
    }, {
        "name": "FLAT_ONE_ARROW_UP",
        "text": '\uE2C6'
    }, {
        "name": "NATURAL_ONE_ARROW_UP",
        "text": '\uE2C7'
    }, {
        "name": "SHARP_ONE_ARROW_UP",
        "text": '\uE2C8'
    }, {
        "name": "DOUBLE_SHARP_ONE_ARROW_UP",
        "text": '\uE2C9'
    }, {
        "name": "DOUBLE_FLAT_TWO_ARROWS_DOWN",
        "text": '\uE2CA'
    }, {
        "name": "FLAT_TWO_ARROWS_DOWN",
        "text": '\uE2CB'
    }, {
        "name": "NATURAL_TWO_ARROWS_DOWN",
        "text": '\uE2CC'
    }, {
        "name": "SHARP_TWO_ARROWS_DOWN",
        "text": '\uE2CD'
    }, {
        "name": "DOUBLE_SHARP_TWO_ARROWS_DOWN",
        "text": '\uE2CE'
    }, {
        "name": "DOUBLE_FLAT_TWO_ARROWS_UP",
        "text": '\uE2CF'
    }, {
        "name": "FLAT_TWO_ARROWS_UP",
        "text": '\uE2D0'
    }, {
        "name": "NATURAL_TWO_ARROWS_UP",
        "text": '\uE2D1'
    }, {
        "name": "SHARP_TWO_ARROWS_UP",
        "text": '\uE2D2'
    }, {
        "name": "DOUBLE_SHARP_TWO_ARROWS_UP",
        "text": '\uE2D3'
    }, {
        "name": "DOUBLE_FLAT_THREE_ARROWS_DOWN",
        "text": '\uE2D4'
    }, {
        "name": "FLAT_THREE_ARROWS_DOWN",
        "text": '\uE2D5'
    }, {
        "name": "NATURAL_THREE_ARROWS_DOWN",
        "text": '\uE2D6'
    }, {
        "name": "SHARP_THREE_ARROWS_DOWN",
        "text": '\uE2D7'
    }, {
        "name": "DOUBLE_SHARP_THREE_ARROWS_DOWN",
        "text": '\uE2D8'
    }, {
        "name": "DOUBLE_FLAT_THREE_ARROWS_UP",
        "text": '\uE2D9'
    }, {
        "name": "FLAT_THREE_ARROWS_UP",
        "text": '\uE2DA'
    }, {
        "name": "NATURAL_THREE_ARROWS_UP",
        "text": '\uE2DB'
    }, {
        "name": "SHARP_THREE_ARROWS_UP",
        "text": '\uE2DC'
    }, {
        "name": "DOUBLE_SHARP_THREE_ARROWS_UP",
        "text": '\uE2DD'
    }, {
        "name": "LOWER_ONE_SEPTIMAL_COMMA",
        "text": '\uE2DE'
    }, {
        "name": "RAISE_ONE_SEPTIMAL_COMMA",
        "text": '\uE2DF'
    }, {
        "name": "LOWER_TWO_SEPTIMAL_COMMAS",
        "text": '\uE2E0'
    }, {
        "name": "RAISE_TWO_SEPTIMAL_COMMAS",
        "text": '\uE2E1'
    }, {
        "name": "LOWER_ONE_UNDECIMAL_QUARTERTONE",
        "text": '\uE2E2'
    }, {
        "name": "RAISE_ONE_UNDECIMAL_QUARTERTONE",
        "text": '\uE2E3'
    }, {
        "name": "LOWER_ONE_TRIDECIMAL_QUARTERTONE",
        "text": '\uE2E4'
    }, {
        "name": "RAISE_ONE_TRIDECIMAL_QUARTERTONE",
        "text": '\uE2E5'
    }, {
        "name": "DOUBLE_FLAT_EQUAL_TEMPERED",
        "text": '\uE2F0'
    }, {
        "name": "FLAT_EQUAL_TEMPERED",
        "text": '\uE2F1'
    }, {
        "name": "NATURAL_EQUAL_TEMPERED",
        "text": '\uE2F2'
    }, {
        "name": "SHARP_EQUAL_TEMPERED",
        "text": '\uE2F3'
    }, {
        "name": "DOUBLE_SHARP_EQUAL_TEMPERED",
        "text": '\uE2F4'
    }, {
        "name": "QUARTER_FLAT_EQUAL_TEMPERED",
        "text": '\uE2F5'
    }, {
        "name": "QUARTER_SHARP_EQUAL_TEMPERED",
        "text": '\uE2F6'
    }, {
        "name": "FLAT_17",
        "text": '\uE2E6'
    }, {
        "name": "SHARP_17",
        "text": '\uE2E7'
    }, {
        "name": "FLAT_19",
        "text": '\uE2E8'
    }, {
        "name": "SHARP_19",
        "text": '\uE2E9'
    }, {
        "name": "FLAT_23",
        "text": '\uE2EA'
    }, {
        "name": "SHARP_23",
        "text": '\uE2EB'
    }, {
        "name": "FLAT_31",
        "text": '\uE2EC'
    }, {
        "name": "SHARP_31",
        "text": '\uE2ED'
    }, {
        "name": "FLAT_53",
        "text": '\uE2F7'
    }, {
        "name": "SHARP_53",
        "text": '\uE2F8'
    }, {
        "name": "//EQUALS_ALMOST",
        "text": '\uE2FA'
    }, {
        "name": "//EQUALS",
        "text": '\uE2FB'
    }, {
        "name": "//TILDE",
        "text": '\uE2F9'
    }, {
        "name": "SORI",
        "text": '\uE461'
    }, {
        "name": "KORON",
        "text": '\uE460'
    }, {
        "name": "TEN_TWELFTH_FLAT",
        "text": '\uE434'
    }, {
        "name": "TEN_TWELFTH_SHARP",
        "text": '\uE429'
    }, {
        "name": "ELEVEN_TWELFTH_FLAT",
        "text": '\uE435'
    }, {
        "name": "ELEVEN_TWELFTH_SHARP",
        "text": '\uE42A'
    }, {
        "name": "ONE_TWELFTH_FLAT",
        "text": '\uE42B'
    }, {
        "name": "ONE_TWELFTH_SHARP",
        "text": '\uE420'
    }, {
        "name": "TWO_TWELFTH_FLAT",
        "text": '\uE42C'
    }, {
        "name": "TWO_TWELFTH_SHARP",
        "text": '\uE421'
    }, {
        "name": "THREE_TWELFTH_FLAT",
        "text": '\uE42D'
    }, {
        "name": "THREE_TWELFTH_SHARP",
        "text": '\uE422'
    }, {
        "name": "FOUR_TWELFTH_FLAT",
        "text": '\uE42E'
    }, {
        "name": "FOUR_TWELFTH_SHARP",
        "text": '\uE423'
    }, {
        "name": "FIVE_TWELFTH_FLAT",
        "text": '\uE42F'
    }, {
        "name": "FIVE_TWELFTH_SHARP",
        "text": '\uE424'
    }, {
        "name": "SIX_TWELFTH_FLAT",
        "text": '\uE430'
    }, {
        "name": "SIX_TWELFTH_SHARP",
        "text": '\uE425'
    }, {
        "name": "SEVEN_TWELFTH_FLAT",
        "text": '\uE431'
    }, {
        "name": "SEVEN_TWELFTH_SHARP",
        "text": '\uE426'
    }, {
        "name": "EIGHT_TWELFTH_FLAT",
        "text": '\uE432'
    }, {
        "name": "EIGHT_TWELFTH_SHARP",
        "text": '\uE427'
    }, {
        "name": "NINE_TWELFTH_FLAT",
        "text": '\uE433'
    }, {
        "name": "NINE_TWELFTH_SHARP",
        "text": '\uE428'
    }, {
        "name": "SAGITTAL_5V7KD",
        "text": '\uE301'
    }, {
        "name": "SAGITTAL_5V7KU",
        "text": '\uE300'
    }, {
        "name": "SAGITTAL_5CD",
        "text": '\uE303'
    }, {
        "name": "SAGITTAL_5CU",
        "text": '\uE302'
    }, {
        "name": "SAGITTAL_7CD",
        "text": '\uE305'
    }, {
        "name": "SAGITTAL_7CU",
        "text": '\uE304'
    }, {
        "name": "SAGITTAL_25SDD",
        "text": '\uE307'
    }, {
        "name": "SAGITTAL_25SDU",
        "text": '\uE306'
    }, {
        "name": "SAGITTAL_35MDD",
        "text": '\uE309'
    }, {
        "name": "SAGITTAL_35MDU",
        "text": '\uE308'
    }, {
        "name": "SAGITTAL_11MDD",
        "text": '\uE30B'
    }, {
        "name": "SAGITTAL_11MDU",
        "text": '\uE30A'
    }, {
        "name": "SAGITTAL_11LDD",
        "text": '\uE30D'
    }, {
        "name": "SAGITTAL_11LDU",
        "text": '\uE30C'
    }, {
        "name": "SAGITTAL_35LDD",
        "text": '\uE30F'
    }, {
        "name": "SAGITTAL_35LDU",
        "text": '\uE30E'
    }, {
        "name": "SAGITTAL_FLAT25SU",
        "text": '\uE311'
    }, {
        "name": "SAGITTAL_SHARP25SD",
        "text": '\uE310'
    }, {
        "name": "SAGITTAL_FLAT7CU",
        "text": '\uE313'
    }, {
        "name": "SAGITTAL_SHARP7CD",
        "text": '\uE312'
    }, {
        "name": "SAGITTAL_FLAT5CU",
        "text": '\uE315'
    }, {
        "name": "SAGITTAL_SHARP5CD",
        "text": '\uE314'
    }, {
        "name": "SAGITTAL_FLAT5V7KU",
        "text": '\uE317'
    }, {
        "name": "SAGITTAL_SHARP5V7KD",
        "text": '\uE316'
    }, {
        "name": "SAGITTAL_FLAT",
        "text": '\uE319'
    }, {
        "name": "SAGITTAL_SHARP",
        "text": '\uE318'
    }, {
        "name": "ONE_COMMA_FLAT",
        "text": '\uE454'
    }, {
        "name": "ONE_COMMA_SHARP",
        "text": '\uE450'
    }, {
        "name": "TWO_COMMA_FLAT",
        "text": '\uE455'
    }, {
        "name": "TWO_COMMA_SHARP",
        "text": '\uE451'
    }, {
        "name": "THREE_COMMA_FLAT",
        "text": '\uE456'
    }, {
        "name": "THREE_COMMA_SHARP",
        "text": '\uE452'
    }, {
        "name": "FOUR_COMMA_FLAT",
        "text": '\uE457'
    }, {
        "name": "//FOUR_COMMA_SHARP",
        "text": '\uE262'
    }, {
        "name": "FIVE_COMMA_SHARP",
        "text": '\uE453'
    }
]

var equivalences = [
    ['SHARP', 'NATURAL_SHARP'],
    ['FLAT', 'NATURAL_FLAT'],
    ['NONE', 'NATURAL'],
    ['SHARP2', 'SHARP_SHARP']
];

function isEquivAccidental(a1, a2) {
    for (var i = 0; i < equivalences.length; i++) {
        if ((equivalences[i][0] === a1 && equivalences[i][1] === a2) ||
            (equivalences[i][0] === a2 && equivalences[i][1] === a1))
            return true;
    }
    return false;
}

var heads = [{
            'name': 'HEAD_NORMAL',
            'text': '\uE0a3'
        }, {
            'name': 'HEAD_CROSS',
            'text': '\uE0a7'
        }, {
            'name': 'HEAD_PLUS',
            'text': '\uE0ad'
        }, {
            'name': 'HEAD_XCIRCLE',
            'text': '\uE0b3'
        }, {
            'name': 'HEAD_WITHX',
            'text': '\uE0b7'
        }, {
            'name': 'HEAD_TRIANGLE_UP',
            'text': '\uE0bd'
        }, {
            'name': 'HEAD_TRIANGLE_DOWN',
            'text': '\uE0c6'
        }, {
            'name': 'HEAD_SLASHED1',
            'text': '\uE0d1'
        }, {
            'name': 'HEAD_SLASHED2',
            'text': '\uE0d2'
        }, {
            'name': 'HEAD_DIAMOND',
            'text': '\uE0de'
        }, {
            'name': 'HEAD_DIAMOND_OLD',
            'text': '\uE0e1'
        }, {
            'name': 'HEAD_CIRCLED',
            'text': '\uE0e5'
        }, {
            'name': 'HEAD_CIRCLED_LARGE',
            'text': '\uE0e9'
        }, {
            'name': 'HEAD_LARGE_ARROW',
            'text': '\uE0ef'
        }, {
            'name': 'HEAD_BREVIS_ALT',
            'text': '\uE0a1'
        }, {
            'name': 'HEAD_SLASH',
            'text': '\uE101'
        }, {
            'name': 'HEAD_SOL',
            'text': '\uE1b0'
        }, {
            'name': 'HEAD_LA',
            'text': '\uE1b2'
        }, {
            'name': 'HEAD_FA',
            'text': '\uE1b4'
        }, {
            'name': 'HEAD_MI',
            'text': '\uE1b8'
        }, {
            'name': 'HEAD_DO',
            'text': '\uE1ba'
        }, {
            'name': 'HEAD_RE',
            'text': '\uE1bc'
        }, {
            'name': 'HEAD_TI',
            'text': '\uE1be'
        }, /*{
            'name': 'HEAD_DO_WALKER',
            'text': '\uE'
        }, {
            'name': 'HEAD_RE_WALKER',
            'text': '\uE'
        }, {
            'name': 'HEAD_TI_WALKER',
            'text': '\uE'
        }, {
            'name': 'HEAD_DO_FUNK',
            'text': '\uE'
        }, {
            'name': 'HEAD_RE_FUNK',
            'text': '\uE'
        }, {
            'name': 'HEAD_TI_FUNK',
            'text': '\uE'
        }, {
            'name': 'HEAD_DO_NAME',
            'text': '\uE'
        }, {
            'name': 'HEAD_RE_NAME',
            'text': '\uE'
        }, {
            'name': 'HEAD_MI_NAME',
            'text': '\uE'
        }, {
            'name': 'HEAD_FA_NAME',
            'text': '\uE'
        }, {
            'name': 'HEAD_SOL_NAME',
            'text': '\uE'
        }, {
            'name': 'HEAD_LA_NAME',
            'text': '\uE'
        }, {
            'name': 'HEAD_TI_NAME',
            'text': '\uE'
        }, {
            'name': 'HEAD_SI_NAME',
            'text': '\uE'
        }, {
            'name': 'HEAD_A_SHARP',
            'text': '\uE'
        }, {
            'name': 'HEAD_A',
            'text': '\uE'
        }, {
            'name': 'HEAD_A_FLAT',
            'text': '\uE'
        }, {
            'name': 'HEAD_B_SHARP',
            'text': '\uE'
        }, {
            'name': 'HEAD_B',
            'text': '\uE'
        }, {
            'name': 'HEAD_B_FLAT',
            'text': '\uE'
        }, {
            'name': 'HEAD_C_SHARP',
            'text': '\uE'
        }, {
            'name': 'HEAD_C',
            'text': '\uE'
        }, {
            'name': 'HEAD_C_FLAT',
            'text': '\uE'
        }, {
            'name': 'HEAD_D_SHARP',
            'text': '\uE'
        }, {
            'name': 'HEAD_D',
            'text': '\uE'
        }, {
            'name': 'HEAD_D_FLAT',
            'text': '\uE'
        }, {
            'name': 'HEAD_E_SHARP',
            'text': '\uE'
        }, {
            'name': 'HEAD_E',
            'text': '\uE'
        }, {
            'name': 'HEAD_E_FLAT',
            'text': '\uE'
        }, {
            'name': 'HEAD_F_SHARP',
            'text': '\uE'
        }, {
            'name': 'HEAD_F',
            'text': '\uE'
        }, {
            'name': 'HEAD_F_FLAT',
            'text': '\uE'
        }, {
            'name': 'HEAD_G_SHARP',
            'text': '\uE'
        }, {
            'name': 'HEAD_G',
            'text': '\uE'
        }, {
            'name': 'HEAD_G_FLAT',
            'text': '\uE'
        }, {
            'name': 'HEAD_H',
            'text': '\uE'
        }, {
            'name': 'HEAD_H_SHARP',
            'text': '\uE'
        }, {
            'name': 'HEAD_CUSTOM',
            'text': '\uE'
        }, {
            'name': 'HEAD_GROUPS',
            'text': '\uE'
        },*/ {
            'name': 'HEAD_INVALID',
            'text': '?'
        }
    ];


/*
'tpc': 33,
'name': 'B♯♯',
'pitch': 13,
'accidental': 'SHARP2',
'raw': 'B'

 */
function tpcClass(tpc, name, accidental) {
    this.tpc = tpc;
    this.name = name;

    this.raw = name.substring(0, 1);

    this.pitch = tpcToPitch(tpc);

    if (accidental !== undefined) {
        this.accidental = accidental;
    } else {

        var a = name.substring(1, name.len);
        switch (a) {
        case '♯♯':
            this.accidental = 'SHARP2';
            break;
        case '♯':
            this.accidental = 'SHARP';
            break;
        case '♭♭':
            this.accidental = 'FLAT2';
            break;
        case '♭':
            this.accidental = 'FLAT';
            break;
        default:
            this.accidental = 'NONE';
        }
    }

    this.toString = function () {
        return this.raw + " " + this.accidental;
    };

    Object.freeze(this);

}

function tpcToPitch(tpc) {
    return deltaTpcToPitch(tpc, 14);
}

function deltaTpcToPitch(tpc1, tpc2) {
    var d = ((tpc2 - tpc1) * 5) % 12;
    if (d < 0)
        d += 12;
    return d;
}

function durationTo64(duration) {
    return 64 * duration.numerator / duration.denominator;
}
