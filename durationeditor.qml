import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import FileIO 3.0
import "zparkingb/selectionhelper.js" as SelHelper
import "zparkingb/notehelper.js" as NoteHelper
import "durationeditor"

/**********************
/* Parking B - DurationEditor - New approach for note duration edition
/* v1.3.0
/* ChangeLog:
/* 	- 1.1.0: Initial releasee
/* 	- 1.3.0.alpha1: New Tuplet functionality
/* 	- 1.3.0.beta1: Bugfix for measures <> 4/4
/* 	- 1.3.0.beta1: Improved rest augmentation
/* 	- 1.3.0.beta1: AddTuplet finalization
/* 	- 1.3.0.beta1: RemoveTuplet
/* 	- 1.3.0.beta2: Paste correct accidentals
/* 	- 1.3.0.beta2: SetDurationXyz fonctionne correctement en multi-voix: toutes les voix sont mises à jour dans tous les cas
/* 	- 1.3.0.beta2: Tie on previous rest too
/* 	- 1.3.0.beta2: Better count available the remaining duration when a tuplet is involved
/* 	- 1.3.0.beta2: Correction for the 5:4 case
/* 	- 1.3.0.beta2: Forbid setDuration and setDot within tuplets
/* 	- 1.3.0.beta2: log to file
/* 	- 1.3.0.beta2: Single Voice edition
/* 	- 1.3.0.beta2: Tuplet multivoice edition
/* 	- 1.3.0.beta2: Single voice copy/paste (incl. tuplets) copies all the annotations (incl. harmonies)
/* 	- 1.3.0.beta3: Correction in x/8 cases
/* 	- 1.3.0.beta3: consider segments with rests but annotations as non empty
/* 	- 1.3.0.beta3: new selectionhelper.js version
/* 	- 1.3.0.beta3: Qt.quit issue

/**********************************************/

MuseScore {
    menuPath: "Plugins." + pluginName
    description: "Edit the notes and rests length by moving the next notes in the measure, instead of eating them."
    version: "1.3.0"
    readonly property var pluginName: "Duration Editor"
    readonly property var selHelperVersion: "1.3.0"
    readonly property var noteHelperVersion: "1.0.5"

    readonly property var debug: false

    pluginType: "dock"
    dockArea: "left"
    requiresScore: false
    width: 450
    height: 200
	
	id: mainWindow


    readonly property var imgHeight: 32
    readonly property var imgPadding: 8

    ColumnLayout {
        // anchors.fill: parent
        width: parent.width
        y: parent.y
        Flow {
            id: layButtons
            Layout.fillWidth: true
            // anchors.fill: parent
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
                ToolTip.text: "Tie rest to preceding note/Tie note to following rest."
                onClicked: addTie()
            }

            Item {
                // height: btnTuplet.height
                height: imgHeight
                // width: btnTuplet.width+btnManualTuplet.width
                width: 50
                ImageButton {
                    id: btnTuplet
                    imageSource: "tuplets.svg"
                    imageHeight: imgHeight
                    imagePadding: imgPadding
                    // fillMode: Image.PreserveAspectCrop
                    ToolTip.text: "Convert consecutive notes/rests to and from tuplets."
                    onClicked: addRemoveTupplet(false)
                }
                ImageButton {
                    id: btnManualTuplet
                    x: btnTuplet.x + btnTuplet.width
                    y: btnTuplet.y
                    imageSource: "arrowbutton.svg"
                    imageHeight: 16
                    implicitHeight: btnTuplet.height
                    imagePadding: 2
                    //fillMode: Image.PreserveAspectCrop
                    ToolTip.text: "Manual conversion to tuplets."
                    onClicked: addRemoveTupplet(true)
                }
            }
        } // flow
/*        SmallCheckBox {
            id: chkCrossVoice
            boxWidth: 20
            text: "Cross voices edition"
            ToolTip.text: "Treat all the voices at oncee."
            checked: true
            enabled: false;
        }
*/
        RowLayout {
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
            }
            Label {
                text: "v: " + version
                font.italic: true
                font.pointSize: 8
            }
        }

    } // ColumnLayout

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
        if (debug) {
            addRemoveTupplet();
        }

    }

    function setDuration(newDuration) {
        // log to file
        if (debug) {
            console.log("Logfile: " + logfile.source);
            openLog(logfile.source);
        }

        var res = getSelection();
        var chords = res.chords;

        if (!chords || (chords.length == 0))
            return;

		if (verifySelection(chords)<0)
			return;

        setElementDuration(chords[0], newDuration, res.multivoice);

        if (debug) {
            closeLog();
        }
    }

    function insertRest(newDuration) {
        // log to file
        if (debug) {
            console.log("Logfile: " + logfile.source);
            openLog(logfile.source);
        }

        var res = getSelection();
        var chords = res.chords;

        if (!chords || (chords.length == 0))
            return;

		if (verifySelection(chords,["staff","tick"])<0)
			return;

        setElementDuration(chords[0], newDuration * (-1), res.multivoice);

        if (debug) {
            closeLog();
        }
    }

    function setDot(newDuration) {
        // log to file
        if (debug) {
            console.log("Logfile: " + logfile.source);
            openLog(logfile.source);
        }

        var res = getSelection();
        var chords = res.chords;

        if (!chords || (chords.length == 0))
            return;

		if (verifySelection(chords)<0)
			return;

        setElementDot(chords[0], newDuration, res.multivoice);

        if (debug) {
            closeLog();
        }
    }

    function setElementDot(element, dot, multivoice) {

        if (element.tuplet !== null) {
            warningDialog.text = "Cannot perform this action for elements within tuplets";
            warningDialog.open();
            return;
        }

        var current = durationTo64(element.duration);
        var analyze = analyzeDuration(current);

        logThis(current + " => " + analyze.base + "/" + analyze.ratio);

        var newDuration;

        if (dot == analyze.ratio) {
            // Same "dot", removing it
            newDuration = analyze.base;
        } else {
            newDuration = analyze.base * dot;
        }

        setElementDuration(element, newDuration, multivoice);
    }

    /**
     * newDuration>0: change the element to that duration
     * newDuration==0: delete the element
     * newDuration<0: insert a rest before the element with that duration
     */
    function setElementDuration(element, newDuration, multivoice) {

        if (element.tuplet !== null && newDuration>=0) {
            warningDialog.text = "Cannot perform this action for elements within tuplets";
            warningDialog.open();
            return;
        }

        var insertmode = (newDuration < 0);
        newDuration = Math.abs(newDuration);

        var score = curScore;

        var cur_time = element.parent.tick;

        var cursor = score.newCursor();
        cursor.track = element.track;
        cursor.rewindToTick(cur_time);

        var current = durationTo64(element.duration);
        var increment = (insertmode) ? newDuration : newDuration - current;
        logThis("setElementDuration: from " + current + " to " + newDuration + " in "+((typeof multivoice==="undefined")?"undefined":(multivoice?"multi":"single"))+" voice context");

        if (increment > 0) {

            // 0) On compte ce qu'on a comme buffer en fin de mesure
            var buffer = computeRemainingRest(cursor.measure, cursor.track, cur_time);
            logThis("Required increment is : " + increment + ", current buffer is : " + buffer);

            // 1) on coupe ce qu'on va déplacer
			var localCopy;
            var doCutPaste = selectRemaingInMeasure(cursor, insertmode, multivoice);
            switch (doCutPaste) {
            case 1:
                if (multivoice) {
                    logThis("CMD: cmd(\"cut\")");
                    cmd("cut");
                } else {
                    logThis("SingleVoice cut");
                    localCopy = copySelection(score.selection.elements);
                    // logThis("CMD: cmd(\"delete\")");
                    // cmd("delete");
                    logThis("CMD: cmd(\"pad-rest\")");
                    cmd("pad-rest");
                }
                break;
            case -1:
				logThis("!! cannot perform a duration modification of a single voice context with tuplets after.");
                warningDialog.subtitle = "Duration editor";
                warningDialog.text = "The limit of the plugin have been reached.\nIt cannot perform a duration modification of a single voice context with tuplets after.";
                warningDialog.open();
                return;

            }
            // 2) on adapte la longueur de la mesure (si on n'a pas assez de buffer)
            if (buffer < increment) {
                var delta = increment - buffer;
                logThis("buffer is < increment => adding a rest of " + delta);
                appendRest(cursor, delta, multivoice);
            } else {
                logThis("buffer is >= increment => no need to add a rest");
            }

            // 3) on adapte la durée de la note
            cursor.rewindToTick(cur_time);
            debugCursor(cursor, "before cursorToDuration");
            cursorToDuration(cursor, newDuration);
            debugCursor(cursor, "after cursorToDuration");

            var lastRestTick = cursor.tick;

            // 4) s'occuper des autres voix (uniquement quand la durée augmente)
            // 1.3.0
			if(multivoice) {
            var t_cursor = cursor.score.newCursor();
            t_cursor.rewindToTick(cur_time);
            var seg = t_cursor.segment;
            logThis("About to adapt others for tracks " + (cursor.staffIdx * 4) + " to " + ((cursor.staffIdx + 1) * 4));
            for (var t = cursor.staffIdx * 4; t < (cursor.staffIdx + 1) * 4; t++) {
                logThis("adapting others at track " + t);
                if (t === element.track)
                    continue; // on a déjà traité celui-là
                var t_el = seg.elementAt(t);
                if (t_el === null)
                    continue; // rien sur la voie t à ce tick
                var t_dur = durationTo64(t_el.duration);
                var t_newdur = t_dur + increment;
                logThis("adapting others from " + t_dur + " to " + t_newdur);
                t_cursor.track = t;
                cursorToDuration(t_cursor, t_newdur);
            }
			}

            // 5) On fait le paste
            if (doCutPaste===1) {
                // cursor.rewindToTick(cur_time);
                cursor.rewindToTick(lastRestTick); //1.3.0
                debugCursor(cursor, "rewind for paste");
                cursor.next();
                debugCursor(cursor, "paste position");

                selectCursor(cursor);
                if (multivoice) {
                    logThis("CMD: cmd(\"paste\")");
                    cmd("paste");
                } else {
                    logThis("SingleVoice paste");
					pasteSelection(cursor, localCopy);
                }
            }
            //endCmd(score);

        }
        if (increment < 0) {

            // 1) on coupe ce qu'on va déplacer
            var localCopy;
            var doCutPaste = selectRemaingInMeasure(cursor, false, multivoice);

            switch (doCutPaste) {
            case 1:
                if (multivoice) {
                    logThis("CMD: cmd(\"cut\")");
                    cmd("cut");
                } else {
                    logThis("SingleVoice cut");
                    localCopy = copySelection(score.selection.elements);
                    logThis("CMD: cmd(\"delete\")");
                    cmd("delete");
                }
                break;
            case -1:
                warningDialog.subtitle = "Duration editor";
                warningDialog.text = "The limit of the plugin have been reached.\nIt cannot perform a duration modification of a single voice context with tuplets after.";
                warningDialog.open();
                return;

            }

            // 2) on adapte la durée de la note
            cursor.rewindToTick(cur_time);
            if (newDuration != 0)
                cursorToDuration(cursor, newDuration);
            else {
                // duration 0, so replace the element by a rest
                startCmd(score);
                logThis("CMD: replace element by rest (removeElement)");
                removeElement(element);
                endCmd(score);
            }
            //cursor.element.duration=fraction(1, 2) // KO


            // 3) On fait le paste
            if (doCutPaste===1) {
                cursor.rewindToTick(cur_time);
                if (newDuration != 0)
                    cursor.next();
                selectCursor(cursor);
                if (multivoice) {
                    logThis("CMD: cmd(\"paste\")");
                    cmd("paste");
                } else {
                    logThis("SingleVoice paste");
					pasteSelection(cursor, localCopy);
                }
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
        // log to file
        if (debug) {
            logThis("Logfile: " + logfile.source);
            openLog(logfile.source);
        }

        var res = getSelection();
        var rests = res.chords;
		
		
        if (rests.length == 0) {
            logThis("NO SELECTION. QUIT HERE.");
            return;
        }

        var rest = rests[0];
        var source = null;

        var cur_time = rest.parent.tick; // getting rest's segment's tick
        var cursor = curScore.newCursor();
        cursor.track = rest.track;

        cursor.rewindToTick(cur_time);

		// current is rest
        if (rest.type === Element.REST) {

            logThis("REST ==> looking behind for a CHORD");
            logThis("REST ==> looking backward for a CHORD");
            cursor.rewindToTick(cur_time);
            if (movePrev(cursor)) {
                logThis("got a backward element");
                var candidate = cursor.element;

                if (candidate !== null) {
                    logThis("which ain't null");

                    if (candidate.type === Element.CHORD) {
                        logThis("and is a chord ==> ok");
                        source = candidate;
                    } else {
                        logThis("which ain't a chord (" + candidate.userName() + ")");
                    }
                } else {
                    logThis("which is null");
                }
            } else {
                logThis("no backward element found");
            }

            if (source == null) {
                logThis("REST ==> looking forward for a CHORD");
                cursor.rewindToTick(cur_time);
                if (moveNext(cursor)) {
                    logThis("got a next element");
                    var candidate = cursor.element;

                    if (candidate !== null) {
                        logThis("which ain't null");

                        if (candidate.type === Element.CHORD) {
                            logThis("and is a chord ==> ok");
                            source = candidate;
                        } else {
                            logThis("which ain't a chord (" + candidate.userName() + ")");
                        }
                    } else {
                        logThis("which is null");
                    }
                } else {
                    logThis("no next element found");
                }
            }
            if (source === null) {
                warningDialog.text = "Failed to tie the rest.\nThe selected note must be preceeded or followed by a chord.";
                warningDialog.open();
                return;
            }
        } // current is rest

		// current is chord
        else {
            source = rest;
            rest = null;

            logThis("CHORD ==> looking backward for a REST");
            cursor.rewindToTick(cur_time);
            if (movePrev(cursor)) {
                logThis("got a backward element");
                var candidate = cursor.element;

                if (candidate !== null) {
                    logThis("which ain't null");

                    if (candidate.type === Element.REST) {
                        logThis("and is a rest ==> ok");
                        rest = candidate;
                    } else {
                        logThis("which ain't a rest (" + candidate.userName() + ")");
                    }
                } else {
                    logThis("which is null");
                }
            } else {
                logThis("no backward element found");
            }

            if (rest == null) {
                logThis("CHORD ==> looking forward for a REST");
				cursor.rewindToTick(cur_time);
                if (moveNext(cursor)) {
                    logThis("got a next element");
                    var candidate = cursor.element;

                    if (candidate !== null) {
                        logThis("which ain't null");

                        if (candidate.type === Element.REST) {
                            logThis("and is a rest ==> ok");
                            rest = candidate;
                        } else {
                            logThis("which ain't a rest (" + candidate.userName() + ")");
                        }
                    } else {
                        logThis("which is null");
                    }
                } else {
                    logThis("no next element found");
                }
            }
            if (rest === null) {
                warningDialog.text = "Failed to tie the note.\nThe selected note must be preceeded or followed by a rest.";
                warningDialog.open();
                return;
            }

        } // current is chord

        // A source is found.
        // var note = source.notes[0];
        logThis("Got a source at " + source.parent.tick + " and a dest at " + rest.parent.tick);
        var notes = [];
        for (var i = 0; i < source.notes.length; i++) {
            // notes.push(source.notes[i].pitch);
            var n = {
                "pitch": source.notes[i].pitch,
                "tpc1": source.notes[i].tpc1,
                "tpc2": source.notes[i].tpc2
            };
            notes.push(n);
        }

        // Transforming the rest into the notes
        startCmd(curScore);

        NoteHelper.restToChord(rest, notes, true); // with keepRestDuration=true

        if (source.parent.tick < rest.parent.tick) {
            cursor.rewindToTick(source.parent.tick);
        } else {
            cursor.rewindToTick(rest.parent.tick);
        }
        selectCursor(cursor);
        cmd("chord-tie");

        cursor.rewindToTick(rest.parent.tick);
        // cursor.rewindToTick(cur_time);
        selectCursor(cursor);

        endCmd(curScore);

        if (debug) {
            closeLog();
        }
    }

    function addRemoveTupplet(ask) {
        // log to file
        if (debug) {
            logThis("Logfile: " + logfile.source);
            openLog(logfile.source);
        }

        var selection = getTupletsFromSelection();
		
        if (selection && (selection.tracks.length > 0)) {
            // Tuplets selected - Converting to regular chords
            logThis("TUPLETS FOUND FROM SELECTION");
            if (ask) {
                warningDialog.subtitle = "Tuplet conversion";
                warningDialog.text = "Cannot perform a manual tuplet conversion for this selection.\nThe manual conversion only applies to non-tuplet consecutive notes/rests.";
                warningDialog.open();
                return;
            }

            convertChordsFromTuplets(selection);

        } else if (selection && (selection.tracks.length === 0)) {
            logThis("No TUPLETS FOUND FROM SELECTION");
            selection = getTupletsCandidates();
			
			// console.log(tupletChords);

            if (selection && (selection.tracks.length > 0)) {
                // Regular chords selected - Converting to tuplets chords
                logThis("THE SELECTION CAN BE CONVERTED to TUPLETS");

				convertChordsToTuplets(selection, ask);

            } else {
                warningDialog.subtitle = "Tuplet conversion";
                warningDialog.text = "Invalid selection.\nExpecting a selection of consecutive notes/rests.";
                warningDialog.open();
                // return;
            }

        } else {
            warningDialog.subtitle = "Tuplet conversion";
            warningDialog.text = "Invalid selection.\nExpecting a selection of consecutive notes/rests or of a tuplet.";
            warningDialog.open();
            // return;
        }

        if (debug) {
            closeLog();
        }

    }

	/**
	* Determines how to convert the selection to tuplets.
	* Computes the target duration, target tuplet ratio, .... Possibly ask for it it cannot be automatically determined.
	* @see getTupletsCandidates for the `selection` object structure.
	*/
    function convertChordsToTuplets(selection, ask) {
        // Transforming regular notes into tuplets
		var track1=selection.tracks[0];
        var measure = track1.chords[0].parent.parent;
		var duration=track1.duration;

        // var measureType = measure.timesigActual.denominator;
        var measureType = measure.timesigNominal.denominator;

        logThis("Selection: " + track1.chords.length + "element, total duration: " + track1.duration);
        logThis("Measure: x/" + measureType + ", total duration: " + sigTo64(measure.timesigActual));

        var tupletN = null;
        var tupletD = null;

        var nums = [3, 5, 7, 9, 4, 6, 8];
		
		
        // En x/8 si j'ai 2 notes sélectionnées, de même durée, j'autorise aussi à faire des 2:3
		if (measureType === 8) { 
			// on garde les tracks qui ont 2 accords et de même durée
			var tsamedur=selection.tracks.filter(function(e) { 
				return e.samedur && e.chords.length==2;
			});

			// si au 1 
			if (tsamedur.length>0) 
			// if ((chords.length == 2) && (measureType == 8) && (samedur > 0))
				nums.unshift(2);
		}

        for (var i = 0; i < nums.length; i++) {
            var n = nums[i];
            if (isTupletCandidate(duration, n)) {
                tupletN = n;
                break;
            }
        }

        if (tupletN != null) {
            if (measureType == 4) {
                // 2/4, 3/4, 4/4, ...
                tupletD = Math.pow(2, Math.sqrt(tupletN) | 0); // (trunc) 3/2, 5/4, 6/4, .. 9/8, ...
            } else if (measureType == 8) {
                // 3/8, 6/8, 9/8, ...
                tupletD = 3 * (Math.max((tupletN / 3) | 0, 1));
            }
        }
        logThis("Heading to " + ((tupletN != null) ? (tupletN + ":" + tupletD + " of " + (duration / tupletN)) : "???"));

        if (ask || (tupletN == null) || (tupletD == null) || (tupletN == tupletD)) {
            manualTupletDefinitionDialog.selection = selection;
            manualTupletDefinitionDialog.duration = duration;
            manualTupletDefinitionDialog.measureType = measureType;
            manualTupletDefinitionDialog.tupletN = (tupletN != null) ? tupletN : "";
            manualTupletDefinitionDialog.tupletD = (tupletD != null) ? tupletD : "";
            manualTupletDefinitionDialog.open();
            return;
        } else {
            convertChordsToTuplets_Exectute(selection, duration, measureType, tupletN, tupletD);
        }
    }

	/**
	* Executing the conversion of the selection to tuplets.
	* Everything must be known (target duration, target tuplet ratio, ...).
	* @see getTupletsCandidates for the `selection` object structure.
	*/
    function convertChordsToTuplets_Exectute(selection, duration, measureType, tupletN, tupletD) {
        if (tupletN == null || tupletD == null) {
            warningDialog.subtitle = "Tuplet conversion";
            warningDialog.text = "Wrong tuplet definition: --" + ((tupletN) ? tupletN : "/") + ":" + ((tupletD) ? tupletD : "/") + "--";
            warningDialog.open();
            return;
        }
		
		var targets=[];
		// Storing track by track what will be pasted later
		// Rational: Dealing with the track 0's duration may alter what's on track 1 and therefor the copy we would take if we did by the time we handle the track 1.
		// So we copy everything *before* modifying anything.
		for (var t = 0; t < selection.tracks.length; t++) {
		    var track = selection.tracks[t];
			logThis("** Copying tuplet "+t+" (track "+track.track+")");

		    targets[t] = copySelection(track.chords);
		}		
		
		// Working track by track
		for (var t = 0; t < selection.tracks.length; t++) {
		    var track = selection.tracks[t];
			logThis("** Dealing with tuplet "+t+" (track "+track.track+")");

		    // Inserting the triplet

		    // 1) deleting/reducing the last elements duration until we get the right total dur
		    var targetdur = duration * tupletD / tupletN;
			if (t === 0 || !selection.multivoice) {
			    // must only be done one time if in multivoice context
			    logThis("Adapting the duration of the selection from " + duration + " to " + targetdur);
			    var delta = duration - targetdur;
			    // startCmd(curScore, "adapt last note duration");
			    for (var i = track.chords.length - 1; i >= 0; i--) {
			        var last = track.chords[i];
			        var newDuration = durationTo64(last.duration) - delta;
			        if (newDuration >= 0) {
			            setElementDuration(last, newDuration, selection.multivoice);
			            break;
			        } else {
			            // Il faut supprimer plus que le dernier
			            setElementDuration(last, 0, selection.multivoice);
			            delta = newDuration * (-1);
			        }
			    }
			}
		    // endCmd(curScore, "adapt last note duration"); // DEBUG
		    // 2) adding a tuplet
		    var cur_time = track.first_tick;
		    var cursor = curScore.newCursor();
		    cursor.track = track.track;
		    cursor.rewindToTick(cur_time);

		    startCmd(curScore, "addTuplet");
		    var actual = fraction(targetdur, 64);
		    var ratio = fraction(tupletN, tupletD);
		    var tuplet = cursor.addTuplet(ratio, actual);
		    // tuplet.bracketType=TupletBracketType.SHOW_BRACKET; // les crochets
		    // tuplet.bracketType=1; // les crochets
		    //tuplet.numberType=TupletNumberType.SHOW_RELATION; //le ratio
		    endCmd(curScore, "addTuplet");

		    // 3) re-adding the notes
		    pasteSelection(cursor, targets[t]);
			
			logThis("** Done with tuplet "+t+" (track "+track.track+")");

		}

		// if (!debug)endCmd(curScore);

    }

    function isTupletCandidate(duration, check) {
        var res = duration / check;
        return ((res | 0) == res); // trunc
    }

	/**
	* Executing the conversion of the selected tuplets to regular chords.
	* @see getTupletsFromSelection for the `selection` object structure.
	*/
    function convertChordsFromTuplets(selection) {
        // Transforming a tuplet into regular notes

		var targets=[];
		// Storing track by track what will be pasted later
		// Rational: Dealing with the track 0's duration may alter what's on track 1 and therefor the copy we would take if we did by the time we handle the track 1.
		// So we copy everything *before* modifying anything.
		for (var t = 0; t < selection.tracks.length; t++) {
		    var track = selection.tracks[t];
			logThis("** Copying tuplet "+t+" (track "+track.track+")");

		    targets[t] = copySelection(track.chords);
		}		

		// computing the new duration
        var tuplet = selection.tracks[0].chords[0].tuplet;
        var tuplet_ratio = tuplet.actualNotes / tuplet.normalNotes;
        var duration = selection.tracks[0].duration;
        var origduration = duration / tuplet_ratio;

        // for (var i = 0; i < chords.length; i++) {
        // logThis("Tuplets chords: " + chords[i].userName() + " with duration " + durationTo64(chords[i].duration));
        // }

		// Working track by track
		var cursor = curScore.newCursor();
		// 1) Remove the tuplet
		for (var t = 0; t < selection.tracks.length; t++) {
		    var track = selection.tracks[t];
			var tuplet = track.chords[0].tuplet;
		    logThis("** Removing the tuplet " + t + " (track " + track.track + ")");

		    var cur_time = track.first_tick;
		    cursor.track = track.track;
		    cursor.rewindToTick(cur_time);

		    debugCursor(cursor, "removing tuplet");

		    startCmd(curScore, "removeTuplet");
		    removeElement(tuplet);
		    // 1.3.0 dans certains cas le removeElement ne donne pas lieu à *1* silence mais à *plusieurs*, dont la *somme* a la bonne durée,
		    // il faut le refusionner ensemble
		    cursor.track = track.track;
		    cursor.rewindToTick(cur_time);
		    debugCursor(cursor, "merging resulting rests if necessary");
		    logThis("merging to " + origduration);
		    cursorToDuration(cursor, origduration);
		    endCmd(curScore, "removeTuplet");
		}
        
		// 2) Re-add the selection
		for (var t = 0; t < selection.tracks.length; t++) {
		    var track = selection.tracks[t];
		    logThis("** Dealing the tuplet " + t + " (track " + track.track + ")");
		    var cur_time = track.first_tick;
		    cursor.track = track.track;
		    cursor.rewindToTick(cur_time);
			
					    if (t === 0 || !selection.multivoice) {
		        // must only be done one time if in multivoice context
		        var rest = cursor.element;
		        debugCursor(cursor, "setting correct length of first element");
		        logThis("setting to " + duration);
		        setElementDuration(rest, duration, selection.multivoice);
		    }

			
			pasteSelection(cursor, targets[t]);
		}

    }

	/**
	* Copy segment by segment, track by track, the CHORDREST found a this segment.
	* Includes the annotations at this segment, as well as the notes and their properties
	*/
    function copySelection(chords) {
        logThis("Copying " + chords.length + " elements canidates");
        var targets = [];
        loopelements:
        for (var i = 0; i < chords.length; i++) {
            var chord = chords[i];

            if (chord.type === Element.NOTE) {
                logThis("!! note element in the selection. Using its parent's chord instead");
                chord = chord.parent;

                for (var c = 0; c < targets.length; c++) {
                    if ((targets[c].tick === chord.parent.tick) && (targets[c].track === chord.track)) {
						logThis("dropping this note, because we have already added its parent's chord in the selection");
                        continue loopelements;
					}
                }
            }

            logThis("Copying " + i + ": " + chord.userName() + " - " + (chord.duration ? chord.duration.str : "null") + ", notes: " + (chord.notes ? chord.notes.length : 0));
            var target = {
				"_element": chord,
				"tick": chord.parent.tick,
				"track": chord.track,
                "duration": (chord.duration?{
                    "numerator": chord.duration.numerator,
                    "denominator": chord.duration.denominator,
                }:null),
                "lyrics": chord.lyrics,
                "graceNotes": chord.graceNotes,
				"notes": undefined,
				"annotations": [],
				"_username": chord.userName(),
				"userName": function() { return this._username;} //must be "chords[i]"
            };

            // If CHORD, then remember the notes. Otherwise treat as a rest
            if (chord.type === Element.CHORD) {
                target.notes = chord.notes;
            };

			// Searching for harmonies & other annotations
			var seg=chord;
			while(seg && seg.type!==Element.SEGMENT) {
				seg=seg.parent
			}
			
			if(seg!==null) {
				var annotations = seg.annotations;
				//console.log(annotations.length + " annotations");
				if (annotations && (annotations.length > 0)) {
					var filtered=[];
					// annotations=annotations.filter(function(e) {
						// return (e.type === Element.HARMONY) && (e.track===chord.track);
					// });
					for(var h=0;h<annotations.length;h++) {
						var e=annotations[h];
						if (/*(e.type === Element.HARMONY) &&*/ (e.track===chord.track)) 
							filtered.push(e);
					}
					annotations=filtered;
					target.annotations=annotations;
				} else annotations=[]; // DEBUG
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

    /**
     * Returns the Chord/Rests belonging to tuplets of the selection.
     * If the selection does not contain a tuplet, an empty array is returned.
     * If the selection is containing incoherent elements (tuplet-based and non-tuplet-based elements, multiple tuplets elements, ...), "false" is returned.

	* @return false | the tuplets' elements organised by tracks
	* 	{
	*	multivoice: true|false,  
	* 	tracks: array of 
	*		{
	*       	track: track number,
    *           duration: total duration of the selection (rem: on all the tracks the selection must have the same duration)
    *           chords: array of Element.CHORD | Element.REST that belonging to the tuplet,
	*		}
	*	}
	*/
    function getTupletsFromSelection() {
        if (curScore == null)
            return false;
        var selection = curScore.selection;
        var el = selection.elements;
        var tuplets = [];
        logThis("Analyzing " + el.length + " elements in search of tuplets");
		

        for (var i = 0; i < el.length; i++) {
            var element = el[i];
            logThis("\t" + i + ") " + element.type + " (" + element.userName() + ")");
            if (element.type == Element.TUPLET) {
                tuplets.push(element);
            }
        }

// 24/5/22 on n'utilise jamais cette fonctionnalité. Celle par notes suffit
/*        if (tuplets.length != 0) {
            logThis("A tuplet bar is selected. Returning its elements");
            var parts = [];
            var tuplet = tuplets[0];
            for (var i = 0; i < tuplet.length; i++) {
                var e = tuplet[i];
                if ((e.type == Element.CHORD) || (e.type == Element.REST)) {
                    parts.push(e);
                }
            };
			var multivoice=(curScore.selection)?curScore.selection.isRange:false;
			if(!multivoice) multivoice=sameAsRange(parts);
			logThis((multivoice?"Multi voice":"Single voice")+" edition"); 
			// TODO aligner avec la nouvelle strcuture
            return {multivoice: multivoice, elements: parts};
        }
*/
        var selection = SelHelper.getChordsRestsFromSelection();
        if (selection.length == 0) {
            // empty selection
            // should return a status -1
            logThis("No selection !!");
            return false;
        }

        var tupletChords = selection.filter(function (e) {
            return (e.tuplet != null);
        });
        if (tupletChords.length == 0) {
            // a selection but no tuplets
            logThis("No tuplets in selection");
            return {multivoice: true, tracks: []};
        }

        if (tupletChords.length != selection.length) {
            // no all chords/rests have tuplets ==> ERROR
            logThis("No all chords have tuplets !!");
            return false;
        }
        logThis("All selection have tuplets");
		
		// Now that now that the selection is roughly correct, we organise this by track
		// grouping stuff by tracks
        var tracks = {};
        for (var i = 0; i < tupletChords.length; i++) {
            var e = tupletChords[i];
            var t = e.track;
            if (tracks[t] === undefined)
                tracks[t] = {
                    track: t,
                    chords: [],
                }
            tracks[t].chords.push(e);
        }
		
        logThis("Candidate tuplet selection on tracks: " + Object.keys(tracks));

		// .. flatten this into an array
		tracks = Object.keys(tracks).map(function (e) {
		    return tracks[e];
		});

        // verifying the coherence of all the tracks
		
        for (var it = 0; it < tracks.length; it++) {
            var track = tracks[it];
		
			logThis("** analyzing the tuplet candidates on track "+track.track);


			// checking if we are dealing with 1 tuplet
			var tuplet = track.chords[0].tuplet;
			var _p = tuplet.elements;
			var parts = [];
			for (var i = 0; i < _p.length; i++) {
				var e = _p[i];
				if ((e.type == Element.CHORD) || (e.type == Element.REST)) {
					parts.push(e);
				}
			};
			logThis(selection.length + " elements; " + parts.length + " parts");
			// looking if all the elements **of the first tuplet** can be found in the selection
			var remainingp = parts.filter(function (e) {
				logThis("filtering parts: " + e.parent.tick);
				var found = false;
				for (var j = 0; j < selection.length; j++) {
					// logThis("filtering parts: " + e.parent.tick + "/" + selection[j].parent.tick);
					if (selection[j].parent.tick == e.parent.tick) {
						found = true;
						break;
					}
				}
				return !found;
			});

			// looking if all the elements **of the selection** are part of the first tuplet
			var remainingc = selection.filter(function (e) {
				var found = false;
				if (e.track!==track) return false; // we analyze only what's on the current track
				for (var j = 0; j < parts.length; j++) {
					// logThis("filtering selection: " + e.parent.tick + "/" + parts[j].parent.tick);
					if (parts[j].parent.tick === e.parent.tick) {
						found = true;
						break;
					}
				}
				return !found;
			});
			logThis("Have we found enverything ? Remaining parts: " + remainingp.length + " parts, Remaining selection:" + remainingc.length + " chords");

			// 16/3/22: no testing this one any more. All I care is that my selection belongs to 1 and only 1 tuplet.
			// if ((remainingp.length != 0) || (remainingc.length != 0)) {
			if ((remainingc.length != 0)) {
				// all chords/rests are not part of the same tuplet ==> ERROR
				logThis("--> No. The selection on track "+track.track+" belongs to different tuplets.");
				return false;
			} else {
				logThis("--> Yes. The selection on track "+track.track+" belongs to one unique tuplet.");
			}
			
			track.chords=undefined; // clearing this property
			track.chords=parts;
			
			// ensuring all tuplets candidates are starting at the same tick
            track.first_tick = track.chords[0].parent.tick;

            if (it > 0 && tracks[it - 1].first_tick !== track.first_tick) {
                logThis("Multi track selection does not start at the same tick");
                return false;
            }
			
            // computing duration and ensuring an equal duration
            track.duration = 0;
            for (var i = 0; i < track.chords.length; i++) {
                var dur = durationTo64(track.chords[i].duration);
                track.duration += dur;
                logThis("From tuplets elements: " + track.chords[i].userName() + " with duration " + dur);
            }

            if (it > 0 && tracks[it - 1].duration !== track.duration) {
                logThis("Multi track selection does not have the same duration");
                return false;
            }

			

		}
		
		var multivoice=(curScore.selection)?curScore.selection.isRange:false;
		if(!multivoice) multivoice=sameAsRange(parts);
		logThis((multivoice?"Multi voice":"Single voice")+" edition"); 
		return {multivoice: multivoice, tracks: tracks};

    } // getTupletsFromSelection


	/**
	* Analyse the selection for candidates for a to-tuplet conversion.
	* @return false | the candidate elements organised by involved track, and some metadata:
	* 	{
	*	multivoice: true|false,  
	* 	tracks: array of 
	*		{
	*       	track: track number
    *           duration: total duration of the selection (rem: on all the tracks the selection must have the same duration)
	*			samedur: true|false if all the chord elements have the same duration
    *           chords: array of Element.CHORD | Element.REST,
	*		}
	*	}
	*/
    function getTupletsCandidates() {
        // we have to ensure that we have a continuous selection
        var selection = SelHelper.getChordsRestsFromSelection();

        if (selection.length == 0)
            return false;

        selection.sort(function (a, b) {
            if (a.parent.tick === b.parent.tick)
                return a.track - b.track;
            return a.parent.tick - b.parent.tick;
        });

        // grouping stuff by tracks
        var tracks = {};
        for (var i = 0; i < selection.length; i++) {
            var e = selection[i];
            var t = e.track;
            if (tracks[t] === undefined)
                tracks[t] = {
                    track: t,
                    chords: [],
                    duration: null
                }
            tracks[t].chords.push(e);
        }
		
        logThis("Candidate tuplet selection on tracks: " + Object.keys(tracks));
		
		// .. flatten this into an array
		tracks = Object.keys(tracks).map(function (e) {
		    return tracks[e];
		});

        // verifying the coherence of all the tracks

        for (var it = 0; it < tracks.length; it++) {
            var track = tracks[it];
			
			logThis("** analyzing the tuplet candidates on track "+track.track);

            // sorting by ascending tick
            track.chords = track.chords.sort(function (a, b) {
                return a.parent.tick - b.parent.tick;
            });

            var selt = track.chords;

            // ensuring all tuplets candidates are starting at the same tick
            track.first_tick = selt[0].parent.tick;

            if (it > 0 && tracks[it - 1].first_tick !== track.first_tick) {
                logThis("Multi track selection does not start at the same tick");
                return false;
            }

            // computing duration and ensuring an equal duration
            track.duration = 0;
            track.samedur = 0;
            for (var i = 0; i < track.chords.length; i++) {
                var dur = durationTo64(track.chords[i].duration);
                track.duration += dur;
                logThis("To tuplets elements: " + track.chords[i].userName() + " with duration " + dur);
                if (track.samedur == 0)
                    track.samedur = dur;
                else if ((track.samedur > 0) && (track.samedur !== dur))
                    track.samedur = -1;
            }

            if (it > 0 && tracks[it - 1].duration !== track.duration) {
                logThis("Multi track selection does not have the same duration");
                return false;
            }

            //debug
            logThis("ticks: " + selection.map(function (e) {
                    return e.parent.tick + "/" + e.track;
                }).join(" - "));

            // looking for consecutiveness of notes
            var cursor = curScore.newCursor();
            cursor.track = track.track;
            cursor.rewindToTick(track.first_tick);

            logThis("0) " + selt[0].parent.tick + "/" + selt[0].track);

            for (var i = 1; i < selt.length; i++) {
                var sel = selt[i];
                logThis(i + ") " + sel.parent.tick);
                var next = moveNextInMeasure(cursor) ? cursor.element : null;

                if ((next == null) || (sel.parent.tick != next.parent.tick)) {
                    logThis("Selection mistmatch: expecting " + sel.parent.tick + ", found: " + ((next != null) ? next.parent.tick : "null"));
                    return false;
                } else {
                    logThis("Selection match: expecting " + sel.parent.tick + ", found: " + next.parent.tick + " (" + next.userName() + ")");

                }
            }

        }

		var multivoice=(curScore.selection)?curScore.selection.isRange:false;
		if(!multivoice) multivoice=sameAsRange(selection);
		logThis((multivoice?"Multi voice":"Single voice")+" edition"); 

        logThis("The selection is valid");
        return {multivoice: multivoice, tracks: tracks};

    } // getTupletsCandidates

    function getSelection() {
        var chords = SelHelper.getChordsRestsFromCursor();

        if (chords && (chords.length > 0)) {
            logThis("CHORDS FOUND FROM CURSOR");
        } else {
            chords = SelHelper.getChordsRestsFromSelection();
            if (chords && (chords.length > 0)) {
                logThis("CHORDS FOUND FROM SELECTION");
            } else
                chords = [];
        }

        // on trie par tick puis par voie
        chords = chords.sort(function (a, b) {
            if (a.parent.tick !== b.parent.tick) {
                return a.parent.tick - b.parent.tick;
            } else {
                return a.track - b.track;
            };
        });

        for(var i=0;i<chords.length;i++) {
        var el=chords[i];
        logThis(el.parent.tick+": "+el.track+" ("+el.duration.str+") "+": "+el.userName());
        }
		

		var multivoice=(curScore.selection)?curScore.selection.isRange:false;
		if(!multivoice) multivoice=sameAsRange(chords);

		logThis((multivoice?"Multi voice":"Single voice")+" edition"); 

        return {multivoice: multivoice, chords: chords};
    }
	
	/**
	* Tests that the selection doesn't span over
	* - multiple ticks
	* - multiple staves
	* - have the same duration
	*/
	function verifySelection(selection, what) {
	    if (selection.length === 0)
	        return -1;

		logThis("Verifying the selection coherences:");

		logThis("- #elements : "+selection.length); 

	    // ticks
	    if (!what || (what === "tick") || (what.indexOf("tick") > -1)) {

	        var tmp = selection.map(function (e) {
	            return e.parent.tick
	        }).sort(function (a, b) {
	            return a - b;
	        });
			
			logThis("- ticks: "+tmp);
			
	        if (tmp[0] !== tmp[selection.length - 1]) {
	            warningDialog.subtitle = "Duration editor";
	            warningDialog.text = "Invalid selection. The selection cannot span over multiple ticks.";
	            warningDialog.open();
	            return -2;
	        }

	    }
	    // staff
	    if (!what || (what === "staff") || (what.indexOf("staff") > -1)) {
	        tmp = selection.map(function (e) {
	            return (e.track / 4) | 0
	        }).sort(function (a, b) {
	            return a - b;
	        });
			
			logThis("- staves: "+tmp);
	        
			if (tmp[0] !== tmp[selection.length - 1]) {
	            warningDialog.subtitle = "Duration editor";
	            warningDialog.text = "Invalid selection. The selection cannot span over multiple staves.";
	            warningDialog.open();
	            return -3;
	        }
	    }
	    // duration
	    if (!what || (what === "duration") || (what.indexOf("duration") > -1)) {
	        tmp = selection.map(function (e) {
	            return elementTo64Effective(e)
	        }).sort(function (a, b) {
	            return a - b;
	        });

			logThis("- durations: "+tmp);

	        if (tmp[0] !== tmp[selection.length - 1]) {
	            warningDialog.subtitle = "Duration editor";
	            warningDialog.text = "Invalid selection. The selection's elements must have the same duration.";
	            warningDialog.open();
	            return -4;
	        }
	    }
	    return 0;

	}
	/**
	* Tells whether a selection which is not of type Range (selection.isRange) can behave like a range (i.e. every elements of all the voices are selected-
	*/ 
	function sameAsRange(selection) {
		logThis("Assessing if non-Range selection is similar to a range selection");
		var fMeasure, lMeasure;
		var selectedTracks=[];
		var usedTracks=[];

        for (var i = 0; i < selection.length; i++) {
            var element = selection[i];

            var seg = element;
            while (seg && seg.type !== Element.SEGMENT) {
                seg = seg.parent;
            }

            if (seg !== null) {
                var tick = seg.tick;
                var measure=seg.parent;
				element.tick = tick; // enrich the element with its tick
                
				if (!fMeasure || measure.firstSegment.tick<fMeasure.firstSegment.tick)
					fMeasure=measure;
                
				if (!lMeasure || measure.firstSegment.tick>lMeasure.firstSegment.tick)
					lMeasure=measure;
				
				if(selectedTracks.indexOf(element.track)<0)
					selectedTracks.push(element.track);
                
            }
        }

		selectedTracks=selectedTracks.sort(function(a,b) { return a-b;});

        logThis("Selection from measure " + fMeasure.firstSegment.tick  + " to " + lMeasure.firstSegment.tick + " on tracks " + selectedTracks);

		if(!fMeasure.is(lMeasure)) {
			logThis("!!Multiuple measure selection. Should not happen in function `sameAsRange`");
			return false;
		}

		// converting the tracks detected in the selection to the tracks of the staves involved. E.g. selection is on track 1 => tracks from the staff are from 0 to 3.
        var fTrack = selectedTracks[0]/4;
		fTrack=(fTrack | 0) * 4; // trunc
        var lTrack = selectedTracks[0]/4;
		lTrack=(lTrack | 0) * 4 + 3; // trunc

        logThis("Comparing from tracks " + fTrack + " to " + lTrack);

		// detecting which tracks are used in the current staff
		// by detecting what is are the tracks having an element at the begining of the measure
		var segment=fMeasure.firstSegment;
		loopingsegments:
		while(segment && segment.tick===fMeasure.firstSegment.tick) {
		for (var t = fTrack; t <= lTrack; t++) {
		    var el = _d(segment, t);
		    if ((el !== null) && (usedTracks.indexOf(t) < 0))
		        usedTracks.push(t);
		};
		segment = segment.nextInMeasure; // moving away from bars, timesig, clef, ... which are only on the voice 0
		}
		logThis("The measure's first segment has elements on tracks "+usedTracks); 


		// comparing the selectedTracks and the usedTracks
		var foundall=(usedTracks.filter(function(e) {
			return selectedTracks.indexOf(e)<0;
		}).length===0);
	
        
        if (foundall) logThis("SIMILAR TO RANGE"); else logThis("NOT SIMILAR TO RANGE");
		return foundall;
		
		
	}
/*	function sameAsRange(selection) {
		logThis("Assessing if non-Range selection is similar to a range selection");
        var fTick, lTick;
        var fTrack, lTrack;

        for (var i = 0; i < selection.length; i++) {
            var element = selection[i];

            var seg = element;
            while (seg && seg.type !== Element.SEGMENT) {
                seg = seg.parent;
            }

            if (seg !== null) {
                var tick = seg.tick;
                element.tick = tick; // enrich the element with its tick
                
                
                if (!fTick || fTick > tick)
                    fTick = tick;
                if (!lTick || lTick < tick)
                    lTick = tick;

                if (!fTrack || fTrack > element.track)
                    fTrack = element.track;
                if (!lTrack || lTrack < element.track)
                    lTrack = element.track;
            }
        }



        console.log("Selection from " + fTick + "/" + fTrack + " to " + lTick + "/" + lTrack);

		// converting the tracks detected in the selection to the tracks of the staves involved. E.g. selection is on track 1 => tracks from the staff are from 0 to 3.
        fTrack = fTrack/4;
		fTrack=(fTrack | 0) * 4; // trunc
        lTrack = lTrack/4;
		lTrack=(lTrack | 0) * 4 + 3; // trunc

        console.log("Comparing from " + fTick + "/" + fTrack + " to " + lTick + "/" + lTrack);

        var cursor = curScore.newCursor();
        cursor.rewindToTick(fTick);
        var segment = cursor.segment;
        var foundall = true;
		// TODO buggy : ne détecte pas les cas en quiconce
        while (foundall && segment && segment.tick <= lTick) {
            for (var t = fTrack; t <= lTrack && foundall; t++) {
                var element = segment.elementAt(t);
                if (!element)
                    continue;

                console.log(segment.tick + "/" + t + ": " + element.userName());

                foundall = false;
                for (var i = 0; i < selection.length; i++) {
                    var sel = selection[i];

                                    console.log("- "+sel.tick + "/" + sel.track + ": " + sel.userName());

                    if ((sel.tick === segment.tick)
                         && (sel.type === element.type)
                         && (sel.track === t)) {
                         console.log(" found !!");
                        foundall = true;
                        break;
                    }
                }
                
                if (!foundall) console.log(" not found --");

            }
			
			segment=segment.next;

        }
        
        if (foundall) console.log("SIMILAR TO RANGE"); else console.log("NOT SIMILAR TO RANGE");
		return foundall;
		
		
	}
*/
    function cursorToDuration(cursor, target) {

        var analyze = analyzeDuration(target);
        var base = analyze.base;
        var ratio = analyze.ratio;

        logThis(target + " : " + base + "/" + ratio);

        selectCursor(cursor);
        var cmdline = "pad-note-" + (64 / base);
        logThis("CMD: cmd(\"" + cmdline + "\")");
        cmd(cmdline);

        if (analyze.half != null) {
            logThis("Dealing with \"1.25\" ratio (" + ratio + ")");
            base = base / 2;

            cmdline = "pad-note-" + (64 / base);
            logThis("CMD: cmd(\"" + cmdline + "\")");
            cmd(cmdline);

            moveNextInMeasure(cursor);
            ratio = 1; // we don't apply any dot on this segment. We'll apply one on the next one.
            // we repeat the same process with halfed duration
            cursorToDuration(cursor, base * analyze.half);
        }

        switch (ratio) {
        case 1.5:
            logThis("CMD: cmd(\"pad-dot\")");
            cmd("pad-dot")
            break;
        case 1.75:
            logThis("CMD: cmd(\"pad-dotdot\")");
            cmd("pad-dotdot")
            break;

        case 1.875:
            logThis("CMD: cmd(\"pad-dot3\")");
            cmd("pad-dot3")
            break;
        case 1.9375:
            logThis("CMD: cmd(\"pad-dot4\")");
            cmd("pad-dot4")
            break;
        case 1:
            // 0 is normal. No reason to complain about.
            break;
        default:
            logThis("!! Cannot find a dot for " + ratio);
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
    function appendRest(cursor, increment, multivoice) {
        var measure = cursor.measure;
        debugMeasureLength(measure);

        if (increment <= 0)
            return;

        // We don't have enough, so we increase by what's msiing
        var sig = measure.timesigActual;
        var sigNum = sigTo64(sig) + increment;
        logThis("Increasing from " + sigTo64(sig) + " to " + sigNum);

        startCmd(cursor.score, "appendRest");
        logThis("CMD: Modify timesigActual");
        measure.timesigActual = fraction(sigNum, 64);
        debugMeasureLength(measure);

        /*var tick = Math.min(measure.lastSegment.tick, cursor.score.lastSegment.tick - 1); // BUG in MS, One cannot rewind to the last score tick

        logThis(measure.lastSegment.tick + " vs. " + cursor.score.lastSegment.tick);
        cursor.rewindToTick(tick);
        cursor.prev();
        selectCursor(cursor);
         */

        //var last = cursor.element;
        //var last = _d(cursor.segment, cursor.track);
		
		var fTrack=multivoice?cursor.staffIdx*4:cursor.track;
		var lTrack=multivoice?cursor.staffIdx*4+3:cursor.track;
		
		for(var t=fTrack;t<=lTrack;t++) {
		
        var last = getPreviousRest(measure.lastSegment, t);
        logThis(" track "+t+"'s last : " + ((last !== null) ? last.userName() : " / "));

        if (last != null) {
            // var orig = durationTo64(last.duration); //
            var orig = elementTo64Effective(last);
            var target = orig + increment;
            var tick = last.parent.tick;
			var tcursor=cursor.score.newCursor();
			tcursor.track=t;
            tcursor.rewindToTick(tick);
            cursorToDuration(tcursor, target);
        }
		
		}
        endCmd(cursor.score, "appendRest");
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
        var theoreticalMax = sigTo64(measure.timesigNominal);
        logThis("Required decrement is : " + increment + ", current available in measure is : " + (sigA - theoreticalMax)); // 16/3/22: was 64
        increment = sigA - Math.max(sigA - increment, theoreticalMax); // 16/3/22: was 64
        // réduction au-delà de ce qui est disponible, on ne fait rien
        if (increment <= 0)
            return;

        // 2) Computing available rest duration
        var available = computeRemainingRest(measure, null); //  we count the available rest, **whathever the tracks**
        logThis("Required decrement is : " + increment + ", current available as rest is : " + available);

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
                logThis("CMD: cmd(\"time-delete\")");
                cmd("time-delete");
                remaining -= orig;
            } else {
                // The rest is too big. Splitting it in 2.
                var split = orig / 2;
                var tick = element.parent.tick;
                cursor.rewindToTick(tick);
                cursorToDuration(cursor, split);
                logThis("Element too big for time-delete (looking for " + increment + ", found " + orig + ") => splitting it");
            }

        }

        if (remaining > 0) {
            logThis("!! Couldn't time-delete all. Looking for " + increment + ", remaining is " + remaining);
        }

        increment -= remaining; // keep aligned how I will reduce the measure to what I have been able to time-delete

        // 4) Adapting the measure length
        var target = sigA - increment;
        startCmd(cursor.score, "removeRest");
        logThis("CMD: Modify timesigActual");
        measure.timesigActual = fraction(target, 64);
        endCmd(cursor.score, "removeRest");
        debugMeasureLength(measure);

    }

    /**
     * Effective duration of an element (so taking into account the tuplet it belongs to)
     */
    function elementTo64Effective(element) {
        // if (!element.duration)
        // return 0;
        var dur = durationTo64(element.duration);
        if (element.tuplet !== null) {
            dur = dur * element.tuplet.normalNotes / element.tuplet.actualNotes;
        }
        return dur;
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
    function computeRemainingRest(measure, track, abovetick) {
        var last = measure.lastSegment;
        var duration = 0;

        logThis("Analyzing track " + (((track !== undefined) && (track != null)) ? track : "all") + ", above " + (abovetick ? abovetick : "-1"));

        if ((track !== undefined) && (track != null)) {
            duration = _computeRemainingRest(measure, track, abovetick);
            return duration;

        } else {
            duration = 999;
            // Analyze made on all tracks
            for (var t = 0; t < curScore.ntracks; t++) {
                logThis(">>>> " + t + "/" + curScore.ntracks + " <<<<");
                var localavailable = _computeRemainingRest(measure, t, abovetick);
                logThis("Available at track " + t + ": " + localavailable + " (" + duration + ")");
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
    function _computeRemainingRest(measure, track, abovetick) {
        var last = measure.lastSegment;
        var duration = sigTo64(measure.timesigActual);

        // setting the limit until which to look for rests
        abovetick = (abovetick === undefined) ? -1 : abovetick;

        logThis("_computeRemainingRest: " + (((track !== undefined) && (track != null)) ? track : "all") + ", above tick " + (abovetick ? abovetick : "-1"));

        if ((track !== undefined) && (track != null)) {
            // Analyze limited to one track
            var inTail = true;
            while ((last != null)) {
                var element = _d(last, track);
                // if ((element != null) && ((element.type == Element.CHORD) )) {
                if ((element != null) && ((element.type == Element.CHORD) || (last.tick <= abovetick))) { // 16/3/22
                    if (inTail)
                        logThis("switching outside of available buffer");
                    // As soon as we encounter a Chord, we leave the "rest-tail"
                    inTail = false;
                }
                if ((element != null) && ((element.type == Element.REST) || (element.type == Element.CHORD)) && !inTail) {
                    // When not longer in the "rest-tail" we decrease the remaing length by the element duration
                    // var eldur=durationTo64(element.duration);
                    // 1.3.0 take into account the effective dur of the element when within a tuplet
                    var eldur = elementTo64Effective(element);
                    duration -= eldur;
                }
                last = last.prevInMeasure;
            }
        }

        duration = Math.round(duration);
        return duration;
    }

    function _d(last, track) {
        var el = last.elementAt(track);
        logThis(" At " + last.tick + "/" + track + ": " + ((el !== null) ? el.userName() : " / "));
        return el;
    }

    /*function selectCursor(cursor) {
    var el = cursor.element;
    //logThis(el.duration.numerator + "--"+el.duration.denominator);
    if (el.type === Element.CHORD)
    el = el.notes[0];
    else if (el.type !== Element.REST)
    return false;
    cursor.score.selection.select(el);

    }*/

    function selectCursor(cursor) {
        var el = cursor.element;
        //logThis(el.duration.numerator + "--"+el.duration.denominator);
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

        debugSegment(cursor.segment, cursor.track);

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

        debugSegment(cursor.segment, cursor.track);
        var first = cursor.segment.prev;
        debugSegment(first, cursor.track);

        // for the first segment: we go the first previous *existing* element on the same track.
        while (first && ((first.segmentType != 512) || (first.elementAt(cursor.track) === null))) {
            first = first.prev;
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
     * Sélectionne la fin mesure à partir du curseur, non compris les derniers silences,  mais  y compris le curseur si (include=true).
     * @return 1 si une sélection a été faite, 0 s'il n'y avait rien à sélectionner, -1 en cas d'impossibilité/erreur à sélectionner.
     *
     */
    function selectRemaingInMeasure(cursor, include, multivoice) {
        logThis("selectRemaingInMeasure: ");
        var measure = cursor.measure;
        //var first = cursor.segment.nextInMeasure;
        var first = (include === undefined || !include) ? cursor.segment.nextInMeasure : cursor.segment;
        // for the first segment: we go the next *existing* element after the one at the cursor.
        while (first && first.elementAt(cursor.track) === null) {
            first = first.nextInMeasure;
        }
		
		if(!first) {
            logThis("We are at the very of the measure/ Nothing to be selected.");
            startCmd(cursor.score, "clear selection");
            cursor.score.selection.clear();
            endCmd(cursor.score, "clear selection");
            return false;
		}

        // For the last segment, we go the last of the measure which isn't a rest.
        var last = measure.lastSegment;
        var element;
        var the_real_last = last;
		logThis("- searching for last non rest segment");
		var fTrack=multivoice?cursor.staffIdx*4:cursor.track;
		var lTrack=multivoice?cursor.staffIdx*4+3:cursor.track;
		// Je remonte depuis la fin. Tant que je trouve qqch et que ce qqch n'est pas un accord ou n'est pas dans un tuplet, alors je continue à remonter
        // while ((last != null) && (((element = _d(last, cursor.track)) == null) || ((element.type != Element.CHORD) && (element.tuplet === null)))) { // 1.3.0 un élement dans un tuplet, on arrête
		loopingsegments:
        while (last!==null)  {
			for(var track=fTrack;track<=lTrack;track++) {
				// Causes for stopping
				// 3) There are annotations at this segment for this track
				var annotations=last.annotations;
				for(var i=0;i<annotations.length;i++) {
					if (annotations[i].track===track) 
						break loopingsegments;
				}



				var element= _d(last, track);

				if (element !== null) {
					// Causes for stopping
					// 1) The element is a Chord
					// 2) The element belongs to a tuplet
					debugSegment(last, track, "last segment's candidate:");
					if ((element.type === Element.CHORD) || (element.tuplet)) 
						break loopingsegments;
					
					the_real_last = last;
					break;
				}
			}
            last = last.prevInMeasure;
        }
        last = the_real_last;
			debugSegment(last, track, "last segment's best:");

        // debug:
        for (var t = 0; t < cursor.score.ntracks; t++) {
            var el = first.elementAt(t);
            logThis(t + ")" + ((el !== null) ? el.userName() : " / "));
        }

        logThis("Select from " + first.tick + " to " + last.tick + " ?");

        // if (last.tick <= first.tick) {
        if (last.tick < first.tick) {
            // Working at the end of the measure, we don't copy/paste
            logThis("-->No. Clear selection.");
            startCmd(cursor.score, "clear selection");
            cursor.score.selection.clear();
            endCmd(cursor.score, "clear selection");
            return false;
        }

        // Select the range. !! Must be surrounded by startCmd/endCmd, otherwise a cmd(" cut ") crashes MS
        var tick = last.tick;
        if (tick == cursor.score.lastSegment.tick)
            tick++; // Bug in MS with the end of score ticks

        var res;
        // res=cursor.score.selection.selectRange(first.tick, tick, cursor.staffIdx, cursor.staffIdx + 1);

        // if (chkCrossVoice.checked) {
        if (multivoice) {
            logThis("--> Yes. Selecting from " + first.tick + "/" + (cursor.staffIdx*4) + " to " + tick + "/" + (cursor.staffIdx*4 + 3));
			startCmd(cursor.score, "select multivoice range");
            res = cursor.score.selection.selectRange(first.tick, tick, cursor.staffIdx, cursor.staffIdx + 1);
			endCmd(cursor.score, "select multivoice range");

			return (res?1:0);
        } else {

            cursor.score.selection.clear();
            var curstmp = cursor.score.newCursor();
			curstmp.track = cursor.track;

            res = false;
			var hasTuplet=false;

            logThis("--> Yes. Selecting from " + first.tick + "/" + cursor.track + " to " + tick + "/" + cursor.track);

			startCmd(cursor.score, "select singlevoice range");

            curstmp.rewindToTick(first.tick);
            // curstmp.filter = Segment.All;
            curstmp.filter = Segment.ChordRest;
            var seg = curstmp.segment;
            while (seg != null && seg.tick < tick && !hasTuplet) { // "<tick" pcq le dernier tick ne doit pas être inclus
                logThis("---- at tick " + seg.tick);
                // var el = seg.elementAt(t, true); // ??? "true" ???
                // var el = _d(seg, cursor.track); //
                var el = seg.elementAt(cursor.track);
				if ((el!==null) && (el.tuplet)) {
					hasTuplet=true;
					break;
				}
				// element level
                if ((el != null) && (el.parent.tick === seg.tick)) {
                    if (el.type === Element.CHORD) {
                        var cnotes = el.notes;
                        for (var j = 0; j < cnotes.length; j++) {
                            var r = cursor.score.selection.select(cnotes[j], true);
                            logThis("adding " + cnotes[j].userName() + " (" + el.parent.tick + ") to selection");
                            res = res || r;
                        }
                    } else {
                        logThis("adding " + el.userName() + " (" + el.parent.tick + ") to selection");
                        var r = cursor.score.selection.select(el, true);
                        res = res || r;
                    }

                    if ((el.elements) && (el.elements.length > 0)) {
                        var celements = el.elements;
                        for (var j = 0; j < celements.length; j++) {
                            cursor.score.selection.select(celements[j], true);
                            logThis("adding " + celements[j].userName() + " (" + el.parent.tick + ") to selection");
                        }
                    }
                } else {
                    logThis("no element found at this tick " + ((el != null) ? ("(" + el.parent.tick + ")") : ""));
                }

                // seg = seg.next;
                // seg = curstmp.next; // (-) déborde de la mesure, (+) ne prend que ce qu'on veut
                seg = seg.nextInMeasure;
            }
        endCmd(cursor.score, "select singlevoice range");

        if (hasTuplet)
            return -1;
        else
            return (res ? 1 : 0);
        }

    }

    function getPreviousRest(segment, track) {
        var last = segment;
        var the_real_last = segment;
        var element = null;
        //while ((last!=null) && (((element = last.elementAt(track)) == null) || (element.type == Element.REST))) {
        while ((last != null) && (((element = _d(last, track)) == null) || ((element.type != Element.CHORD) /*&& (element.tuplet===null)*/))) { /* //1.3.0 Rest within tuplets cannot be used */
            if ((element != null) && (element.type == Element.REST)) {
                the_real_last = last;
                break;
            }
            last = last.prevInMeasure;
        }
        element = the_real_last.elementAt(track);

        if ((element == null) || (element.type != Element.REST)) {
            logThis("Could not find a rest at the end of the measure");
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
            mainWindow.parent.Window.window.close(); //Qt.quit()
        }
    }

    MessageDialog {
        id: warningDialog
        icon: StandardIcon.Warning
        standardButtons: StandardButton.Ok
        title: 'Warning' + (subtitle ? (" - " + subtitle) : "")
        property var subtitle
        text: "--"
        onAccepted: {
            subtitle = undefined;
        }
    }
    Dialog {
        id: manualTupletDefinitionDialog
        title: "Define tuplet..."
        //modal: true
        standardButtons: Dialog.Save | Dialog.Cancel

        property var selection
        property var duration
        property var measureType
        property alias tupletN: txtTupletN.text
        property alias tupletD: txtTupletD.text

        RowLayout {
            anchors.fill: parent

            Item { // spacer
                implicitHeight: 10
                Layout.fillWidth: true
            }
            Label {
                text: "Ratio:"
            }

            TextField {
                id: txtTupletN
                validator: IntValidator {
                    bottom: 2;
                    top: 99;
                }
                Layout.fillWidth: false
                Layout.minimumWidth: 40
                Layout.preferredWidth: Layout.minimumWidth
                placeholderText: "3"
                maximumLength: 2
                selectByMouse: true

            }
            Label {
                text: "/"
            }

            TextField {
                id: txtTupletD
                validator: IntValidator {
                    bottom: 2;
                    top: 99;
                }
                Layout.fillWidth: false
                Layout.minimumWidth: 40
                Layout.preferredWidth: Layout.minimumWidth
                placeholderText: "2"
                maximumLength: 2
                selectByMouse: true
            }
            Item { // spacer // DEBUG Item/Rectangle
                implicitHeight: 10
                Layout.fillWidth: true
            }

        }

        onAccepted: {
            var tN = parseInt(txtTupletN.text);
            var tD = parseInt(txtTupletD.text);
            logThis("==> " + tN + ":" + tD);

            if ((tN !== tN) || (tD !== tD)) { // testing NaN
                warningDialog.subtitle = "Tuplet conversion";
                warningDialog.text = "Invalid ratio. Only numbers are allowed.";
                warningDialog.open();
                return;
            }
            manualTupletDefinitionDialog.close();

            convertChordsToTuplets_Exectute(selection, duration, measureType, tN, tD);
        }
        onRejected: manualTupletDefinitionDialog.close();

    }

    function logThis(text) {
        console.log(text);

        if (debug) {
            logn(text);
        }

    }
    function debugCursor(cursor, label) {
        var l = (label !== undefined) ? (label + ": ") : "";
        logThis(l + "cursor at: " + cursor.tick);
    }

    function debugMeasureLength(measure) {
        logThis(measure.timesigNominal.str + " // " + measure.timesigActual.str);
    }

    function debugSegment(segment, track, label) {
        var el = (segment !== null) ? segment.elementAt(track) : null;
        logThis((label?(label+" "):"")+"segment (" + ((segment !== null) ? segment.tick : "null") + ") =" +
            ((segment !== null) ? segment.segmentType : "null") +
            " (with " + ((el !== null) ? el.userName() : "null") +
            " on track " + track + ")");
    }

    function startCmd(score, comment) {
        score.startCmd();
        logThis(">>>>>>>>>> START CMD " + (comment ? ("(" + comment + ") ") : "") + ">>>>>>>>>>>>>>>>>");
    }

    function endCmd(score, comment) {
        score.endCmd();
        logThis("<<<<<<<<<< END CMD " + (comment ? ("(" + comment + ") ") : "") + "<<<<<<<<<<<<<<<<<");
    }

    function debugO(label, element, excludes, isinclude) {
        if (typeof isinclude === 'undefined') {
            isinclude = false; // by default the exclude is an exclude list.otherwise it is an include
        }
        if (!Array.isArray(excludes)) {
            excludes = [];
        }

        if (typeof element === 'undefined') {
            logThis(label + ": undefined");
        } else if (element === null) {
            logThis(label + ": null");

        } else if (Array.isArray(element)) {
            for (var i = 0; i < element.length; i++) {
                debugO(label + "-" + i, element[i], excludes, isinclude);
            }

        } else if (typeof element === 'object') {

            var kys = Object.keys(element);
            for (var i = 0; i < kys.length; i++) {
                if ((excludes.indexOf(kys[i]) == -1) ^ isinclude) {
                    debugO(label + ": " + kys[i], element[kys[i]], excludes, isinclude);
                }
            }
        } else {
            logThis(label + ": " + element);
        }
    }

    FileIO {
        id: logfile
        source: tempPath() + "/durationeditor.log" // = TEMP folder
    }
}
