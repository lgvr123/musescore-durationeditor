import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import "zparkingb/selectionhelper.js" as SelHelper
import "durationeditor"

MuseScore {
    menuPath: "Plugins." + pluginName
    description: "Edit the notes and rests length by moving the next notes in the measure, instead of eating them."
    version: "1.1.0"
    readonly property var pluginName: "Duration Editor"
    readonly property var selHelperVersion: "1.2.0"

    pluginType: "dock"
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
            ToolTip.text: "Whole/Semibreve"
            onClicked: setDuration(64);
        }

        ImageButton {
            imageSource: "blanche.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Half/Minim"
            onClicked: setDuration(32);
        }

        ImageButton {
            imageSource: "noire.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Quarter/Crotchet"
            onClicked: setDuration(16);
        }

        ImageButton {
            imageSource: "croche.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Eighth/Quaver"
            onClicked: setDuration(8);
        }

        ImageButton {
            imageSource: "double.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Sixteenth/Semiquaver"
            onClicked: setDuration(4);
        }

        ImageButton {
            imageSource: "triple.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Thirty-second/Demisemiquaver"
            onClicked: setDuration(2);
        }

        ImageButton {
            imageSource: "quadruple.svg"
            imageHeight: imgHeight
            imagePadding: imgPadding
            ToolTip.text: "Sixty-fourth/Hemidemisemiquaver"
            onClicked: setDuration(1);
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

    }

    onRun: {

        if ((typeof(SelHelper.checktVersion) !== 'function') || !SelHelper.checktVersion(selHelperVersion)) {
            console.log("Invalid zparkingb/selectionhelper.js. Expecting "
                 + selHelperVersion + ".");
            invalidLibraryDialog.open();
            return;
        }

    }

    function setDuration(newDuration) {
        var chords = getSelection();

        if (!chords || (chords.length == 0))
            return;

        setElementDuration(chords[0], newDuration);

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

    function setElementDuration(element, newDuration) {

        var score = curScore;

        var cur_time = element.parent.tick;

        var cursor = score.newCursor();
        cursor.rewindToTick(cur_time);

        var current = durationTo64(element.duration); ;
        var increment = newDuration - current;
        console.log("from " + current + " to " + newDuration);

        if (increment > 0) {

            // 0) On compte ce qu'on a comme buffer en fin de mesure
            var buffer = computeRemainingRest(cursor.measure, cursor.track);
            console.log("Required increment is : " + increment + ", current buffer is : " + buffer);

            // 1) on coupe ce qu'on va déplacer
            var doCutPaste = selectRemaingInMeasure(cursor);

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
            //score.endCmd();

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
            cursorToDuration(cursor, newDuration);
            //cursor.element.duration=fraction(1, 2) // KO


            // 3) On fait le paste
            if (doCutPaste) {
                cursor.rewindToTick(cur_time);
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

            moveNext(cursor);
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
        if (Math.abs(ratio - 1.25) <= 0.01) {
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
        var sigDen = 64;
        var sigNum = sigDen * sig.numerator / sig.denominator + increment;
        console.log("Increasing from " + (sigDen * sig.numerator / sig.denominator) + " to " + sigNum);

        cursor.score.startCmd();
        console.log("CMD: Modify timesigActual");
        measure.timesigActual = fraction(sigNum, sigDen);
        debugMeasureLength(measure);
        cursor.score.endCmd();

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
        var sigN = measure.timesigNominal;
        var sigA = measure.timesigActual;
        console.log("Required decrement is : " + increment + ", current available in measure is : " + (sigA.numerator - sigA.denominator));
        increment = sigA.numerator - Math.max(sigA.numerator - increment, sigA.denominator);
        // réduction au-delà de ce qui est disponible, on ne fait rien
        if (increment <= 0)
            return;

        // 2) Computing available rest duration
        var available = computeRemainingRest(measure, cursor.track);
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
                console.log("!! Couldn't find a correct element to time-delete. Looking for " + increment + ", found " + orig);
                break;
            }

        }

        if (remaining > 0) {
            console.log("!! Couldn't time-delete all. Looking for " + increment + ", remaining is " + remaining);
        }

        // 4) Adapting the measure length
        var target = sigA.numerator - increment;
        cursor.score.startCmd();
        console.log("CMD: Modify timesigActual");
        measure.timesigActual = fraction(target, sigA.denominator);
        cursor.score.endCmd();
        debugMeasureLength(measure);

    }

    function durationTo64(duration) {
        return 64 * duration.numerator / duration.denominator;
    }

    /**
     * Computes the duration of the rests at the end of the measure.
     */
    function computeRemainingRest(measure, track) {
        var last = measure.lastSegment;
        var duration = 0;
        var element;
        //while ((last!=null) && (((element = last.elementAt(track)) == null) || (element.type == Element.REST))) {
        while ((last != null) && (((element = _d(last, track)) == null) || (element.type != Element.CHORD))) {
            if ((element != null) && (element.type == Element.REST)) {
                duration += durationTo64(element.duration);
            }
            last = last.prevInMeasure;
        }

        return duration;

    }

    function _d(last, track) {
        var el = last.elementAt(track);
        console.log(" At " + last.tick + ": " + ((el !== null) ? el.userName() : " / "));
        return el;
    }

    function selectCursor(cursor) {
        var el = cursor.element;
        //console.log(el.duration.numerator + "--"+el.duration.denominator);
        if (el.type === Element.CHORD)
            el = el.notes[0];
        else if (el.type !== Element.REST)
            return false;
        cursor.score.selection.select(el);

    }

    /**
     * Position to the next valid segment in the current measure.
     */
    function moveNext(cursor) {

        var first = cursor.segment.nextInMeasure;
        // for the first segment: we go the next *existing* element after the one at the cursor.
        while (first && first.elementAt(cursor.track) === null) {
            first = first.nextInMeasure;
        }

        if (first !== null) {
            var tick = first.tick;
            cursor.rewindToTick(tick);
        }

    }

    function selectRemaingInMeasure(cursor) {
        var measure = cursor.measure;
        var first = cursor.segment.nextInMeasure;
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
            cursor.score.startCmd();
            console.log("CMD: Selection clear");
            cursor.score.selection.clear();
            cursor.score.endCmd();
            return false;
        }

        // Select the range. !! Must be surrounded by startCmd/endCmd, otherwise a cmd(" cut ") crashes MS
        var tick = last.tick;
        if (tick == cursor.score.lastSegment.tick)
            tick++; // Bug in MS with the end of score ticks
        console.log("--> Yes. Selecting from " + first.tick + " to " + tick);
        cursor.score.startCmd();
        console.log("CMD: SelectRange");
        cursor.score.selection.selectRange(first.tick, tick, cursor.staffIdx, cursor.staffIdx);
        cursor.score.endCmd();

        return true;

    }

    function debugMeasureLength(measure) {
        console.log(measure.timesigNominal.str + " // " + measure.timesigActual.str);
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
        text: "Invalid 'zparkingb/selectionhelper.js' version.\nExpecting "
         + selHelperVersion + ".\n" + pluginName + " will stop here."
        onAccepted: {
            Qt.quit()
        }
    }
}
