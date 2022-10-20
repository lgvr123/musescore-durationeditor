/**********************
/* Parking B - MuseScore - Note helper
/* v1.0.5
/* ChangeLog:
/* 	- 22/7/21: Added restToNote and changeNote function
/*  - 25/7/21: Managing of transposing instruments
/*	- 5/9/21: v1.0.2 Improved support for transpositing instruments.
/*	- 13/03/22: v1.0.4 Extra parameter to keep the rest duration when adding notes and chords.
/*	- 13/03/22: v1.0.4 New restToChords function.
/*	- 18/03/22: v1.0.5 restToNote and New restToChords accept now tpc1 and tpc2 values.
/**********************************************/
// -----------------------------------------------------------------------
// --- Vesionning-----------------------------------------
// -----------------------------------------------------------------------

function checktVersion(expected) {
    return checkVersion(expected);
}
function checkVersion(expected) {
    var version = "1.0.5";

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
 * - note.extname.fullname : "C#4"
 * - note.extname.name : "C4"
 * - note.extname.raw : "C"
 * - note.extname.octave : "4"
 * @param note The note to be enriched
 * @return /
 */
function enrichNote(note) {
    // accidental
    var id = note.accidentalType;
    note.accidentalName = "UNKOWN";
    for (var i = 0; i < accidentals.length; i++) {
        var acc = accidentals[i];
        if (id == eval("Accidental." + acc.name)) {
            note.accidentalName = acc.name;
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

    var name = noteName.substr(0, 1);
    var octave = parseInt(noteName.substr(1, 3));

    var a = accidental;
    for (var i = 0; i < equivalences.length; i++) {
        for (var j = 1; j < equivalences[i].length; j++) {
            if (accidental == equivalences[i][j]) {
                a = equivalences[i][0];
                break;
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
        // ==> we force the representation mode by steiing tpc1 to undefined and specifying tpc2
        //"tpc1" : tpc.tpc,
        "tpc2": tpc.tpc
    };

    return recompose;
}

/**
 * keepRestDuration: duration|boolean|undefined 
 * * duration: on the form of duration.numerator, duration.denominator : the duration to force
 * * boolean==true: keep the rest duration
 * * boolean==false | undefined: the duration will be quarter
 */
function restToNote(rest, toNote, keepRestDuration) {
    if (rest.type != Element.REST)
        return;
    var duration;

    if (toNote === parseInt(toNote))
        toNote = {
            "pitch": toNote,
            "concertPitch": false,
            "sharp_mode": true
        };

    // For compatibility
    if (typeof keepRestDuration === 'undefined')
        duration = undefined;
    else if (typeof keepRestDuration === 'boolean') {
        if (keepRestDuration) {
            duration = rest.duration;
        }

    } else
        duration = keepRestDuration;

    //console.log("==ON A REST==");
    var cur_time = rest.parent.tick; // getting rest's segment's tick
    var oCursor = curScore.newCursor();
    oCursor.track = rest.track;

    if (duration) {
        oCursor.setDuration(duration.numerator, duration.denominator);
    }
    oCursor.rewindToTick(cur_time);
    oCursor.addNote(toNote.pitch);
    oCursor.rewindToTick(cur_time);
    var chord = oCursor.element;
    var note = chord.notes[0];

    //debugPitch(level_DEBUG,"Added note",note);

    changeNote(note, toNote);

    //debugPitch(level_DEBUG,"Corrected note",note);


    return note;
}

function restToChord(rest, toNotes, keepRestDuration) {
    if (rest.type != Element.REST)
        return;

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

    //console.log("Dealing with note "+0+": "+notes[0].pitch);
    restToNote(rest, notes[0], keepRestDuration);

    for (var i = 1; i < notes.length; i++) {
        var dest = notes[i];
        //console.log("Dealing with note "+i+": "+dest.pitch);
        var cur_time = rest.parent.tick; // getting rest's segment's tick
        var oCursor = curScore.newCursor();
        oCursor.track = rest.track;
        oCursor.rewindToTick(cur_time);
        oCursor.addNote(dest.pitch, true); // addToChord=true
        oCursor.rewindToTick(cur_time);
        var chord = oCursor.element;
        console.log(">>" + ((chord !== null) ? chord.userName() : "null") + " (" + ((chord !== null) ? chord.notes.length : "/") + ")");
        var note = chord.notes[i];

        //debugPitch(level_DEBUG,"Added note",note);

        NoteHelper.changeNote(note, dest);

    }

    return note;
}

/**
 * @param toNote.pitch: the target pitch,

 * @param toNote.tpc1, toNote.tpc2 : the target tpc, if known beforehand

 * -- OR --

 * @param toNote.concertPitch: true|false, false means the note must be dispalyed as having that pitch.
 * For a Bb instrument, a pitch=60 (C), with concertPitch=false will be displayed as a C but be played as Bb.
 * With concertPitch=true, it will be played as a C and therefor displayed as a D.
 * @param toNote.sharp_mode: true|false The preference goes to sharp accidentals (true) or flat accidentals (false)
 */
function changeNote(note, toNote) {
    if (note.type != Element.NOTE) {
        debug(level_INFO, "! Changing Note of a non-Note element");
        return;
    }

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
        'name': 'NONE',
    }, {
        'name': 'FLAT',
    }, {
        'name': 'NATURAL',
    }, {
        'name': 'SHARP',
    }, {
        'name': 'SHARP2',
    }, {
        'name': 'FLAT2',
    }, {
        'name': 'NATURAL_FLAT',
    }, {
        'name': 'NATURAL_SHARP',
    }, {
        'name': 'SHARP_SHARP',
    }, {
        'name': 'FLAT_ARROW_UP',
    }, {
        'name': 'FLAT_ARROW_DOWN',
    }, {
        'name': 'NATURAL_ARROW_UP',
    }, {
        'name': 'NATURAL_ARROW_DOWN',
    }, {
        'name': 'SHARP_ARROW_UP',
    }, {
        'name': 'SHARP_ARROW_DOWN',
    }, {
        'name': 'SHARP2_ARROW_UP',
    }, {
        'name': 'SHARP2_ARROW_DOWN',
    }, {
        'name': 'FLAT2_ARROW_UP',
    }, {
        'name': 'FLAT2_ARROW_DOWN',
    }, {
        'name': 'MIRRORED_FLAT',
    }, {
        'name': 'MIRRORED_FLAT2',
    }, {
        'name': 'SHARP_SLASH',
    }, {
        'name': 'SHARP_SLASH4',
    }, {
        'name': 'FLAT_SLASH2',
    }, {
        'name': 'FLAT_SLASH',
    }, {
        'name': 'SHARP_SLASH3',
    }, {
        'name': 'SHARP_SLASH2',
    }, {
        'name': 'DOUBLE_FLAT_ONE_ARROW_DOWN',
    }, {
        'name': 'FLAT_ONE_ARROW_DOWN',
    }, {
        'name': 'NATURAL_ONE_ARROW_DOWN',
    }, {
        'name': 'SHARP_ONE_ARROW_DOWN',
    }, {
        'name': 'DOUBLE_SHARP_ONE_ARROW_DOWN',
    }, {
        'name': 'DOUBLE_FLAT_ONE_ARROW_UP',
    }, {
        'name': 'FLAT_ONE_ARROW_UP',
    }, {
        'name': 'NATURAL_ONE_ARROW_UP',
    }, {
        'name': 'SHARP_ONE_ARROW_UP',
    }, {
        'name': 'DOUBLE_SHARP_ONE_ARROW_UP',
    }, {
        'name': 'DOUBLE_FLAT_TWO_ARROWS_DOWN',
    }, {
        'name': 'FLAT_TWO_ARROWS_DOWN',
    }, {
        'name': 'NATURAL_TWO_ARROWS_DOWN',
    }, {
        'name': 'SHARP_TWO_ARROWS_DOWN',
    }, {
        'name': 'DOUBLE_SHARP_TWO_ARROWS_DOWN',
    }, {
        'name': 'DOUBLE_FLAT_TWO_ARROWS_UP',
    }, {
        'name': 'FLAT_TWO_ARROWS_UP',
    }, {
        'name': 'NATURAL_TWO_ARROWS_UP',
    }, {
        'name': 'SHARP_TWO_ARROWS_UP',
    }, {
        'name': 'DOUBLE_SHARP_TWO_ARROWS_UP',
    }, {
        'name': 'DOUBLE_FLAT_THREE_ARROWS_DOWN',
    }, {
        'name': 'FLAT_THREE_ARROWS_DOWN',
    }, {
        'name': 'NATURAL_THREE_ARROWS_DOWN',
    }, {
        'name': 'SHARP_THREE_ARROWS_DOWN',
    }, {
        'name': 'DOUBLE_SHARP_THREE_ARROWS_DOWN',
    }, {
        'name': 'DOUBLE_FLAT_THREE_ARROWS_UP',
    }, {
        'name': 'FLAT_THREE_ARROWS_UP',
    }, {
        'name': 'NATURAL_THREE_ARROWS_UP',
    }, {
        'name': 'SHARP_THREE_ARROWS_UP',
    }, {
        'name': 'DOUBLE_SHARP_THREE_ARROWS_UP',
    }, {
        'name': 'LOWER_ONE_SEPTIMAL_COMMA',
    }, {
        'name': 'RAISE_ONE_SEPTIMAL_COMMA',
    }, {
        'name': 'LOWER_TWO_SEPTIMAL_COMMAS',
    }, {
        'name': 'RAISE_TWO_SEPTIMAL_COMMAS',
    }, {
        'name': 'LOWER_ONE_UNDECIMAL_QUARTERTONE',
    }, {
        'name': 'RAISE_ONE_UNDECIMAL_QUARTERTONE',
    }, {
        'name': 'LOWER_ONE_TRIDECIMAL_QUARTERTONE',
    }, {
        'name': 'RAISE_ONE_TRIDECIMAL_QUARTERTONE',
    }, {
        'name': 'DOUBLE_FLAT_EQUAL_TEMPERED',
    }, {
        'name': 'FLAT_EQUAL_TEMPERED',
    }, {
        'name': 'NATURAL_EQUAL_TEMPERED',
    }, {
        'name': 'SHARP_EQUAL_TEMPERED',
    }, {
        'name': 'DOUBLE_SHARP_EQUAL_TEMPERED',
    }, {
        'name': 'QUARTER_FLAT_EQUAL_TEMPERED',
    }, {
        'name': 'QUARTER_SHARP_EQUAL_TEMPERED',
    }, {
        'name': 'SORI',
    }, {
        'name': 'KORON',
    }
    //,{ 'name': 'UNKNOWN',  }
];

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