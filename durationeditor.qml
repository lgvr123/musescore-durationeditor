import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import "zparkingb/selectionhelper.js" as SelHelper
import "zparkingb/notehelper.js" as NoteHelper
import "durationeditor"

/**********************
/* Parking B - DurationEditor - New approach for note duration edition
/* v1.3.0
/* ChangeLog:
/* 	- 1.1.0: Initial release
/* 	- 1.2.0: New Tie note functionality
/* 	- 1.3.0: New Tuplet functionality
/**********************************************/

MuseScore {
    menuPath: "Plugins." + pluginName
    description: "Edit the notes and rests length by moving the next notes in the measure, instead of eating them."
    version: "1.2.0"
    readonly property var pluginName: "Duration Editor"
    readonly property var selHelperVersion: "1.2.0"
    readonly property var noteHelperVersion: "1.0.4"

    readonly property var debug: false
	
    pluginType: debug?undefined:"dock"
    dockArea: "right"
    requiresScore: false
    width: 600
    height: 100

    readonly property var imgHeight: 32
    readonly property var imgPadding: 8

    Flow {
        id: layButtons

        anchors.fill: parent
        anchors.margins: 4
        spacing: 10

        ImageButton {
            imageSource: "ronde.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Change to Whole/Semibreve\nSHIFT: insert a rest"
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    if ((mouse.button == Qt.LeftButton) && (mouse.modifiers & Qt.ShiftModifier)) {
                        insertRest(64);
                    } else {
                        setDuration(64);
                    }
                }
            }
        }

        ImageButton {
            imageSource: "blanche.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Change to Half/Minim\nSHIFT: insert a rest"
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    if ((mouse.button == Qt.LeftButton) && (mouse.modifiers & Qt.ShiftModifier)) {
                        insertRest(32);
                    } else {
                        setDuration(32);
                    }
                }
            }
        }

        ImageButton {
            imageSource: "noire.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Change to Quarter/Crotchet\nSHIFT: insert a rest"
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    if ((mouse.button == Qt.LeftButton) && (mouse.modifiers & Qt.ShiftModifier)) {
                        insertRest(16);
                    } else {
                        setDuration(16);
                    }
                }
            }
        }

        ImageButton {
            imageSource: "croche.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Change to Eighth/Quaver\nSHIFT: insert a rest"
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    if ((mouse.button == Qt.LeftButton) && (mouse.modifiers & Qt.ShiftModifier)) {
                        insertRest(8);
                    } else {
                        setDuration(8);
                    }
                }
            }
        }

        ImageButton {
            imageSource: "double.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Change to Sixteenth/Semiquaver\nSHIFT: insert a rest"
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    if ((mouse.button == Qt.LeftButton) && (mouse.modifiers & Qt.ShiftModifier)) {
                        insertRest(4);
                    } else {
                        setDuration(4);
                    }
                }
            }
        }

        ImageButton {
            imageSource: "triple.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Change to Thirty-second/Demisemiquaver\nSHIFT: insert a rest"
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    if ((mouse.button == Qt.LeftButton) && (mouse.modifiers & Qt.ShiftModifier)) {
                        insertRest(2);
                    } else {
                        setDuration(2);
                    }
                }
            }
        }

        ImageButton {
            imageSource: "quadruple.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Change to Sixty-fourth/Hemidemisemiquaver\nSHIFT: insert a rest"
            MouseArea {
                anchors.fill: parent
                onPressed: {
                    if ((mouse.button == Qt.LeftButton) && (mouse.modifiers & Qt.ShiftModifier)) {
                        insertRest(1);
                    } else {
                        setDuration(1);
                    }
                }
            }
        }

        ImageButton {
            imageSource: "dot.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Dot"
            onClicked: setDot(1.5)
        }

        ImageButton {
            imageSource: "dot2.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Dubble dot"
            onClicked: setDot(1.75)
        }

        ImageButton {
            imageSource: "dot3.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Triple dot"
            onClicked: setDot(1.875)
        }

        ImageButton {
            imageSource: "dot4.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Quadruple dot"
            onClicked: setDot(1.9375)
        }

        ImageButton {
            imageSource: "remove.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Delete"
            onClicked: setDuration(0)
        }

        ImageButton {
            id: btnTie
            // imageSource: "qrc:///data/icons/note-tie.svg"
            imageSource: "tie.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            // fillMode: Image.PreserveAspectCrop
            ToolTip.text: "Tie rest to previous chord/Tie chord to next rest."
            onClicked: addTie()
        }

        ImageButton {
            id: btnTuplet
            imageSource: "tuplets.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            // fillMode: Image.PreserveAspectCrop
            ToolTip.text: "Convert regular chords to and from tuplets."
            onClicked: addRemoveTupplet()
        }

    }

    onRun: {

        // Versionning
        if ((typeof(SelHelper.checktVersion) !== 'function') || !SelHelper.checktVersion(selHelperVersion) ||
            (typeof(NoteHelper.checktVersion) !== 'function') || !NoteHelper.checktVersion(noteHelperVersion)) {
            console.log("Invalid zparkingb/selectionhelper.js or zparkingb/notehelper.js versions. Expecting "
                 + selHelperVersion + " and " + noteHelperVersion + ".");
            invalidLibraryDialog.open();
            return;
        }

        // auto-run test
        if (debug) addRemoveTupplet();

    }

    function setDuration(newDuration) {
        var chords = getSelection();

        if (!chords || (chords.length == 0))
            return;

        setElementDuration(chords[0], newDuration);

    }

    function insertRest(newDuration) {
        var chords = getSelection();

        if (!chords || (chords.length == 0))
            return;

        setElementDuration(chords[0], newDuration * (-1));

    }

    function setDot(newDuration) {
        var chords = getSelection();

        if (!chords || (chords.length == 0))
            return;

        setElementDot(chords[0], newDuration);

    }

    function setElementDot(element, dot) {
        var current = durationTo64(element.duration);
        var analyze = analyzeDuration(current);

        console.log(current + " => " + analyze.base + "/" + analyze.ratio);

        var newDuration;

        if (dot == analyze.ratio) {
            // Same "dot", removing it
            newDuration = analyze.base;
        } else {
            newDuration = analyze.base * dot;
        }

        setElementDuration(element, newDuration);
    }

    /**
     * newDuration>0: change the element to that duration
     * newDuration==0: delete the element
     * newDuration<0: insert a rest before the element with that duration
     */
    function setElementDuration(element, newDuration) {

        var insertmode = (newDuration < 0);
        newDuration = Math.abs(newDuration);

        var score = curScore;

        var cur_time = element.parent.tick;

        var cursor = score.newCursor();
        cursor.track = element.track;
        cursor.rewindToTick(cur_time);

        var current = durationTo64(element.duration);
        var increment = (insertmode) ? newDuration : newDuration - current;
        console.log("from " + current + " to " + newDuration);

        if (increment > 0) {

            // 0) On compte ce qu'on a comme buffer en fin de mesure
            var buffer = computeRemainingRest(cursor.measure, cursor.track);
            console.log("Required increment is : " + increment + ", current buffer is : " + buffer);

            // 1) on coupe ce qu'on va déplacer
            var doCutPaste = selectRemaingInMeasure(cursor, insertmode);

            if (doCutPaste) {
                console.log("CMD: cmd(\"cut\")");
                cmd("cut");
            }

            // 2) on adapte la longueur de la mesure (si on n'a pas assez de buffer)
            if (buffer < increment) {
                appendRest(cursor, increment - buffer);
            }

            // 3) on adapte la durée de la note
            cursor.rewindToTick(cur_time);
            cursorToDuration(cursor, newDuration);

            // 3) On fait le paste
            if (doCutPaste) {
                cursor.rewindToTick(cur_time);
                cursor.next();
                selectCursor(cursor);
                console.log("CMD: cmd(\"paste\")");
                cmd("paste");
            }
            //endCmd(score);

        }
        if (increment < 0) {

            // 1) on coupe ce qu'on va déplacer
            var doCutPaste = selectRemaingInMeasure(cursor);

            if (doCutPaste) {
                console.log("CMD: cmd(\"cut\")");
                cmd("cut");
            }

            // 2) on adapte la durée de la note
            cursor.rewindToTick(cur_time);
            if (newDuration != 0)
                cursorToDuration(cursor, newDuration);
            else {
                // duration 0, so replace the element by a rest
                startCmd(score);
                console.log("CMD: replace element by rest (removeElement)");
                removeElement(element);
                endCmd(score);
            }
            //cursor.element.duration=fraction(1, 2) // KO


            // 3) On fait le paste
            if (doCutPaste) {
                cursor.rewindToTick(cur_time);
                if (newDuration != 0)
                    cursor.next();
                selectCursor(cursor);
                console.log("CMD: cmd(\"paste\")");
                cmd("paste");
            }

            // 4) On réduit la durée de la mesure si nécessaire

            var measure = cursor.measure;
            debugMeasureLength(measure);
            removeRest(cursor, increment);
            debugMeasureLength(measure);

        }

        cursor.rewindToTick(cur_time);
        selectCursor(cursor);

    }

    function addTie() {
        var rests = getSelection();
        if (rests.length == 0) {
            console.log("NO SELECTION. QUIT HERE.");
            return;
        }

        var rest = rests[0];
        var source = null;

        var cur_time = rest.parent.tick; // getting rest's segment's tick
        var cursor = curScore.newCursor();
        cursor.track = rest.track;

        cursor.rewindToTick(cur_time);

        if (rest.type === Element.REST) {

            console.log("REST ==> looking behind for a CHORD");

            if (!movePrev(cursor)) {
                warningDialog.text = "Failed to tie the rest.\nCannot identify a chord to tie from.";
                warningDialog.open();
                return;
            }

            source = cursor.element;

            if (source === null) {
                warningDialog.text = "Failed to tie the rest.\nCannot identify a chord to tie from.";
                warningDialog.open();
                return;
            }

            if (source.type !== Element.CHORD) {
                warningDialog.text = "Failed to tie the rest.\nThe selected rest must to preceded by a chord.";
                warningDialog.open();
                return;
            }
        } // current is rest
        else {
            console.log("CHORD ==> looking forward for a REST");
            source = rest;
            if (!moveNext(cursor)) {
                warningDialog.text = "Failed to tie the chord.\nCannot identify a rest to tie to.";
                warningDialog.open();
                return;
            }

            rest = cursor.element;

            if (rest === null) {
                warningDialog.text = "Failed to tie the chord.\nCannot identify a rest to tie to.";
                warningDialog.open();
                return;
            }

            if (rest.type !== Element.REST) {
                warningDialog.text = "Failed to tie the chord.\nThe selected chord must to followed by a rest.";
                warningDialog.open();
                return;
            }

        }

        // A source is found.
        // var note = source.notes[0];
        console.log("Got a source at " + source.parent.tick + " and a dest at " + rest.parent.tick);
        var notes = [];
        for (var i = 0; i < source.notes.length; i++) {
            notes.push(source.notes[i].pitch);
        }

        // Transforming the rest into the notes
        startCmd(curScore);

        NoteHelper.restToChord(rest, notes, true); // with keepRestDuration=true

        cursor.rewindToTick(source.parent.tick);
        selectCursor(cursor);
        cmd("chord-tie");

        cursor.rewindToTick(rest.parent.tick);
        // cursor.rewindToTick(cur_time);
        selectCursor(cursor);

        endCmd(curScore);
    }

    function addRemoveTupplet() {
        var tupletChords = getTupletsFromSelection();

        if (tupletChords && (tupletChords.length > 0)) {
            // Tuplets selected - Converting to regular chords
            console.log("TUPLETS FOUND FROM SELECTION");
            convertChordsFromTuplets(tupletChords);

        } else if (tupletChords && (tupletChords.length == 0)) {
            console.log("No TUPLETS FOUND FROM SELECTION");
            tupletChords = getTupletsCandidates();

            if (tupletChords && (tupletChords.length > 0)) {
                // Regular chords selected - Converting to tuplets chords
                console.log("THE SELECTION CAN BE CONVERTED to TUPLETS");
                convertChordsToTuplets(tupletChords);

            } else {
                console.log("INVALID SELECTION");
                return;
            }

        } else {
            console.log("INVALID SELECTION");
            return;
        }

    }
    function convertChordsToTuplets(chords) {
        // Transforming regular notes into tuplets
        var measure = chords[0].parent.parent;

        var duration = 0;
        for (var i = 0; i < chords.length; i++) {
            duration += durationTo64(chords[i].duration);
            console.log("To tuplets elements: " + chords[i].userName() + " with duration " + durationTo64(chords[i].duration));
        }

        var measureType = measure.timesigActual.denominator;

        console.log("Selection: " + chords.length + "element, total duration: " + duration);
        console.log("Measure: x/" + measureType + ", total duration: " + sigTo64(measure.timesigActual));

        var tupletN = null;
        var tupletD = null;

        if (measureType == 4) {
            // 2/4, 3/4, 4/4, ...
            for (var n = 3; n <= 9; n++) {
                if (isTupletCandidate(duration, n)) {
                    tupletN = n;
                    break;
                }
            }

            if (tupletN != null) {
                tupletD = Math.pow(2, Math.sqrt(tupletN) | 0); // (trunc) 3/2, 5/4, 6/4, .. 9/8, ...
            }

        } else if (measureType == 8) {
            // 3/8, 6/8, 9/8, ...
            // TODO

        }

        console.log("Heading to " + ((tupletN != null) ? (tupletN + ":" + tupletD + " of " + (duration / tupletN)) : "???"));

        if (tupletN == null) {
            console.log("Failed to identify the tuplet structure");
            return false;
        }

        // Inserting the triplet
        // 0) collecting what to be re-added
        var targets = [];
        for (var i = 0; i < chords.length; i++) {
            var chord = chords[i];
            var target = {
                "duration": {
                    "numerator": chord.duration.numerator,
                    "denominator": chord.duration.denominator
                }
            };
            // If CHORD, then remember the notes. Otherwise treat as a rest
            if (chord.type === Element.CHORD) {
                target.notes = chord.notes;
            };
            targets.push(target);
        }
        // 1) deleting/reducing the last element duration
        var targetdur = duration * tupletD / tupletN;
        console.log("duration modification : " + duration + " --> " + targetdur);
        var delta = duration - targetdur;
        for (var i = chords.length - 1; i >= 0; i--) {
            var last = chords[i];
            var newDuration = durationTo64(last.duration) - delta;
			startCmd(curScore,"adapt last note duration");
            if (newDuration >= 0) {
                setElementDuration(last, newDuration);
                break;
            } else {
                // Il faut supprimer plus que le dernier
                setElementDuration(last, 0);
                delta = newDuration * (-1);
            }
            endCmd(curScore,"adapt last note duration"); // DEBUG
        }
        // 2) adding a tuplet
        var cur_time = chords[0].parent.tick;
        var cursor = curScore.newCursor();
        cursor.track = chords[0].track;
        cursor.rewindToTick(cur_time);

        startCmd(curScore,"addTuplet");
        cursor.addTuplet(fraction(tupletN, tupletD), fraction(duration / tupletN, 64 * tupletD / measureType));
		endCmd(curScore,"addTuplet"); 

        // 3) re-adding the notes
        for (var i = 0; i < targets.length; i++) {
            var target = targets[i];
            //var target = chords[i]; // TEST - DIRECTEMENT UTILISER LES NOTES MEMEORISEES --> KO (du moins sur les durées)
			var tick=cursor.tick;
            //console.log("Target " + i + ": " + target.duration.numerator + "/" + target.duration.denominator + ", notes: " + (target.notes ? target.notes.length : 0));

            if (target.notes && target.notes.length > 0) {
                var pitches = [];
                for (var j = 0; j < target.notes.length; j++) {
                    pitches.push(target.notes[j].pitch);
                }
                startCmd(curScore,"restToChord"); //DEBUG
                NoteHelper.restToChord(cursor.element, pitches, true); // with keepRestDuration=true
				endCmd(curScore,"restToChord"); // DEBUG
            }

            //console.log("note duration modification: "+durationTo64(cursor.element.duration)+" --> "+durationTo64(target.duration));
            startCmd(curScore,"adapt duration"); //DEBUG
			cursor.rewindToTick(tick);
            cursorToDuration(cursor, durationTo64(target.duration));
            endCmd(curScore,"adapt duration"); // DEBUG

            moveNext(cursor);
        }

        // if (!debug)endCmd(curScore);

    }

    function isTupletCandidate(duration, check) {
        var res = duration / check;
        return ((res | 0) == res); // trunc
    }

    function convertChordsFromTuplets(tupletChords) {
        // Transforming a tuplet into regular notes
        var tuplet = tupletChords[0];
        var measure = tuplet.parent;
        var _p = tupletChords[0].tuplet.elements;
        var elements = [];
        for (var i = 0; i < _p.length; i++) {
            var e = _p[i];
            if ((e.type == Element.CHORD) || (e.type == Element.REST)) {
                elements.push(e);
            }
        };
        startCmd(curScore,"removeTuplet");
        // Fonctionne
        //removeElement(tuplet);

        for (var i = 0; i < elements.length; i++) {
            console.log("Tuplets elements: " + elements[i].userName() + " with duration " + durationTo64(elements[i].duration));
        }

        endCmd(curScore,"removeTuplet");

    }

    /**
     * Returns the Chord/Rests belonging to the 1st tuplet of the selection.
     * If the selection does not contain a tuplet, an empty array is returned.
     * If the selection is containing incoherent elements (tuplet-based and non-tuplet-based elements, multiple tuplets elements, ...), "false" is returned.
     */
    function getTupletsFromSelection() {
        var selection = curScore.selection;
        var el = selection.elements;
        var tuplets = [];
        console.log("Analyzing " + el.length + " elements in search of tuplets");
        for (var i = 0; i < el.length; i++) {
            var element = el[i];
            console.log("\t" + i + ") " + element.type + " (" + element.userName() + ")");
            if (element.type == Element.TUPLET) {
                tuplets.push(element);
            }
        }

        if (tuplets.length != 0) {
            console.log("A tuplet bar is selected. Returning its elements");
            var parts = [];
            var tuplet = tuplets[0];
            for (var i = 0; i < tuplet.length; i++) {
                var e = tuplet[i];
                if ((e.type == Element.CHORD) || (e.type == Element.REST)) {
                    parts.push(e);
                }
            };
            return parts;
        }

        var selection = SelHelper.getChordsRestsFromSelection();
        if (selection.length == 0) {
            // empty selection
            // should return a status -1
            console.log("No selection !!");
            return false;
        }

        var tupletChords = selection.filter(function (e) {
            return (e.tuplet != null);
        });
        if (tupletChords.length == 0) {
            // a selection but no tuplets
            console.log("No tuplets in selection");
            return tupletChords;
        }

        if (tupletChords.length != selection.length) {
            // no all chords/rests have tuplets ==> ERROR
            console.log("No all chords have tuplets !!");
            return false;
        }
        console.log("All selection have tuplets");

        // checking if we are dealing with 1 tuplet
        var tuplet = tupletChords[0].tuplet;
        var _p = tupletChords[0].tuplet.elements;
        var parts = [];
        for (var i = 0; i < _p.length; i++) {
            var e = _p[i];
            if ((e.type == Element.CHORD) || (e.type == Element.REST)) {
                parts.push(e);
            }
        };
        console.log(selection.length + " elements; " + parts.length + " parts");
        var remainingp = parts.filter(function (e) {
            console.log("filtering parts: " + e.parent.tick);
            var found = false;
            for (var j = 0; j < selection.length; j++) {
                // console.log("filtering parts: " + e.parent.tick + "/" + selection[j].parent.tick);
                if (selection[j].parent.tick == e.parent.tick) {
                    found = true;
                    break;
                }
            }
            return !found;
        });
        var remainingc = selection.filter(function (e) {
            var found = false;
            for (var j = 0; j < parts.length; j++) {
                // console.log("filtering selection: " + e.parent.tick + "/" + parts[j].parent.tick);
                if (parts[j].parent.tick == e.parent.tick) {
                    found = true;
                    break;
                }
            }
            return !found;
        });
        console.log("Have we found enverything ? Remaining parts:" + remainingp.length + " parts, Remaining selection:" + remainingc.length + " chords");

        if ((remainingp.length != 0) || (remainingc.length != 0)) {
            // all chords/rests are not part of the same tuplet ==> ERROR
            console.log("The nd the tuplets are not uniquely selected !!");
            return false;
        }

        console.log("Returning implicy selected tuplet chords elements");
        return tupletChords;
    } // getTupletsFromSelection


    function getTupletsCandidates() {
        // we have to ensure that we have a continuous selection
        var selection = SelHelper.getChordsRestsFromSelection();

        if (selection.length == 0)
            return false;

        var cur_time = selection[0].parent.tick;
        var cursor = curScore.newCursor();
        cursor.track = selection[0].track;
        cursor.rewindToTick(cur_time);

        //debug
        console.log("ticks: " + selection.map(function (e) {
                return e.parent.tick;
            }).join(" - "));

        console.log("0) " + selection[0].parent.tick);

        for (var i = 1; i < selection.length; i++) {
            var sel = selection[i];
            console.log(i + ") " + sel.parent.tick);
            var next = moveNextInMeasure(cursor) ? cursor.element : null;

            if ((next == null) || (sel.parent.tick != next.parent.tick)) {
                console.log("Selection mistmatch: expecting " + sel.parent.tick + ", found: " + ((next != null) ? next.parent.tick : "null"));
                return false;
            } else {
                console.log("Selection match: expecting " + sel.parent.tick + ", found: " + next.parent.tick + " (" + next.userName() + ")");

            }
        }

        console.log("The selection is valid");
        return selection;

    } // getTupletsCandidates

    function getSelection() {
        var chords = SelHelper.getChordsRestsFromCursor();

        if (chords && (chords.length > 0)) {
            console.log("CHORDS FOUND FROM CURSOR");
        } else {
            chords = SelHelper.getChordsRestsFromSelection();
            if (chords && (chords.length > 0)) {
                console.log("CHORDS FOUND FROM SELECTION");
            } else
                chords = [];
        }

        return chords;
    }

    function cursorToDuration(cursor, target) {

        var analyze = analyzeDuration(target);
        var base = analyze.base;
        var ratio = analyze.ratio;

        console.log(target + " : " + base + "/" + ratio);

        selectCursor(cursor);
        var cmdline = "pad-note-" + (64 / base);
        console.log("CMD: cmd(\"" + cmdline + "\")");
        cmd(cmdline);

        if (analyze.half != null) {
            console.log("Dealing with \"1.25\" ratio (" + ratio + ")");
            base = base / 2;

            cmdline = "pad-note-" + (64 / base);
            console.log("CMD: cmd(\"" + cmdline + "\")");
            cmd(cmdline);

            moveNextInMeasure(cursor);
            ratio = 1; // we don't apply any dot on this segment. We'll apply one on the next one.
            // we repeat the same process with halfed duration
            cursorToDuration(cursor, base * analyze.half);
        }

        switch (ratio) {
        case 1.5:
            console.log("CMD: cmd(\"pad-dot\")");
            cmd("pad-dot")
            break;
        case 1.75:
            console.log("CMD: cmd(\"pad-dotdot\")");
            cmd("pad-dotdot")
            break;

        case 1.875:
            console.log("CMD: cmd(\"pad-dot3\")");
            cmd("pad-dot3")
            break;
        case 1.9375:
            console.log("CMD: cmd(\"pad-dot4\")");
            cmd("pad-dot4")
            break;
        case 1:
            // 0 is normal. No reason to complain about.
            break;
        default:
            console.log("!! Cannot find a dot for " + ratio);
        }

    }

    function analyzeDuration(target) {
        var base = Math.log(target) / Math.log(2);
        var remaining = base - (base | 0); // base - trunc(base);
        base = base | 0; // = trunc
        base = Math.pow(2, base);
        var ratio = ((Math.pow(2, remaining) * 10000) | 0) / 10000;

        var half = null; ;

        // Gestion des arrondis
        // Gestion des arrondis
        if (Math.abs(ratio - 1.125) <= 0.01) {
            ratio = 1.125;
            half = 1.25;
        } else if (Math.abs(ratio - 1.25) <= 0.01) {
            ratio = 1.25;
            half = 1.5;
        } else if (Math.abs(ratio - 1.375) <= 0.01) {
            ratio = 1.375;
            half = 1.75;
        } else if (Math.abs(ratio - 1.4375) <= 0.01) {
            ratio = 1.4375;
            half = 1.875;
        } else if (Math.abs(ratio - 1.46875) <= 0.01) {
            ratio = 1.46875;
            half = 1.9375;
        } else if (Math.abs(ratio - 1.5) <= 0.01)
            ratio = 1.5;
        else if (Math.abs(ratio - 1.75) <= 0.01)
            ratio = 1.75;
        else if (Math.abs(ratio - 1.875) <= 0.01)
            ratio = 1.875;
        else if (Math.abs(ratio - 1.9375) <= 0.01)
            ratio = 1.9375;

        return {
            "base": base,
            "ratio": ratio,
            "half": half
        };

    }

    /**
     * Add the desired duration at the end of the measure.
     */
    function appendRest(cursor, increment) {
        var measure = cursor.measure;
        debugMeasureLength(measure);

        if (increment <= 0)
            return;

        // We don't have enough, so we increase by what's msiing
        var sig = measure.timesigActual;
        var sigNum = sigTo64(sig) + increment;
        console.log("Increasing from " + sigTo64(sig) + " to " + sigNum);

        startCmd(cursor.score,"appendRest");
        console.log("CMD: Modify timesigActual");
        measure.timesigActual = fraction(sigNum, 64);
        debugMeasureLength(measure);
        endCmd(cursor.score,"appendRest");

        /*var tick = Math.min(measure.lastSegment.tick, cursor.score.lastSegment.tick - 1); // BUG in MS, One cannot rewind to the last score tick

        console.log(measure.lastSegment.tick + " vs. " + cursor.score.lastSegment.tick);
        cursor.rewindToTick(tick);
        cursor.prev();
        selectCursor(cursor);
         */

        //var last = cursor.element;
        //var last = _d(cursor.segment, cursor.track);
        var last = getPreviousRest(measure.lastSegment, cursor.track);
        console.log(" last : " + ((last !== null) ? last.userName() : " / "));

        if (last != null) {
            var orig = durationTo64(last.duration);
            var target = orig + increment;
            var tick = last.parent.tick;
            cursor.rewindToTick(tick);
            cursorToDuration(cursor, target);
        }
    }

    /**
     * Remove the desired duration at the end of the measure.
     */
    function removeRest(cursor, increment) {
        var measure = cursor.measure;
        debugMeasureLength(measure);

        increment *= -1;

        // 1) S'assurer qu'on ne veut pas supprimer plus que la longueur nominale de la mesure
        var sigA = sigTo64(measure.timesigActual);
        console.log("Required decrement is : " + increment + ", current available in measure is : " + (sigA - 64));
        increment = sigA - Math.max(sigA - increment, 64);
        // réduction au-delà de ce qui est disponible, on ne fait rien
        if (increment <= 0)
            return;

        // 2) Computing available rest duration
        var available = computeRemainingRest(measure, null); //  we count the available rest, **whathever the tracks**
        console.log("Required decrement is : " + increment + ", current available as rest is : " + available);

        increment = Math.min(increment, available);
        // réduction au-delà de ce qui est disponible, on ne fait rien
        if (increment <= 0)
            return;

        // 3) Selecting last rest to adapt it/remove it

        var remaining = increment;
        var element = null;
        while ((remaining > 0) && ((element = getPreviousRest(measure.lastSegment, cursor.track)) != null)) {

            var orig = durationTo64(element.duration);
            if (orig <= remaining) {
                cursor.score.selection.select(element);
                console.log("CMD: cmd(\"time-delete\")");
                cmd("time-delete");
                remaining -= orig;
            } else {
                // The rest is too big. Splitting it in 2.
                var split = orig / 2;
                var tick = element.parent.tick;
                cursor.rewindToTick(tick);
                cursorToDuration(cursor, split);
                console.log("Element too big for time-delete (looking for " + increment + ", found " + orig + ") => splitting it");
            }

        }

        if (remaining > 0) {
            console.log("!! Couldn't time-delete all. Looking for " + increment + ", remaining is " + remaining);
        }

        increment -= remaining; // keep aligned how I will reduce the measure to what I have been able to time-delete

        // 4) Adapting the measure length
        var target = sigA - increment;
        startCmd(cursor.score,"removeRest");
        console.log("CMD: Modify timesigActual");
        measure.timesigActual = fraction(target, 64);
        endCmd(cursor.score,"removeRest");
        debugMeasureLength(measure);

    }

    function durationTo64(duration) {
        return 64 * duration.numerator / duration.denominator;
    }

    function sigTo64(sig) {
        return 64 * sig.numerator / sig.denominator;
    }

    /**
     * Computes the duration of the rests at the end of the measure.
     * If the track is empty (no chords, no rests) return an arbitrary value of -1
     */
    function computeRemainingRest(measure, track) {
        var last = measure.lastSegment;
        var duration = 0;

        console.log("Analyzing track " + (((track !== undefined) && (track != null)) ? track : "all"));

        if ((track !== undefined) && (track != null)) {
            duration = _computeRemainingRest(measure, track);
            return duration;

        } else {
            duration = 999;
            // Analyze made on all tracks
            for (var t = 0; t < curScore.ntracks; t++) {
                console.log(">>>> " + t + "/" + curScore.ntracks + " <<<<");
                var localavailable = _computeRemainingRest(measure, t);
                console.log("Available at track " + t + ": " + localavailable + " (" + duration + ")");
                duration = Math.min(duration, localavailable);
                if (duration == 0)
                    break;
            }
            return duration;
        }

    }

    /*
     * Instead of counting the rests at the end of measure, we count what's inside the measure beyond the last rests.
     * That way, we take into account the fact that changing the time signature of a measure doesn't fill it with rests, but leaves an empty space.
     */
    function _computeRemainingRest(measure, track) {
        var last = measure.lastSegment;
        var duration = sigTo64(measure.timesigActual);

        console.log("Analyzing track " + (((track !== undefined) && (track != null)) ? track : "all"));

        if ((track !== undefined) && (track != null)) {
            // Analyze limited to one track
            var inTail = true;
            while (last != null) {
                var element = _d(last, track);
                if ((element != null) && (element.type == Element.CHORD)) {
                    // As soon as we encounter a Chord, we leave the "rest-tail"
                    inTail = false;
                }
                if ((element != null) && ((element.type == Element.REST) || (element.type == Element.CHORD)) && !inTail) {
                    // When not longer in the "rest-tail" we decrease the remaing length by the element duration
                    duration -= durationTo64(element.duration);
                }
                last = last.prevInMeasure;
            }
        }
        return duration;
    }

    function _d(last, track) {
        var el = last.elementAt(track);
        console.log(" At " + last.tick + ": " + ((el !== null) ? el.userName() : " / "));
        return el;
    }

    /*function selectCursor(cursor) {
    var el = cursor.element;
    //console.log(el.duration.numerator + "--"+el.duration.denominator);
    if (el.type === Element.CHORD)
    el = el.notes[0];
    else if (el.type !== Element.REST)
    return false;
    cursor.score.selection.select(el);

    }*/

    function selectCursor(cursor) {
        var el = cursor.element;
        //console.log(el.duration.numerator + "--"+el.duration.denominator);
        if (el == null) {
            return false;
        } else if (el.type === Element.CHORD) {
            for (var i = 0; i < el.notes.length; i++) {
                var note = el.notes[i];
                cursor.score.selection.select(note, (i !== 0)); //addToSelection for i > 0
            }
        } else if (el.type !== Element.REST)
            return false;
        else
            cursor.score.selection.select(el);

    }

    /**
     * Position to the next valid segment in the current measure.
     * !! Nouvelle version pour 1.3.0 qui teste sur le type de segment
     */
    function moveNextInMeasure(cursor) {

        var first = cursor.segment.nextInMeasure;
        //debugSegment(first, cursor.track);
        // for the first segment: we go the next *existing* element after the one at the cursor.

        //while (first && first.elementAt(cursor.track) === null) {
        while (first && ((first.segmentType != 512) || (first.elementAt(cursor.track) === null))) {
            first = first.nextInMeasure;
            //debugSegment(first, cursor.track);
        }

        if (first === null) {
            return false;
        }

        var tick = first.tick;
        cursor.rewindToTick(tick);

        return true;

    }

    /**
     * Position to the next valid segment on the same track.
     */
    function moveNext(cursor) {

        var first = cursor.segment.next;
        debugSegment(first, cursor.track);

        // for the first segment: we go the first previous *existing* element on the same track.
        while (first && ((first.segmentType != 512) || (first.elementAt(cursor.track) === null))) {
            first = first.next;
            debugSegment(first, cursor.track);
        }

        if (first === null) {
            return false;
        }
        var tick = first.tick;
        cursor.rewindToTick(tick);
        return true;

    }

    /**
     * Position to the previous valid segment on the same track.
     */
    function movePrev(cursor) {

        var first = cursor.segment.prev;
        //debugSegment(first, cursor.track);

        // for the first segment: we go the first previous *existing* element on the same track.
        while (first && ((first.segmentType != 512) || (first.elementAt(cursor.track) === null))) {
            first = first.prev;
            //debugSegment(first, cursor.track);
        }

        if (first === null) {
            return false;
        }
        var tick = first.tick;
        cursor.rewindToTick(tick);
        return true;

    }

    function selectRemaingInMeasure(cursor, include) {
        var measure = cursor.measure;
        //var first = cursor.segment.nextInMeasure;
        var first = (include === undefined || !include) ? cursor.segment.nextInMeasure : cursor.segment;
        // for the first segment: we go the next *existing* element after the one at the cursor.
        while (first.elementAt(cursor.track) === null) {
            first = first.nextInMeasure;
        }

        // For the last segment, we go the last of the measure which isn't a rest.
        var last = measure.lastSegment;
        var element;
        var the_real_last = last;
        //while ((last!=null) && (((element = last.elementAt(track)) == null) || (element.type == Element.REST))) {
        while ((last != null) && (((element = _d(last, cursor.track)) == null) || (element.type != Element.CHORD))) {
            if (element != null)
                the_real_last = last;
            last = last.prevInMeasure;
        }
        //last = last.nextInMeasure;
        last = the_real_last;

        // debug:
        for (var t = 0; t < cursor.score.ntracks; t++) {
            var el = first.elementAt(t);
            console.log(t + ")" + ((el !== null) ? el.userName() : " / "));
        }

        console.log("Select from " + first.tick + " to " + last.tick + " ?");

        if (last.tick <= first.tick) {
            // Working at the end of the measure, we don't copy/paste
            console.log("-->No. Clear selection.");
            startCmd(cursor.score,"clear selection");
            cursor.score.selection.clear();
            endCmd(cursor.score,"clear selection");
            return false;
        }

        // Select the range. !! Must be surrounded by startCmd/endCmd, otherwise a cmd(" cut ") crashes MS
        var tick = last.tick;
        if (tick == cursor.score.lastSegment.tick)
            tick++; // Bug in MS with the end of score ticks
        console.log("--> Yes. Selecting from " + first.tick + "/" + cursor.staffIdx + " to " + tick + "/" + cursor.staffIdx);
        var res = false;
        startCmd(cursor.score,"select range");
        res = cursor.score.selection.selectRange(first.tick, tick, cursor.staffIdx, cursor.staffIdx + 1);
        endCmd(cursor.score,"select range");

        return res;

    }

    function getPreviousRest(segment, track) {
        var last = segment;
        var the_real_last = segment;
        var element = null;
        //while ((last!=null) && (((element = last.elementAt(track)) == null) || (element.type == Element.REST))) {
        while ((last != null) && (((element = _d(last, track)) == null) || (element.type != Element.CHORD))) {
            if ((element != null) && (element.type == Element.REST)) {
                the_real_last = last;
                break;
            }
            last = last.prevInMeasure;
        }
        element = the_real_last.elementAt(track);

        if ((element == null) || (element.type != Element.REST)) {
            console.log("Could not find a rest at the end of the measure");
            return null;
        }

        return element;

    }

    MessageDialog {
        id: invalidLibraryDialog
        icon: StandardIcon.Critical
        standardButtons: StandardButton.Ok
        title: 'Invalid libraries'
        text: "Invalid 'zparkingb/notehelper.js' or 'zparkingb/selhelper.js' versions.\nExpecting " + noteHelperVersion + " and " + selHelperVersion + ".\n" + pluginName + " will stop here."
        onAccepted: {
            Qt.quit()
        }
    }

    MessageDialog {
        id: warningDialog
        icon: StandardIcon.Warning
        standardButtons: StandardButton.Ok
        title: 'Warning'
        text: "--"
    }

    function debugMeasureLength(measure) {
        console.log(measure.timesigNominal.str + " // " + measure.timesigActual.str);
    }

    function debugSegment(segment, track) {
        var el = (segment !== null) ? segment.elementAt(track) : null;
        console.log("segment (" + ((segment !== null) ? segment.tick : "null") + ") =" +
            ((segment !== null) ? segment.segmentType : "null") +
            " (with " + ((el !== null) ? el.userName() : "null") +
            " on track " + track + ")");
    }

    function debugO(label, element, excludes) {

        if (typeof element === 'undefined') {
            console.log(label + ": undefined");
        } else if (element === null) {
            console.log(label + ": null");

        } else if (Array.isArray(element)) {
            for (var i = 0; i < element.length; i++) {
                debugO(label + "-" + i, element[i], excludes);
            }

        } else if (typeof element === 'object') {

            var kys = Object.keys(element);
            for (var i = 0; i < kys.length; i++) {
                if (!excludes || excludes.indexOf(kys[i]) == -1) {
                    debugO(label + ": " + kys[i], element[kys[i]], excludes);
                }
            }
        } else {
            console.log(label + ": " + element);
        }
    }
	
	function startCmd(score,comment) {
		score.startCmd();
		console.log(">>>>>>>>>> START CMD "+(comment?("("+comment+") "):"")+">>>>>>>>>>>>>>>>>");
	}
	
	function endCmd(score,comment) {
		score.endCmd();
		console.log("<<<<<<<<<< END CMD "+(comment?("("+comment+") "):"")+"<<<<<<<<<<<<<<<<<");
	}
}