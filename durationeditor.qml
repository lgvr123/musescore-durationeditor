import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import "zparkingb/selectionhelper.js" as SelHelper

MuseScore {
    menuPath: "Plugins." + pluginName
    description: "---"
    version: "1.0.0"
    readonly property var pluginName: "Duration Editor"
    readonly property var selHelperVersion: "1.2.0"

    pluginType: "dock"
    dockArea: "right"
    requiresScore: false
    width: 600
    height: 200

    Grid {
        id: layButtons

        rows: 1
        columnSpacing: 5
        rowSpacing: 0

        Button {
            text: "1/2"
            onClicked: setDuration(32)
        }
        Button {
            text: "1/4"
            onClicked: setDuration(16)
        }
        Button {
            text: "1/8"
            onClicked: setDuration(8)
        }

    }

    onRun: {

        if ((typeof(SelHelper.checktVersion) !== 'function') || !SelHelper.checktVersion(selHelperVersion)) {
            console.log("Invalid zparkingb/selectionhelper.js. Expecting "
                 + selHelperVersion + ".");
            invalidLibraryDialog.open();
            return;
        }
		
		if (Qt.fontFamilies().indexOf('Leland') < 0) {
			console.log("Leland not found");
		} 

    }

    function setDuration(newDuration) {
        var chords = getSelection();

        if (!chords || (chords.length == 0))
            return;

        setElementDuration(chords[0], newDuration);

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
            var doCutPaste = selectionRemaingInMeasure(cursor);

            if (doCutPaste)
                cmd("cut");

            // 2) on adapte la longueur de la mesure (si on n'a pas assez de buffer)
            if (buffer < increment) {
                appendRest(cursor, increment - buffer);
            }

            // 3) on adapte la durée de la note
            cursor.rewindToTick(cur_time);
            selectCursor(cursor);

            selectionToDuration(current, newDuration);

            // 3) On fait le paste
            if (doCutPaste) {
                cursor.rewindToTick(cur_time);
                cursor.next();
                selectCursor(cursor);
                cmd("paste");
            }
            //score.endCmd();

        }
        if (increment < 0) {

            // 1) on coupe ce qu'on va déplacer
            var doCutPaste = selectionRemaingInMeasure(cursor);
            if (doCutPaste)
                cmd("cut");

            // 2) on adapte la durée de la note
            cursor.rewindToTick(cur_time);
            selectCursor(cursor);
            selectionToDuration(current, newDuration);
            //cursor.element.duration=fraction(1, 2) // KO


            // 3) On fait le paste
            if (doCutPaste) {
                cursor.rewindToTick(cur_time);
                cursor.next();
                selectCursor(cursor);
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

    function selectionToDuration(orig, target) {

        //var re1=Math.log2(target);
        var re1 = Math.log(target) / Math.log(2);
        var re2 = re1 - (re1 | 0); // base - trunc(base);
        re1 = re1 | 0; // = trunc
        var ratio = ((Math.pow(2, re2) * 10000) | 0) / 10000;

        console.log(orig + " -- " + target + " : " + re1 + "/" + ratio);

        var cmdline = "pad-note-" + (64 / Math.pow(2, re1));
        console.log("-->" + cmdline);
        cmd(cmdline);

        switch (ratio) {
        case 1.25: // TO DO "pad-dot" c'est trop. Il faudrait scinder la note en 2 et faire "pad-dot" sur la moitié
        case 1.5:
            console.log("-->pad-dot");
            cmd("pad-dot")
            break;

        case 1.75:
            console.log("-->pad-dotdot");
            cmd("pad-dotdot")
            break;

        case 1.875:
            console.log("-->pad-dot3");
            cmd("pad-dot3")
            break;
        }

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
            cursor.score.selection.select(last);
            selectionToDuration(orig, target);
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
        var last = measure.lastSegment;
        var element = getPreviousRest(last, cursor.track);

        var orig = durationTo64(element.duration);
        if (orig == increment) {
            cursor.score.selection.select(element);
            cmd("time-delete");
        }

        // 4) Adapting the measure length
        var target = sigA.numerator - increment;
        cursor.score.startCmd();
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

    /*function appendRest(cursor) {
    var last = null;
    var measure = cursor.measure;
    var seg = measure.firstSegment;

    debugMeasureLength(measure);

    var i = 0;

    do {
    var element;
    element = seg.elementAt(cursor.track);

    console.log((i++) + ")" + element.userName());

    if (element && ((element.type == Element.REST) || (element.type == Element.CHORD))) {
    if (element.type === Element.CHORD)
    last = element.notes[0];
    else if (element.type === Element.REST)
    last = element;
    }

    seg = seg.nextInMeasure;

    } while (seg != null)

    if (last == null) {
    console.log(" Could not find a last note / rest in that measure ");
    return;
    }

    cursor.score.selection.select(last);
    insertRestAtSelection();

    debugMeasureLength(measure);

    }

    function insertRest(cursor) {
    cursor.setDuration(1, 2)
    selectCursor(cursor);
    insertRestAtSelection();
    }

    function insertRestAtSelection() {
    cmd(" insert - a ");
    var el = cursor.element;
    removeElement(el); // to rest
    }*/

    function selectCursor(cursor) {
        var el = cursor.element;
        //console.log(el.duration.numerator + "--"+el.duration.denominator);
        if (el.type === Element.CHORD)
            el = el.notes[0];
        else if (el.type !== Element.REST)
            return false;
        cursor.score.selection.select(el);

    }

    function selectionRemaingInMeasure(cursor) {
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
            cursor.score.selection.clear();
            cursor.score.endCmd();
            return false;
        }

        // Select the range. !! Must be surrounded by startCmd/endCmd, otherwise a cmd(" cut ") crashes MS
        console.log("-->Yes");
        cursor.score.startCmd();
        var tick=last.tick;
        if (tick==cursor.score.lastSegment.tick) tick++;  // Bug in MS with the end of score ticks
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
            if (element != null)
                the_real_last = last;
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
