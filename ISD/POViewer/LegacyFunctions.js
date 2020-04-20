
//Legacy ApplicationWebForm.js Functions

/**************************************************************************************
*  Function    : OpwnWindowCentered(URLstring)                                       *
*  Description : This function is responsible to do a window .open. Open the pop up  *
and place it in the center of the screen.                           *
*  Parameters  : URLstring. the URL for the window.open                              *
**************************************************************************************/
function OpenWindowCentered(URLstring) {
    var width = 400;
    var height = 300;
    var left = parseInt((screen.availWidth / 2) - (width / 2));
    var top = parseInt((screen.availHeight / 2) - (height / 2));
    var windowFeatures = "width=" + width + ",height=" + height + ",left=" + left + ",top=" + top + ",resizable,scrollbars=1";
    helpWindow = window.open(URLstring, "", windowFeatures);

    //return false;
}

/**************************************************************************************
*  Function    : FCKeditor_OnComplete()                                              *
*  Description : Sets focus in the textarea of the FCKEditor (if the method          *
*                Fev_FocusOnDefaultElement() determines that it appears before the   *
*                control upon which focus would otherwise normally be set).          *
*                Note that this method gets called upon loading of the FCKEditor in  *
*                the page, but only AFTER Fev_FocusOnFirstFocusableFormElement()     *
*                gets called; also, the focus needs to be set in this FCKEditor-     *
*                provided JavaScriptAPI method because the FCKEditor does not        *
*                respond to the conventional JavaScript focus() method.              *
*  Parameters  : pEditorInstance: reference to the FCKEditor                         *
**************************************************************************************/
var gSetFocusOnFCKEditor = false;
function FCKeditor_OnComplete(pEditorInstance) {
    var oEditor = pEditorInstance;
    if (gSetFocusOnFCKEditor == true) {
        oEditor.Focus();
        // disable further focus setting (in case there are more than one FCKEditor textarea on page)
        gSetFocusOnFCKEditor = false;
    }
}

function Fev_IsEnterKeyPressed(bIgnoreTextAreaEvents) {
    if (window.event) {
        var e = window.event;
        var bIsEnterKeyPress = ((e.keyCode == 13) && (e.type == 'keypress'));
        if (bIsEnterKeyPress) {
            if (bIgnoreTextAreaEvents && (bIgnoreTextAreaEvents == true)) {
                var strType = Fev_GetElementType(Fev_GetEventSourceElement(e));
                if (strType != null) strType = strType.toLowerCase();
                if (strType == "textarea") {
                    return false;
                }
            }
            return true;
        }
    }
    return false;
}

/**************************************************************************************
*  Function    : getHRefName()                                                       *
*  Description : We need to get the name of button used in the <a href tag.  For     *
*                example, if the href tag = __doPostBack('Menu1$Button') then we     *
*        need to return Menu1$Button.                        *
*  Parameters  : anElement: anElement whose HRef value is retrieved and          *
*        and parsed.                                 *
**************************************************************************************/
function getHRefName(anElement) {
    var anHRef = anElement.href;

    var startpos = anHRef.indexOf("doPostBack('");
    if (startpos >= 0) {
        startpos = startpos + "doPostBack('".length;
    } else {
        if (navigator.appName == "Netscape") {
            startpos = anHRef.indexOf('DoPostBackWithOptions(new WebForm_PostBackOptions("');
            startpos = startpos + 'DoPostBackWithOptions(new WebForm_PostBackOptions("'.length;
        }
        else { // IE
            startpos = anHRef.indexOf('DoPostBackWithOptions(new%20WebForm_PostBackOptions("');
            startpos = startpos + 'DoPostBackWithOptions(new%20WebForm_PostBackOptions("'.length;
        }
    }

    var endpos = anHRef.indexOf("',");
    if (endpos < 0) endpos = anHRef.indexOf('",');


    anHRef = anHRef.substring(startpos, endpos);

    return anHRef;
}

// returns true if the href uses PostBackWithOptions.
function DoesButtonUsePostbackWithOptions(anElement) {
    var anHRef = anElement.href;
    var startpos = anHRef.indexOf('PostBackWithOptions');
    if (startpos >= 0) {
        return true;
    }
    return false;
}



/**************************************************************************************
*  Function    : toggleExpandCollapse()                                              *
*  Description : Toggles the expanding and collapsing of the content region of       *
*                    record and table panels; also swaps the "expand/collapse" icon, *
*                    and "total records" count based upon the current                *
*                    expand/collapse state.                                          *
*  Parameters  : anchorNode, <a> tag node which is clicked upon to initiate toggling *
*                    of expand/collapse                                              *
*  Assumptions : The region which is expanded/collapsed is the table (with HTML      *
*                    id, "CollapsibleRegion") within the sibling (row) of the table  *
*                    row which contains the anchorNode.                              *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function toggleExpandCollapse(anchorNode) {
    var collapsibleNode = anchorNode;

    // traverse up node tree until the parent table which contains the "dialog_header" and the "collapsible region" is found
    while (true) {
        collapsibleNode = collapsibleNode.parentNode;
        if ((collapsibleNode != null) &&
    		 (collapsibleNode.tagName == "TABLE") &&
    		 ((collapsibleNode.className == "dialog_view") || (collapsibleNode.className == "dv"))
    	   ) {
            break;
        }
    }

    // traverse down node tree to "collapsible region"    
    var childNodesArray = collapsibleNode.getElementsByTagName("TABLE");
    for (var i = 0; i < childNodesArray.length; i++) {
        if (childNodesArray[i].id == "CollapsibleRegion") {
            collapsibleNode = childNodesArray[i];
            break;
        }
    }

    // make sure this node is a collapsible region before collapsing
    if ((collapsibleNode != null) && (collapsibleNode.id == "CollapsibleRegion") && (collapsibleNode.tagName == "TABLE")) {
        collapsibleNode.style.display = (collapsibleNode.style.display == "") ? "none" : "";

        // reposition any scrolling tables' "fixed header" row
        refreshFixedHeaderRows();
    }

    // traverse to image node (note that for both Netscape and IE, this is the first child of anchor tag)
    var imageNode = anchorNode.childNodes.item(0);

    // make sure this node contains the expand/collapse image before swapping icon
    if ((imageNode.id == "ExpandCollapseIcon") && (imageNode.tagName == "IMG")) {
        // show appropriate icon for current expand/collapse state
        imageNode.src = (collapsibleNode.style.display == "") ? "../Images/DialogHeaderIconCollapse.gif" : "../Images/DialogHeaderIconExpand.gif";

        // show appropriate tool tip for current expand/collapse state (for section 508 compliance)
        // imageNode.alt = (collapsibleNode.style.display == "") ? "Collapse panel" : "Expand panel";
        // imageNode.title = (collapsibleNode.style.display == "") ? "Collapse panel" : "Expand panel";
    }


    // traverse up node tree until the parent table which contains the "dialog_header" and the "collapsible region" is found
    var totalRecordsNode = anchorNode;

    while (true) {
        totalRecordsNode = totalRecordsNode.parentNode;
        if ((totalRecordsNode != null) &&
    		 (totalRecordsNode.tagName == "TD") &&
    		 ((totalRecordsNode.className == "dialog_header") || (totalRecordsNode.className == "dh"))
    	   ) {
            break;
        }
    }

    // traverse down node tree to "collapsible region total records"    
    var childNodesArray = totalRecordsNode.getElementsByTagName("TABLE");
    for (var i = 0; i < childNodesArray.length; i++) {
        if (childNodesArray[i].id == "CollapsibleRegionTotalRecords") {
            totalRecordsNode = childNodesArray[i];
            break;
        }
    }

    // make sure this node contains the total records count before toggling
    if ((totalRecordsNode != null) && (totalRecordsNode.id == "CollapsibleRegionTotalRecords") && (totalRecordsNode.tagName == "TABLE")) {
        // show total records count if panel in collapsed state
        totalRecordsNode.style.display = (totalRecordsNode.style.display == "") ? "none" : "";
    }

    return false;
}


/**************************************************************************************
*  Function    : refreshFixedHeaderRows()                                            *
*  Description : Upon expand/collapse of record/table panels, forces a repositioning *
*                    of any scrolling table's "fixed" header row (to it proper       *
*                    location above/relative to the rest of the shifted table rows.  *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function refreshFixedHeaderRows() {
    var lHeaderRowNodesArray = document.getElementsByTagName("thead");
    for (var i = 0; i < lHeaderRowNodesArray.length; i++) {
        var lHeaderRowNode = lHeaderRowNodesArray[i];
        if (lHeaderRowNode.className == "fixedHeader") {
            lHeaderRowNode.style.position = "absolute";
            lHeaderRowNode.style.position = "relative";
        }
    }
}

/**************************************************************************************
*  Function    : emailPage()                                                         *
*  Description : Invokes the system's default e-mail client to send an e-mail with   *
*                    the current URL in the body of the message.                     *
*  ISD Feature : "E-mail Page"                                                       *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function emailPage() {
    // if (justDoIt == true)
    // {
    var lMailStr;
    lMailStr = "mailto:?body=" + location.href;
    location.href = lMailStr;
    // }
}



/**************************************************************************************
*  Function    : captureEnterKeyInScrollingTable()                                   *
*  Description : Captures an "enter" keyboard event, and calls the respective        *
*                    function to process the event.                                  *
*  Parameters  : pTableInFocus, html table receiving the keyboard event              *
*                event, browser-generated event object                               *
*  Assumptions : Only scrolling table panels will call this function.                *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function captureEnterKeyInScrollingTable(pTableInFocus, event) {

    // capture current scroll position for "maintain position in tables" feature 
    setCurrentBrowserCoordinates();

    if (justDoIt == true) {

        // for IE...
        if (event.keyCode) {
            // if enter key...
            if (event.keyCode == 13) {
                if (clickEditButtonOfTableRowInFocus() == true) {
                    event.returnValue = false;
                    event.cancel = true;
                    event.cancelBubble = true;
                    if (event.stopPropagation) event.stopPropagation();
                }
                /* else let event bubble up to "enter key capture" code for the above column filter button */
            }
            // if key down...
            else if (event.keyCode == 40) {
                event.returnValue = false;
                event.cancel = true;
                event.cancelBubble = true;
                if (event.stopPropagation) event.stopPropagation();
                // ignore because up/down keypress functionality is not supported in scrolling tables
            }
            // if key up...
            else if (event.keyCode == 38) {
                event.returnValue = false;
                event.cancel = true;
                event.cancelBubble = true;
                if (event.stopPropagation) event.stopPropagation();
                // ignore because up/down keypress functionality is not supported in scrolling tables
            }
        }
        // if Netscape/Firefox...
        else if (event.which) {

            // if enter key...
            if (event.which == 13) {
                if (clickEditButtonOfTableRowInFocus() == true) {
                    event.returnValue = false;
                    event.cancel = true;
                    event.cancelBubble = true;
                    if (event.stopPropagation) event.stopPropagation();
                }
                /* else let event bubble up to "enter key capture" code for the above column filter button */
            }
            // if key down...
            else if (event.which == 40) {
                event.returnValue = false;
                event.cancel = true;
                event.cancelBubble = true;
                if (event.stopPropagation) event.stopPropagation();
                // ignore because up/down keypress functionality is not supported in scrolling tables
            }
            // if key up...
            else if (event.which == 38) {
                event.returnValue = false;
                event.cancel = true;
                event.cancelBubble = true;
                if (event.stopPropagation) event.stopPropagation();
                // ignore because up/down keypress functionality is not supported in scrolling tables
            }
        }
    }
}


/**************************************************************************************
*  Function    : processFirstMonthDigit()                                            *
*  Description : Parses the first month digit entered.                               *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*                gDateStringEntered, current contents (value) in the input textbox   *
*  Returns:    : None.                                                               *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function processFirstMonthDigit(aInputTextbox, gDateStringEntered) {

    // myAlert("processFirstMonthDigit(aInputTextbox.value=" + aInputTextbox.value + ",gDateStringEntered=" + gDateStringEntered + ")");

    var lLastCharEntered = (aInputTextbox.value).charAt((aInputTextbox.value).length - 1);

    var lValidDigits = "01";
    // if user entered premature date separator...
    if ((lLastCharEntered == gDateSeparator1) || (lLastCharEntered == gDateSeparator2)) {
        clearLastCharEntered(aInputTextbox);
    }
    // if "2", "3",..., or "9" entered...
    else if (lValidDigits.indexOf(lLastCharEntered) == -1) {
        // pre-pend month's leading "0" for user
        // aInputTextbox.value = aInputTextbox.value.substring(0, aInputTextbox.value.length-1) + "0" + lLastCharEntered;
        aInputTextbox.value = gDateStringEntered + "0" + lLastCharEntered;

        if (gDateMonthPosition == 1) {
            aInputTextbox.value += gDateSeparator1;
        }
        else if (gDateMonthPosition == 2) {
            aInputTextbox.value += gDateSeparator2;
        }

        // record current valid month entry
        gCurrentValidDateArray[gDateMonthPosition - 1] = "0" + lLastCharEntered;

        goToNextState("SecondMonthDigit");
    }
    // if "0" or "1" entered...
    else {
        // aInputTextbox.value = aInputTextbox.value.substring(0, aInputTextbox.value.length-1) + lLastCharEntered;
        aInputTextbox.value = gDateStringEntered + lLastCharEntered;

        // record current valid month entry
        gCurrentValidDateArray[gDateMonthPosition - 1] = lLastCharEntered + "m";

        goToNextState("FirstMonthDigit");
    }
}


/**************************************************************************************
*  Function    : processSecondMonthDigit()                                           *
*  Description : Parses the second month digit entered.                              *
*  Assumption  : First month digit entered was "0" or "1".                           *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*                gDateStringEntered, current contents (value) in the input textbox   *
*  Returns:    : None.                                                               *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function processSecondMonthDigit(aInputTextbox, gDateStringEntered) {
    var lLastCharEntered = (aInputTextbox.value).charAt((aInputTextbox.value).length - 1);
    var lFirstCharEntered = (aInputTextbox.value).charAt((aInputTextbox.value).length - 2);

    // myAlert("processSecondMonthDigit(aInputTextbox.value=" + aInputTextbox.value + ",gDateStringEntered=" + gDateStringEntered + ")");

    // if user entered premature date separator...
    if (((gDateMonthPosition == 1) && (lLastCharEntered == gDateSeparator1)) || ((gDateMonthPosition == 2) && (lLastCharEntered == gDateSeparator2))) {
        // if valid user-entered premature date separator...
        if (lFirstCharEntered != "0") {
            // pre-pend month's leading "0" for user
            // aInputTextbox.value = aInputTextbox.value.substring(0, aInputTextbox.value.length-2) + "0" + lFirstCharEntered;
            aInputTextbox.value = gDateStringEntered.substring(0, (gDateStringEntered.length) - 1) + "0" + lFirstCharEntered;

            if (gDateMonthPosition == 1) {
                aInputTextbox.value += gDateSeparator1;
            }
            else if (gDateMonthPosition == 2) {
                aInputTextbox.value += gDateSeparator2;
            }

            // record current valid month entry
            gCurrentValidDateArray[gDateMonthPosition - 1] = "0" + lFirstCharEntered;

            goToNextState("SecondMonthDigit");
        }
        else {
            clearLastCharEntered(aInputTextbox);

            // remain in current state      
        }
    }
    // if user entered incorrect premature date separator...
    else if (((gDateMonthPosition == 1) && (lLastCharEntered == gDateSeparator2)) || ((gDateMonthPosition == 2) && (lLastCharEntered == gDateSeparator1))) {
        clearLastCharEntered(aInputTextbox);

        // remain in current state
    }
    else if (lFirstCharEntered == "0") {
        // if valid month portion entered...
        if (lLastCharEntered != "0") {

            if (gDateMonthPosition == 1) {
                aInputTextbox.value += gDateSeparator1;
            }
            else if (gDateMonthPosition == 2) {
                aInputTextbox.value += gDateSeparator2;
            }

            // record current valid month entry
            gCurrentValidDateArray[gDateMonthPosition - 1] = gCurrentValidDateArray[gDateMonthPosition - 1].replace(/m/, lLastCharEntered);

            goToNextState("SecondMonthDigit");
        }
        // invalid month digit entered...
        else {
            clearLastCharEntered(aInputTextbox);

            // remain in current state
        }
    }
    else if (lFirstCharEntered == "1") {
        var lValidDigits = "012";
        // if valid month portion entered...                        
        if (lValidDigits.indexOf(lLastCharEntered) != -1) {

            if (gDateMonthPosition == 1) {
                aInputTextbox.value += gDateSeparator1;
            }
            else if (gDateMonthPosition == 2) {
                aInputTextbox.value += gDateSeparator2;
            }

            // record current valid month entry
            gCurrentValidDateArray[gDateMonthPosition - 1] = gCurrentValidDateArray[gDateMonthPosition - 1].replace(/m/, lLastCharEntered);

            goToNextState("SecondMonthDigit");
        }
        // invalid month digit entered...
        else {
            clearLastCharEntered(aInputTextbox);

            // remain in current state
        }
    }
}

/**************************************************************************************
*  Function    : processFirstDayDigit()                                              *
*  Description : Parses the first day digit entered.                                 *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*                gDateStringEntered, current contents (value) in the input textbox   *
*  Returns:    : None.                                                               *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function processFirstDayDigit(aInputTextbox, gDateStringEntered) {
    var lLastCharEntered = (aInputTextbox.value).charAt((aInputTextbox.value).length - 1);

    // myAlert("processFirstDayDigit(aInputTextbox.value=" + aInputTextbox.value + ",gDateStringEntered=" + gDateStringEntered + ")");

    var lValidDigits = "0123";
    if ((lLastCharEntered == gDateSeparator1) || (lLastCharEntered == gDateSeparator2)) {
        clearLastCharEntered(aInputTextbox);
    }
    // if "4", "5",..., or "9" entered...
    else if (lValidDigits.indexOf(lLastCharEntered) == -1) {
        // pre-pend month's leading "0" for user
        // aInputTextbox.value = aInputTextbox.value.substring(0, aInputTextbox.value.length-1) + "0" + lLastCharEntered;
        aInputTextbox.value = gDateStringEntered + "0" + lLastCharEntered;

        if (gDateDayPosition == 1) {
            aInputTextbox.value += gDateSeparator1;
        }
        else if (gDateDayPosition == 2) {
            aInputTextbox.value += gDateSeparator2;
        }

        // record current valid day entry
        gCurrentValidDateArray[gDateDayPosition - 1] = "0" + lLastCharEntered;

        goToNextState("SecondDayDigit");
    }
    // if "0", "1", "2", or "3" entered...
    else {
        // record current valid day entry
        gCurrentValidDateArray[gDateDayPosition - 1] = lLastCharEntered + "d";

        goToNextState("FirstDayDigit");
    }
}


/**************************************************************************************
*  Function    : processSecondDayDigit()                                             *
*  Description : Parses the second day digit entered.                                *
*  Assumption  : First month digit entered was "0",..., or "3.                       *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*                gDateStringEntered, current contents (value) in the input textbox   *
*  Returns:    : None.                                                               *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function processSecondDayDigit(aInputTextbox, gDateStringEntered) {
    var lLastCharEntered = (aInputTextbox.value).charAt((aInputTextbox.value).length - 1);
    var lFirstCharEntered = (aInputTextbox.value).charAt((aInputTextbox.value).length - 2);

    // myAlert("processSecondDayDigit(aInputTextbox.value=" + aInputTextbox.value + ",gDateStringEntered=" + gDateStringEntered + ")");

    // if user entered premature date separator...
    if (((gDateDayPosition == 1) && (lLastCharEntered == gDateSeparator1)) || ((gDateDayPosition == 2) && (lLastCharEntered == gDateSeparator2))) {
        // if valid user-entered premature date separator...
        if (lFirstCharEntered != "0") {
            // pre-pend day's leading "0" for user
            // aInputTextbox.value = aInputTextbox.value.substring(0, aInputTextbox.value.length-2) + "0" + lFirstCharEntered;
            aInputTextbox.value = gDateStringEntered.substring(0, (gDateStringEntered.length) - 1) + "0" + lFirstCharEntered;

            if (gDateDayPosition == 1) {
                aInputTextbox.value += gDateSeparator1;
            }
            else if (gDateDayPosition == 2) {
                aInputTextbox.value += gDateSeparator2;
            }

            // record current valid day entry
            gCurrentValidDateArray[gDateDayPosition - 1] = "0" + lFirstCharEntered;

            goToNextState("SecondDayDigit");
        }
        else {
            clearLastCharEntered(aInputTextbox);

            // remain in current state      
        }
    }
    // if user entered incorrect premature date separator...
    else if (((gDateDayPosition == 1) && (lLastCharEntered == gDateSeparator2)) || ((gDateDayPosition == 2) && (lLastCharEntered == gDateSeparator1))) {
        clearLastCharEntered(aInputTextbox);

        // remain in current state
    }
    else if (lFirstCharEntered == "0") {
        // if valid day portion entered...
        if (lLastCharEntered != "0") {
            if (gDateDayPosition == 1) {
                aInputTextbox.value += gDateSeparator1;
            }
            else if (gDateDayPosition == 2) {
                aInputTextbox.value += gDateSeparator2;
            }

            // record current valid day entry
            gCurrentValidDateArray[gDateDayPosition - 1] = gCurrentValidDateArray[gDateDayPosition - 1].replace(/d/, lLastCharEntered);

            goToNextState("SecondDayDigit");
        }
        // invalid day digit entered...
        else {
            clearLastCharEntered(aInputTextbox);

            // remain in current state
        }
    }
    else if ((lFirstCharEntered == "1") ||
              (lFirstCharEntered == "2")) {
        // all second day digits are valid

        if (gDateDayPosition == 1) {
            aInputTextbox.value += gDateSeparator1;
        }
        else if (gDateDayPosition == 2) {
            aInputTextbox.value += gDateSeparator2;
        }

        // record current valid day entry
        gCurrentValidDateArray[gDateDayPosition - 1] = gCurrentValidDateArray[gDateDayPosition - 1].replace(/d/, lLastCharEntered);

        goToNextState("SecondDayDigit");
    }
    // first day digit is "3"...
    else {
        var lValidDigits = "01";
        // if valid second day portion entered...                       
        if (lValidDigits.indexOf(lLastCharEntered) != -1) {

            if (gDateDayPosition == 1) {
                aInputTextbox.value += gDateSeparator1;
            }
            else if (gDateDayPosition == 2) {
                aInputTextbox.value += gDateSeparator2;
            }

            // record current valid day entry
            gCurrentValidDateArray[gDateDayPosition - 1] = gCurrentValidDateArray[gDateDayPosition - 1].replace(/d/, lLastCharEntered);

            goToNextState("SecondDayDigit");
        }
        // invalid second day digit entered...
        else {
            clearLastCharEntered(aInputTextbox);

            // remain in current state
        }
    }
}


/**************************************************************************************
*  Function    : processFirstYearDigit()                                             *
*  Description : Parses the first year digit entered.                                *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*                gDateStringEntered, current contents (value) in the input textbox   *
*  Returns:    : None.                                                               *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function processFirstYearDigit(aInputTextbox, gDateStringEntered) {
    var lLastCharEntered = (aInputTextbox.value).charAt((aInputTextbox.value).length - 1);

    // if four-digit year...
    if (gDatePatternArray[gDateYearPosition - 1].length == 4) {
        if ((lLastCharEntered == gDateSeparator1) || (lLastCharEntered == gDateSeparator2)) {
            clearLastCharEntered(aInputTextbox);
        }
        // if invalid year digit entered...
        else if ((lLastCharEntered != "1") &&
             (lLastCharEntered != "2")) {

            // pre-pend year's leading "20" for user (assume 21st century)
            // aInputTextbox.value = aInputTextbox.value.substring(0, aInputTextbox.value.length-1) + "20" + lLastCharEntered;
            aInputTextbox.value = gDateStringEntered + "20" + lLastCharEntered;

            // record current valid year entry
            gCurrentValidDateArray[gDateYearPosition - 1] = "20" + lLastCharEntered + "y";
        }
        else {
            // aInputTextbox.value = aInputTextbox.value.substring(0, aInputTextbox.value.length-1) + lLastCharEntered;
            aInputTextbox.value = gDateStringEntered + lLastCharEntered;

            // record current valid year entry
            gCurrentValidDateArray[gDateYearPosition - 1] = lLastCharEntered + "yyy";
        }
    }
    // if two-digit year...
    else {
        if ((lLastCharEntered == gDateSeparator1) || (lLastCharEntered == gDateSeparator2)) {
            clearLastCharEntered(aInputTextbox);
        }
        else {
            // any initial year digit is valid

            // record current valid year entry
            gCurrentValidDateArray[gDateYearPosition - 1] = lLastCharEntered + "y";
        }
    }

    goToNextState("FirstYearDigit");
}

/**************************************************************************************
*  Function    : processSucceedingYearDigit()                                        *
*  Description : Parses subsequent year digits entered.                              *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*                gDateStringEntered, current contents (value) in the input textbox   *
*  Returns:    : None.                                                               *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function processSucceedingYearDigit(aInputTextbox, gDateStringEntered) {
    var lLastCharEntered = (aInputTextbox.value).charAt((aInputTextbox.value).length - 1);

    var lDateStringArray;
    var lYearStringEnteredSoFar;

    if (gDateSeparator1 == gDateSeparator2) {
        lDateStringArray = (aInputTextbox.value).split(gDateSeparator1);
        lYearStringEnteredSoFar = lDateStringArray[gDateYearPosition - 1];
    }
    else {
        if (gDateYearPosition == 3) {
            lDateStringArray = (aInputTextbox.value).split(gDateSeparator2);
            lYearStringEnteredSoFar = lDateStringArray[1];
        }
        else if (gDateYearPosition == 2) {
            lDateStringArray = (aInputTextbox.value).split(gDateSeparator2);
            lDateStringArray = lDateStringArray[0].split(gDateSeparator1);
            lYearStringEnteredSoFar = lDateStringArray[1];
        }
        else // (gDateYearPosition == 1)
        {
            lDateStringArray = (aInputTextbox.value).split(gDateSeparator1);
            lYearStringEnteredSoFar = lDateStringArray[0];
        }
    }

    if ((lLastCharEntered == gDateSeparator1) || (lLastCharEntered == gDateSeparator2)) {
        clearLastCharEntered(aInputTextbox);
    }
    else {
        // any subsequent year digit is valid

        // record current valid year entry
        gCurrentValidDateArray[gDateYearPosition - 1] = gCurrentValidDateArray[gDateYearPosition - 1].replace(/y/, lLastCharEntered);
    }

    if (gCurrentValidDateArray[gDateYearPosition - 1].indexOf("y") == -1) {

        if ((gDateYearPosition == 1) && (gDateDayPosition != 0)) {
            aInputTextbox.value += gDateSeparator1;
        }
        else if ((gDateYearPosition == 2) && (gDateDayPosition != 0)) {
            aInputTextbox.value += gDateSeparator2;
        }

        goToNextState("SucceedingYearDigit");
    }
    // else, remain in current state
}


/**************************************************************************************
*  Function    : displayDateSelector()                                               *
*  Description : Displays the date selector beneath the "date input field" when the  *
*                     "date selector icon" is clicked.                               *
*  Parameters  : dateFieldName, html element name of the "date input field" that     *
*                     will be filled in if the user picks a date                     *
*                displayBelowThisObject, html element name of the object below which *
*                     the date selector is displayed (optional)                      *
*  Returns:    : None.                                                               *
*  ISD Feature : "JavaScript Date Selector"                                          *
*  Authors     : Julian Robichaux, http://www.nsftools.com, and Samson Wong          *
**************************************************************************************/
function displayDateSelector(dateFieldName, displayBelowThisObject, dtFormat, dtSep) {
    var targetDateField = document.getElementsByName(dateFieldName).item(0);

    // if we weren't told what node to display the dateSelector beneath, just display it
    // beneath the date field we're updating
    if (!displayBelowThisObject)
        displayBelowThisObject = targetDateField;

    // if a date separator character was given, update the dateSeparator variable
    if (dtSep)
        dateSeparator = dtSep;
    else
        dateSeparator = defaultDateSeparator;

    // if a date format was given, update the dateFormat variable
    if (dtFormat)
        dateFormat = dtFormat;
    else
        dateFormat = defaultDateFormat;

    var x = displayBelowThisObject.offsetLeft;
    var y = displayBelowThisObject.offsetTop + displayBelowThisObject.offsetHeight;

    // deal with elements inside tables and such
    var parent = displayBelowThisObject;
    while (parent.offsetParent) {
        parent = parent.offsetParent;
        x += parent.offsetLeft;
        y += parent.offsetTop;
    }

    drawDateSelector(targetDateField, x, y);
}


/**************************************************************************************
*  Function    : drawDateSelector()                                                  *
*  Description : Called by displayDateSelector() to draw the dateSelector object     *
*                (which is just a table with calendar elements) at the specified x   *
*                and y coordinates.                                                  *
*  Parameters  : targetDateField, html element name of the "date input field" that   *
*                     will be filled in if the user picks a date                     *
*                x, x-coordinate of the displayed date selector                      *
*                y, y-coordinate of the displayed date selector                      *
*  Returns:    : None.                                                               *
*  ISD Feature : "JavaScript Date Selector"                                          *
*  Authors     : Julian Robichaux, http://www.nsftools.com, and Samson Wong          *
**************************************************************************************/
function drawDateSelector(targetDateField, x, y) {
    var dt = getFieldDate(targetDateField.value);

    // the dateSelector table will be drawn inside of a <div> with an ID defined by the
    // global dateSelectorDivID variable. If such a div doesn't yet exist on the HTML
    // document we're working with, add one.
    if (!document.getElementById(dateSelectorDivID)) {
        // don't use innerHTML to update the body, because it can cause global variables
        // that are currently pointing to objects on the page to have bad references
        //document.body.innerHTML += "<div id='" + dateSelectorDivID + "' class='dpDiv'></div>";
        var newNode = document.createElement("div");
        newNode.setAttribute("id", dateSelectorDivID);
        newNode.setAttribute("class", "dpDiv");
        newNode.setAttribute("style", "visibility: hidden;");
        document.body.appendChild(newNode);
    }

    // move the dateSelector div to the proper x,y coordinate and toggle the visiblity
    var selectorDiv = document.getElementById(dateSelectorDivID);
    selectorDiv.style.position = "absolute";
    selectorDiv.style.left = x + "px";
    selectorDiv.style.top = y + "px";
    selectorDiv.style.visibility = (selectorDiv.style.visibility == "visible" ? "hidden" : "visible");
    selectorDiv.style.display = (selectorDiv.style.display == "" ? "none" : "");
    selectorDiv.style.zIndex = 10000;

    // draw the dateSelector table
    refreshDateSelector(targetDateField.name, dt.getFullYear(), dt.getMonth(), dt.getDate());
}


/**************************************************************************************
*  Function    : refreshDateSelector()                                               *
*  Description : Function which actually does the drawing of the date selector       *
*                    html table.                                                     *
*  Parameters  : dateFieldName, html element name of the "date input field" that     *
*                     will be filled in if the user picks a date                     *
*                year, year to highlight (optional) (default is today's year)        *
*                month, month to highlight (optional) (default is today's month)     *
*                day, day to highlight (optional) (default is today's day)           *
*  Returns:    : None.                                                               *
*  ISD Feature : "JavaScript Date Selector"                                          *
*  Authors     : Julian Robichaux, http://www.nsftools.com, and Samson Wong          *
**************************************************************************************/
function refreshDateSelector(dateFieldName, year, month, day) {
    // if no arguments are passed, use today's date; otherwise, month and year
    // are required (if a day is passed, it will be highlighted later)
    var thisDay = new Date();

    if ((month >= 0) && (year > 0)) {
        thisDay = new Date(year, month, 1);
    } else {
        day = thisDay.getDate();
        thisDay.setDate(1);
    }

    // the calendar will be drawn as a table
    // you can customize the table elements with a global CSS style sheet,
    // or by hardcoding style and formatting elements below
    var crlf = "\r\n";
    var TABLE = "<table cols=7 class='dpTable'>" + crlf;
    var xTABLE = "</table>" + crlf;
    var TR = "<tr class='dpTR'>";
    var TR_title = "<tr class='dpTitleTR'>";
    var TR_days = "<tr class='dpDayTR'>";
    var TR_todaybutton = "<tr class='dpTodayButtonTR'>";
    var xTR = "</tr>" + crlf;
    var TD = "<td class='dpTD' onMouseOut='this.className=\"dpTD\";' onMouseOver=' this.className=\"dpTDHover\";' ";    // leave this tag open, because we'll be adding an onClick event
    // sam
    var TD_noDay = "<td>";
    // sam
    // var TD_title = "<td colspan=5 class='dpTitleTD'>";
    var TD_title = "<td colspan=3 class='dpTitleTD'>";
    // var TD_buttons = "<td class='dpButtonTD'>";
    var TD_buttons = "<td class='dpButtonTD' colspan='2' style='text-align:center;'>";
    var TD_todaybutton = "<td colspan=7 class='dpTodayButtonTD'>";
    var TD_days = "<td class='dpDayTD'>";
    var TD_selected = "<td class='dpDayHighlightTD' onMouseOut='this.className=\"dpDayHighlightTD\";' onMouseOver='this.className=\"dpTDHover\";' ";    // leave this tag open, because we'll be adding an onClick event
    var xTD = "</td>" + crlf;
    var DIV_title = "<div class='dpTitleText'>";
    var DIV_selected = "<div class='dpDayHighlight'>";
    var xDIV = "</div>";

    // start generating the code for the calendar table
    var html = TABLE;

    // this is the title bar, which displays the month and the buttons to
    // go back to a previous month or forward to the next month
    html += TR_title;

    // sam
    html += TD_buttons + getButtonCode(dateFieldName, thisDay, -12, "arrow_beg.gif") + "&nbsp;" + getButtonCode(dateFieldName, thisDay, -1, "arrow_left.gif") + xTD;
    html += TD_title + DIV_title + monthArrayLong[thisDay.getMonth()] + " " + thisDay.getFullYear() + xDIV + xTD;
    html += TD_buttons + getButtonCode(dateFieldName, thisDay, 1, "arrow_right.gif") + "&nbsp;" + getButtonCode(dateFieldName, thisDay, 12, "arrow_end.gif") + xTD;
    html += xTR;

    // this is the row that indicates which day of the week we're on
    html += TR_days;
    for (i = 0; i < dayArrayShort.length; i++)
        html += TD_days + dayArrayShort[i] + xTD;
    html += xTR;

    // now we'll start populating the table with days of the month
    html += TR;

    // first, the leading blanks
    for (i = 0; i < thisDay.getDay(); i++)
        html += TD_noDay + "&nbsp;" + xTD;

    // now, the days of the month
    do {
        dayNum = thisDay.getDate();
        TD_onclick = " onclick=\"updateDateField('" + dateFieldName + "', '" + getDateString(thisDay) + "');\">";

        if (dayNum == day)
            html += TD_selected + TD_onclick + DIV_selected + dayNum + xDIV + xTD;
        else
            html += TD + TD_onclick + dayNum + xTD;

        // if this is a Saturday, start a new row
        if (thisDay.getDay() == 6)
            html += xTR + TR;

        // increment the day
        thisDay.setDate(thisDay.getDate() + 1);
    } while (thisDay.getDate() > 1)

    // fill in any trailing blanks
    if (thisDay.getDay() > 0) {
        for (i = 6; i > thisDay.getDay(); i--)
            html += TD_noDay + "&nbsp;" + xTD;
    }
    html += xTR;

    // add a button to allow the user to easily return to today, or close the calendar
    var today = new Date();
    var todayString = "Today is " + dayArrayMed[today.getDay()] + ", " + monthArrayMed[today.getMonth()] + " " + today.getDate();
    html += TR_todaybutton + TD_todaybutton;

    // sam
    // html += "<button class='dpTodayButton' onClick='refreshDateSelector(\"" + dateFieldName + "\");'>this month</button> ";
    html += "<table cellpadding='0' cellspacing='0' border='0' style='padding-top:10px;' width='100%'>"
    html += "        <tr><td style='text-align:right;'>";

    html += "<table cellpadding='0' cellspacing='0' border='0'>"
    html += "        <tr>";
    html += "           <td class='button-TL-white'><img src='../Images/space.gif' height='5' width='17' alt=''/></td>";
    html += "           <td class='button-T-white'><img src='../Images/space.gif' height='5' width='4' alt=''/></td>";
    html += "           <td class='button-TR-white'><img src='../Images/space.gif' height='5' width='16' alt=''/></td>";
    html += "        </tr>";
    html += "        <tr>";
    html += "           <td class='button-L-white'><img src='../Images/space.gif' height='12' width='17' alt=''/></td>";
    html += "           <td class='button-white'><a id='OkButton__Button' class='button_link' href='#' onClick='refreshDateSelector(\"" + dateFieldName + "\");'>Today</a></td>";
    html += "           <td class='button-R-white'><img src='../Images/space.gif' height='12' width='16' alt=''/></td>";
    html += "        </tr>";
    html += "        <tr>";
    html += "           <td class='button-BL-white'><img src='../Images/space.gif' height='8' width='17' alt=''/></td>";
    html += "           <td class='button-B-white'><img src='../Images/space.gif' height='8' width='4' alt=''/></td>";
    html += "           <td class='button-BR-white'><img src='../Images/space.gif' height='8' width='16' alt=''/></td>";
    html += "        </tr>";
    html += "       </table>";

    html += "        </td>";
    html += "       <td width='10'>";
    html += "        </td>";
    html += "       <td>";

    html += "<table cellpadding='0' cellspacing='0' border='0'>"
    html += "        <tr>";
    html += "           <td class='button-TL-white'><img src='../Images/space.gif' height='5' width='17' alt=''/></td>";
    html += "           <td class='button-T-white'><img src='../Images/space.gif' height='5' width='4' alt=''/></td>";
    html += "           <td class='button-TR-white'><img src='../Images/space.gif' height='5' width='16' alt=''/></td>";
    html += "        </tr>";
    html += "        <tr>";
    html += "           <td class='button-L-white'><img src='../Images/space.gif' height='12' width='17' alt=''/></td>";
    html += "           <td class='button-white'><a id='CancelButton__Button' class='button_link' href='#' onClick='updateDateField(\"" + dateFieldName + "\");'>Cancel</a></td>";
    html += "           <td class='button-R-white'><img src='../Images/space.gif' height='12' width='16' alt=''/></td>";
    html += "        </tr>";
    html += "        <tr>";
    html += "           <td class='button-BL-white'><img src='../Images/space.gif' height='8' width='17' alt=''/></td>";
    html += "           <td class='button-B-white'><img src='../Images/space.gif' height='8' width='4' alt=''/></td>";
    html += "           <td class='button-BR-white'><img src='../Images/space.gif' height='8' width='16' alt=''/></td>";
    html += "        </tr>";
    html += "       </table>";

    html += "        </td></tr>";
    html += "       </table>";

    // html += "<button class='dpTodayButton' onClick='updateDateField(\"" + dateFieldName + "\");'>close</button>";
    html += xTD + xTR;

    // and finally, close the table
    html += xTABLE;

    document.getElementById(dateSelectorDivID).innerHTML = html;
    // add an "iFrame shim" to allow the dateSelector to display above selection lists
    adjustiFrame();
}

/**************************************************************************************
*  Function    : getButtonCode()                                                     *
*  Description : Helper function to construct the html for the previous/next         *
*                    month/year buttons.                                             *
*  Parameters  : dateFieldName, html element name of the "date input field" that     *
*                     will be filled in if the user picks a date                     *
*                dateVal, current date highlighted                                   *
*                adjust, number of months to move back/forward                       *
*                label, previous/next month/year button image to use for this button *
*  Returns:    : The html for previous/next month/year button.                       *
*  ISD Feature : "JavaScript Date Selector"                                          *
*  Authors     : Julian Robichaux, http://www.nsftools.com, and Samson Wong          *
**************************************************************************************/
function getButtonCode(dateFieldName, dateVal, adjust, label) {
    var newMonth = (dateVal.getMonth() + adjust) % 12;
    var newYear = dateVal.getFullYear() + parseInt((dateVal.getMonth() + adjust) / 12);
    if (newMonth < 0) {
        newMonth += 12;
        newYear += -1;
    }

    // sam
    // return "<button class='dpButton' onClick='refreshDateSelector(\"" + dateFieldName + "\", " + newYear + ", " + newMonth + ");'>" + label + "</button>";
    return "<a href='#' onClick='refreshDateSelector(\"" + dateFieldName + "\", " + newYear + ", " + newMonth + ");'><img src='../Images/" + label + "' border='0'></a>"
}

function updateDateField(dateFieldName, dateString) {
    var targetDateField = document.getElementsByName(dateFieldName).item(0);
    if (dateString)
        targetDateField.value = dateString;

    var selectorDiv = document.getElementById(dateSelectorDivID);
    selectorDiv.style.visibility = "hidden";
    selectorDiv.style.display = "none";

    adjustiFrame();
    targetDateField.focus();

    // after the dateSelector has closed, optionally run a user-defined function called
    // dateSelectorClosed, passing the field that was just updated as a parameter
    // (note that this will only run if the user actually selected a date from the dateSelector)
    if ((dateString) && (typeof (dateSelectorClosed) == "function"))
        dateSelectorClosed(targetDateField);
}


/**************************************************************************************
*  Function    : adjustiFrame()                                                      *
*  Description : Uses an "iFrame shim" to deal with problems where the dateSelector  *
*                    shows up behind selection list elements, if they're below the   *
*                    date selector.                                                  *
*                The problem and solution are described at:                          *
*                 http://dotnetjunkies.com/WebLog/jking/archive/2003/07/21/488.aspx  *
*                 http://dotnetjunkies.com/WebLog/jking/archive/2003/10/30/2975.aspx *
*  Parameters  : selectorDiv, html div containing date selector                      *
*                iFrameDiv, html div containing iframe shim.                         *
*  Returns:    : None.                                                               *
*  ISD Feature : "JavaScript Date Selector"                                          *
*  Authors     : Julian Robichaux, http://www.nsftools.com, and Samson Wong          *
**************************************************************************************/
function adjustiFrame(selectorDiv, iFrameDiv) {
    // we know that Opera doesn't like something about this, so if we
    // think we're using Opera, don't even try
    var is_opera = (navigator.userAgent.toLowerCase().indexOf("opera") != -1);
    if (is_opera)
        return;

    // put a try/catch block around the whole thing, just in case
    try {
        if (!document.getElementById(iFrameDivID)) {
            // don't use innerHTML to update the body, because it can cause global variables
            // that are currently pointing to objects on the page to have bad references
            //document.body.innerHTML += "<iframe id='" + iFrameDivID + "' src='javascript:false;' scrolling='no' frameborder='0'>";
            var newNode = document.createElement("iFrame");
            newNode.setAttribute("id", iFrameDivID);
            newNode.setAttribute("src", "javascript:false;");
            newNode.setAttribute("scrolling", "no");
            newNode.setAttribute("frameborder", "0");
            document.body.appendChild(newNode);
        }

        if (!selectorDiv)
            selectorDiv = document.getElementById(dateSelectorDivID);
        if (!iFrameDiv)
            iFrameDiv = document.getElementById(iFrameDivID);

        try {
            iFrameDiv.style.position = "absolute";
            iFrameDiv.style.width = selectorDiv.offsetWidth;
            iFrameDiv.style.height = selectorDiv.offsetHeight;
            iFrameDiv.style.top = selectorDiv.style.top;
            iFrameDiv.style.left = selectorDiv.style.left;
            iFrameDiv.style.zIndex = selectorDiv.style.zIndex - 1;
            iFrameDiv.style.visibility = selectorDiv.style.visibility;
            iFrameDiv.style.display = selectorDiv.style.display;
        } catch (e) {
        }

    } catch (ee) {
    }
}

/**************************************************************************************
*  Function    : getDateString()                                                     *
*  Description : Convert a JavaScript Date object to a string, based on the          *
*                dateFormat and dateSeparator variables at the beginning of this     *
*                script library.                                                     *
*  Parameters  : dateVal, current date highlighted                                   *
*  Returns:    : The highlighted date as a string.                                   *
*  ISD Feature : "JavaScript Date Selector"                                          *
*  Authors     : Julian Robichaux, http://www.nsftools.com, and Samson Wong          *
**************************************************************************************/
function getDateString(dateVal) {
    var dayString = "00" + dateVal.getDate();
    var monthString = "00" + (dateVal.getMonth() + 1);
    dayString = dayString.substring(dayString.length - 2);
    monthString = monthString.substring(monthString.length - 2);

    switch (dateFormat) {
        case "dmy":
            return dayString + dateSeparator + monthString + dateSeparator + dateVal.getFullYear();
        case "ymd":
            return dateVal.getFullYear() + dateSeparator + monthString + dateSeparator + dayString;
        case "mdy":
        default:
            return monthString + dateSeparator + dayString + dateSeparator + dateVal.getFullYear();
    }
}

function enableParent() {
    var lModalDiv = document.getElementById("modalDivID");
    document.body.removeChild(lModalDiv);
}

//Legacy ApplicationWebUIValidation Functions
//Same as the Microsoft version, except with 1 line added to the end
function ValidatorOnLoad() {
    if (typeof (Page_Validators) == "undefined")
        return;

    var i, val;
    for (i = 0; i < Page_Validators.length; i++) {
        val = Page_Validators[i];
        if (typeof (val.evaluationfunction) == "string") {
            eval("val.evaluationfunction = " + val.evaluationfunction + ";");
        }
        if (typeof (val.isvalid) == "string") {
            if (val.isvalid == "False") {
                val.isvalid = false;
                Page_IsValid = false;
            }
            else {
                val.isvalid = true;
            }
        } else {
            val.isvalid = true;
        }
        if (typeof (val.enabled) == "string") {
            val.enabled = (val.enabled != "False");
        }
        ValidatorHookupControlID(val.controltovalidate, val);
        ValidatorHookupControlID(val.controlhookup, val);
    }
    Page_ValidationActive = true;

    if (!Page_IsValid) { ValidationSummaryOnSubmit(); }
}

//Same as the Microsoft version, except:
//A) This function will not display duplicate validator error messages
//   in either the summary or the message box.
function ValidationSummaryOnSubmit() {
    if (typeof (Page_ValidationSummaries) == "undefined")
        return;
    var summary, sums, s;
    for (sums = 0; sums < Page_ValidationSummaries.length; sums++) {
        summary = Page_ValidationSummaries[sums];
        summary.style.display = "none";
        if (!Page_IsValid) {
            if (summary.showsummary != "False") {
                summary.style.display = "";
                if (typeof (summary.displaymode) != "string") {
                    summary.displaymode = "BulletList";
                }
                switch (summary.displaymode) {
                    case "List":
                        headerSep = "<br>";
                        first = "";
                        pre = "";
                        post = "<br>";
                        endString = "";
                        break;

                    case "BulletList":
                    default:
                        headerSep = "";
                        first = "<ul>";
                        pre = "<li>";
                        post = "</li>";
                        endString = "</ul>";
                        break;

                    case "SingleParagraph":
                        headerSep = " ";
                        first = "";
                        pre = "";
                        post = " ";
                        endString = "<br>";
                        break;
                }
                s = "";
                if (typeof (summary.headertext) == "string") {
                    s += summary.headertext + headerSep;
                }
                s += first;

                //start changed code
                var errorMessages = Fev_GetInvalidValidatorErrorMessages();
                for (i = 0; i < errorMessages.length; i++) {
                    s += pre + errorMessages[i] + post;
                }
                //end changed code

                s += endString;
                summary.innerHTML = s;
                window.scrollTo(0, 0);
            }
            if (summary.showmessagebox == "True") {
                s = "";
                if (typeof (summary.headertext) == "string") {
                    s += summary.headertext + "<BR>";
                }

                //start changed code
                var errorMessages = Fev_GetInvalidValidatorErrorMessages();
                var pre, post;
                switch (summary.displaymode) {
                    case "List":
                        pre = '';
                        post = '<BR>';
                        break;
                    case "BulletList":
                    default:
                        pre = '  - ';
                        post = '<BR>';
                        break;
                    case "SingleParagraph":
                        pre = '';
                        post = ' ';
                        break;
                }
                for (i = 0; i < errorMessages.length; i++) {
                    s += pre + errorMessages[i] + post;
                }
                //end changed code

                span = document.createElement("SPAN");
                span.innerHTML = s;
                s = span.innerText;
                alert(s);
            }
        }
    }
}


//
// Validation constants
//
var FEV_CREDIT_CARD_TYPE_VISA = 'Visa';
var FEV_CREDIT_CARD_TYPE_DISCOVER = 'Discover';
var FEV_CREDIT_CARD_TYPE_MASTER_CARD = 'Master Card';
var FEV_CREDIT_CARD_TYPE_AMERICAN_EXPRESS = 'American Express';
var FEV_CREDIT_CARD_TYPE_ENROUTE = 'EnRoute';
var FEV_CREDIT_CARD_TYPE_CARTE_BLANCHE = 'Carte Blanche';
var FEV_CREDIT_CARD_TYPE_DINERS_CLUB = 'Diners Club';
var FEV_CREDIT_CARD_TYPE_JCB = 'JCB';
var FEV_CREDIT_CARD_TYPE_UNKNOWN = 'Unknown';
var FEV_CREDIT_CARD_TYPE_INVALID = 'Invalid';

//
// .NET Validator Control functions
//

function Fev_ValidatorEvaluateIsValid(val) {
    var control;
    if (document && val && val.controltovalidate) {
        control = document.getElementById(val.controltovalidate);
        if (control) {
            return CustomValidatorEvaluateIsValid(val);
        }
    }
    return (true);
}

function Fev_FieldValueValidatorEvaluateIsValid(objSource, objArguments) {
    var innerValidatorId = objSource.id + '_InnerValidator';
    var innerValidator = document.all[innerValidatorId];
    if (innerValidator) {
        ValidatorValidate(innerValidator);
        objArguments.IsValid = innerValidator.isvalid;
    }
    else {
        objArguments.IsValid = true;
    }
}

function Fev_BooleanValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidBoolean(value);
}

function Fev_PasswordValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidPassword(value, objSource.MinLength, objSource.MaxLength);
}

function Fev_UsaPhoneNumberValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidUsaPhoneNumber(value);
}

function Fev_CreditCardNumberValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidCreditCardNumber(value, true);
}

function Fev_CreditCardDateValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidCreditCardDate(value);
}

function Fev_NumberValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidFloatUpToNDecimals(value, objSource.MaxDecimalPlaces, objSource.MinValue, objSource.MaxValue);
}

function Fev_CountryValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidCountry(value);
}

function Fev_UsaStateValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidUsaState(value);
}

function Fev_UsaZipCodeValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidUsaZipCode(value);
}

function Fev_EmailValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidEmailAddress(value);
}

function Fev_UrlValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidUrl(value);
}

function Fev_PercentageValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidPercentage(value, objSource.MaxDecimalPlaces, objSource.MinValue, objSource.MaxValue);
}

function Fev_CurrencyValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidCurrency(value, objSource.MaxDecimalPlaces, objSource.MinValue, objSource.MaxValue);
}

function Fev_ImageValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidImagePath(value);
}

function Fev_FileValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidWindowsFileName(value);
}

function Fev_DateTimeValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidUsaDate_digits(value, objSource.AllowTime);
}

function Fev_ShortDateValidatorEvaluateIsValid(objSource, objArguments) {
    var value = objArguments.Value;
    if (value == '') objArguments.IsValid = true;
    else objArguments.IsValid = Fev_isValidUsaDate_digits(value, false);
}

//function removes non-digit characters, and returns the string
function Fev_RemoveNonDigits(str) {
    if (str == null || str.length < 1)
        return '';

    var i;
    var currentChar;
    for (i = 0; i < str.length; i++) {
        currentChar = str.charAt(i);

        currentChar = parseInt(currentChar, 10);
        if (isNaN(currentChar)) {
            if (i == 0) {					//1st char
                if (str.length > 1) {
                    str = str.substring(1);
                } else {
                    str = '';
                }
            } else if (i == str.length - 1) {	//last char
                str = str.substring(0, str.length - 1);
            } else {						//somewhere in the middle
                str = str.substring(0, i) + str.substring(i + 1, str.length);
            }
            i--;
        }
    }
    return str;
}


//==================================================================
//Fev_StrReplace(original string, find string to replace, string that replaces, isCaseSensitive, numTimes) : Returns a copy of a string after replacement.
//	loops (replaces) numTimes times, or as long as the string is found (when numTimes = -1)
//  isCaseSensitive: true (case matters), false (case doesn't matter)
//==================================================================
function Fev_StrReplace(originalStr, findStr, replaceWith, isCaseSensitive, numTimes) {
    if (originalStr == null || originalStr == "" || findStr == null || findStr == "")
        return originalStr;
    if (findStr == replaceWith)
        return originalStr;

    numTimes = parseInt(numTimes, 10);
    if (isNaN(numTimes) || numTimes == 0)
        return originalStr;
    var isInfinite = (numTimes < 0);

    var findStrLen = findStr.length;
    var tempStr = originalStr;
    var myCounter = 0;

    var TEMP_PLACEHOLDER = ' ';

    if (findStr.indexOf(TEMP_PLACEHOLDER) >= 0)
        return originalStr;

    var index;
    if (isCaseSensitive) {
        index = tempStr.indexOf(findStr);
    } else {
        index = tempStr.toUpperCase().indexOf(findStr.toUpperCase());
    }

    while (index >= 0 && (isInfinite || myCounter < numTimes)) {
        if (index == tempStr.length - findStrLen) {
            tempStr = tempStr.substring(0, tempStr.length - findStrLen) + TEMP_PLACEHOLDER;
        } else if (index == 0) {
            tempStr = TEMP_PLACEHOLDER + tempStr.substring(findStrLen);
        } else {
            tempStr = tempStr.substring(0, index) + TEMP_PLACEHOLDER + tempStr.substring(index + findStrLen);
        }

        if (isCaseSensitive) {
            index = tempStr.indexOf(findStr);
        } else {
            index = tempStr.toUpperCase().indexOf(findStr.toUpperCase());
        }
        myCounter++;
    }

    index = tempStr.indexOf(TEMP_PLACEHOLDER);
    findStrLen = TEMP_PLACEHOLDER.length;

    while (index >= 0 && (isInfinite || myCounter > 0)) {
        if (index == tempStr.length - findStrLen) {
            tempStr = tempStr.substring(0, tempStr.length - findStrLen) + replaceWith;
        } else if (index == 0) {
            tempStr = replaceWith + tempStr.substring(findStrLen);
        } else {
            tempStr = tempStr.substring(0, index) + replaceWith + tempStr.substring(index + findStrLen);
        }

        index = tempStr.indexOf(TEMP_PLACEHOLDER);
        myCounter--;
    }
    return tempStr;
}

function Fev_Trim(str) {
    if (str == null) return null;
    var m = str.match(/^\s*(\S+(\s+\S+)*)\s*$/);
    return (m == null) ? "" : m[1];
}

//
// Validation functions
// Note: All Fev_isValid* functions always return true or false (they never throw errors).
//

function Fev_isValidCreditCardNumber(strCreditCardNumber, bIgnoreNonDigits) {
    if ((strCreditCardNumber == null) || (strCreditCardNumber == ''))
        return false;

    var strDigits = Fev_RemoveNonDigits(strCreditCardNumber);

    if ((!bIgnoreNonDigits) && (strDigits != strCreditCardNumber))
        return false;
    if ((strDigits == null) || (strDigits == ''))
        return false;
    if ((strDigits.length < 4) || (strDigits.length > 19))
        return false;

    var strCardType = Fev_ParseCreditCardNumberPrefix(strDigits, true);

    //Validate the card number's length and type
    switch (strCardType) {
        case FEV_CREDIT_CARD_TYPE_VISA:
            if ((strDigits.length != 16) && (strDigits.length != 13)) return false;
            break;
        case FEV_CREDIT_CARD_TYPE_DISCOVER:
        case FEV_CREDIT_CARD_TYPE_MASTER_CARD:
            if (strDigits.length != 16) return false;
            break;
        case FEV_CREDIT_CARD_TYPE_AMERICAN_EXPRESS:
        case FEV_CREDIT_CARD_TYPE_ENROUTE:
            if (strDigits.length != 15) return false;
            break;
        case FEV_CREDIT_CARD_TYPE_CARTE_BLANCHE:
        case FEV_CREDIT_CARD_TYPE_DINERS_CLUB:
            if (strDigits.length != 14) return false;
            break;
        case FEV_CREDIT_CARD_TYPE_JCB:
            if ((strDigits.charAt(0) == 3) && (strDigits.length != 16)) return false;
            else if ((strDigits.charAt(0) != 3) && (strDigits.length != 15)) return false;
            break;
        case FEV_CREDIT_CARD_TYPE_UNKNOWN:
        case FEV_CREDIT_CARD_TYPE_INVALID:
        default:
            return false;
    }

    //Validate the card number's Luhn checksum
    switch (strCardType) {
        case FEV_CREDIT_CARD_TYPE_ENROUTE:
            //EnRoute cards can have any Checksum
            break;
        default:
            if (Fev_ComputeLuhnChecksum(strDigits) != 0) return false;
            break;
    }

    return true;
}


//Valid time format: hh:mm:ss <am|pm>

function Fev_isValidTimeAMPM(strTime) {
    strTime = Fev_Trim(strTime);
    if (strTime == null || strTime == '')
        return false;

    var timeRE = new RegExp('^' + PATTERN_TIME_AMPM + '?$', 'i');
    return timeRE.test(strTime);
}


//Valid time format: hh:mm:ss
//hh: from 0-23 or 00-23
//mm: from 0-59 or 00-59
//ss: from 0-59 or 00-59
function Fev_isValidTime24HR(strTime) {
    strTime = Fev_Trim(strTime);
    if (strTime == null || strTime == '')
        return false;

    var timeRE = new RegExp('^' + PATTERN_TIME_24HR + '?$', 'i');
    return timeRE.test(strTime);
}



//valid USA date [digits - i.e. non alphabetic]:
//[?1-12]/[?1-31]/([00-99]or [0000-9999]) hh:mm:ss[ ]?am/pm
//i.e. month/day/year where
//	month is either 1[january]-12[december], where ? means option ZERO, if under 10
//	day is from 1 to 31, with optional ZERO if under 10.
//	year is either 2 or 4 digits.
//	dividers: slash, space or dash
//hh: from 0-12 or 00-12 (where 0 = 12), or 0-24/00-24
//mm: from 0-59 or 00-59
//ss: from 0-59 or 00-59
//am or pm is optional
function Fev_isValidUsaDate_digits(strDate, isAllowTime) {
    strDate = Fev_Trim(strDate);
    if (strDate == null || strDate == '')
        return false;

    var timePattern = "";
    if (isAllowTime) {
        timePattern += "([\ ](" + PATTERN_TIME_AMPM + "|" + PATTERN_TIME_24HR + "))?";
    }

    var dateArray = new Array('^(([0]?[1-9])|10|11|12)', '(([0]?[0-9])|([1-2][0-9])|30|31)', '(([0-9]{4})|([0-9]{2}))' + timePattern + '$');

    var separatorArray = new Array('\ ', '/', '-');

    var separator;
    var i;
    var found = false;
    var RE;
    for (i = 0; i < separatorArray.length && !found; i++) {
        RE = new RegExp(dateArray.join(separatorArray[i]), 'i');
        if (RE.test(strDate)) {
            found = true;
            separator = separatorArray[i];
        }
    }
    if (!found) return false;

    var dateArr = strDate.split(separator);
    var month = parseInt(dateArr[0], 10);
    var day = parseInt(dateArr[1], 10);
    var year = parseInt(dateArr[2], 10);

    year = Fev_NormalizeYear(year);

    var highestDayOfMonth = Fev_GetHighestDayOfMonth(month, year);
    return (day >= 1 && day <= highestDayOfMonth);
}



//valid USA date [alphanumeric]:
//([jan-dec][.]? or [january-december])/[?1-31]/([00-99]or [0000-9999])
//i.e. month/day/year where
//	month is either january-december, or jan-dec or jan.-dec. (notice abbreviation can have a PERIOD)
//	day is from 1 to 31, with optional ZERO if under 10.
//	year is either 2 or 4 digits.
//	dividers: slash, space or dash
//hh: from 0-12 or 00-12 (where 0 = 12), or 0-24/00-24
//mm: from 0-59 or 00-59
//ss: from 0-59 or 00-59
//am or pm is optional
function Fev_isValidUsaDate_monthinletters(strDate, isAllowTime) {
    strDate = Fev_Trim(strDate);
    if (strDate == null || strDate == '')
        return false;

    var monthsStr = '';
    var i;

    monthsStr += '(((';
    for (i = 0; i < Fev_Get_Months_Short().length; i++) {
        if (i > 0) {
            monthsStr += '|';
        }
        monthsStr += Fev_Get_Months_Short()[i];
    }
    monthsStr += ')[\.]?)|';
    for (i = 0; i < Fev_Get_Months_Long().length; i++) {
        if (i > 0) {
            monthsStr += '|';
        }
        monthsStr += Fev_Get_Months_Long()[i];
    }
    monthsStr += ')';

    var timePattern = "";
    if (isAllowTime) {
        timePattern += "([\ ](" + PATTERN_TIME_AMPM + "|" + PATTERN_TIME_24HR + "))?";
    }

    var dateArray = new Array('^' + monthsStr + '[', '\ ](([0]?[0-9])|([1-2][0-9])|30|31)([', ']|(,[\ ]?))(([0-9]{4})|([0-9]{2}))' + timePattern + '$');

    var separatorArray = new Array('\ ', '/', '-');

    var separator;
    var i;
    var found = false;
    var RE;
    for (i = 0; i < separatorArray.length && !found; i++) {
        RE = new RegExp(dateArray.join(separatorArray[i]), 'i');
        if (RE.test(strDate)) {
            found = true;
            separator = separatorArray[i];
        }
    }
    if (!found) return false;

    var dateArr = strDate.split(separator);
    var month = Fev_MonthStrToInt(dateArr[0]);
    var day = parseInt(dateArr[1], 10);
    var year = parseInt(dateArr[2], 10);

    year = Fev_NormalizeYear(year);

    var highestDayOfMonth = Fev_GetHighestDayOfMonth(month, year);
    return (day >= 1 && day <= highestDayOfMonth);
}



//valid: mm/yyyy  (where m can be 1 or 2 digits)
function Fev_isValidCreditCardDate(strCreditCardDate) {
    var separatorArray = new Array('\ ', '/', '-');

    var ccDateArray = new Array('^(([0]?[1-9])|10|11|12)[', '][0-9]{4}$');

    var separator;
    var i;
    var found = false;
    var RE;
    for (i = 0; i < separatorArray.length && !found; i++) {
        RE = new RegExp(ccDateArray.join(separatorArray[i]), 'i');
        if (RE.test(strCreditCardDate)) {
            found = true;
            separator = separatorArray[i];
        }
    }
    if (!found) return false;
    return true;
}


//valid numbers:
// - without commas:	zero
//						<optional minus>(1st digit is non-zero)[unlimited number of digits]
// - with commas:	zero
//					<optional minus>(non-zero digit)<0or1or2 digits><(comma)(3 digits)>*
//  also can have unlimited # of leading zero's (in the whole part of the number)
//  also can have unlimited # of trailing zero's in the decimal portion
function Fev_isValidInteger(strInteger, minValue, maxValue) {
    strInteger = Fev_Trim(strInteger);
    if (strInteger == null || strInteger == '')
        return false;

    return Fev_isValidFloatUpToNDecimals(strInteger, 0, minValue, maxValue);
    //	var integerRE = new RegExp('^(([-]?[1-9][0-9]*)|[0])$');	//without commas
    //	var integerWithCommaRE = new RegExp('^(([-]?[1-9][0-9]{0,2}(,[0-9]{3})*)|0)$');	//with commas
    //	return integerRE.test(strInteger) || integerWithCommaRE.test(strInteger);
}


//same format as Fev_isValidInteger, in addition to:
//	+ <(decimal point)(unlimited number of digits)>
//  also can have unlimited # of leading zero's (in the whole part of the number)
//  also can have unlimited # of trailing zero's in the decimal portion
function Fev_isValidFloat(strFloat, minValue, maxValue) {
    return Fev_isValidFloatUpToNDecimals(strFloat, -1, minValue, maxValue);
}


//called by Fev_isValidFloat.
//can specify the max number of allowed decimal digits
//can specify min value
//can specify max value
//  where a non positive number is unlimited, and any positive number is used as max num of decimal digits
//  also can have unlimited # of leading zero's (in the whole part of the number)
//  also can have unlimited # of trailing zero's in the decimal portion
function Fev_isValidFloatUpToNDecimals(strFloat, maxDecimalDigits, minValue, maxValue) {
    if (maxDecimalDigits == null || maxDecimalDigits == '')
        maxDecimalDigits = -1;
    minValue = Fev_Trim(minValue);
    maxValue = Fev_Trim(maxValue);

    strFloat = Fev_Trim(strFloat);
    if (strFloat == null || strFloat == '')
        return false;

    var decStr = "";
    if (isNaN(maxDecimalDigits) || (maxDecimalDigits < 0)) {
        decStr += "[\.][0-9]*";
    } else if (maxDecimalDigits == 0) {
        decStr += "[\.][0]*";
    } else {
        decStr += "[\.][0-9]{0," + parseInt(maxDecimalDigits, 10) + "}0*";
    }

    var floatRE = new RegExp('^(([-]?[0]*[0-9]*))(' + decStr + ')?$'); //without commas
    var floatWithCommaRE = new RegExp('^([-]?[0-9]{1,3}(,[0-9]{3})*)(' + decStr + ')?$'); //with commas

    if (!(floatRE.test(strFloat) || floatWithCommaRE.test(strFloat))) {
        return false;
    }

    var myNum = parseFloat(Fev_StrReplace(strFloat, ",", "", false, -1));

    if (!isNaN(minValue)) {
        minValue = parseInt(minValue, 10);
        if (myNum < minValue) {
            return false;
        }
    }
    if (!isNaN(maxValue)) {
        maxValue = parseInt(maxValue, 10);
        if (myNum > maxValue) {
            return false;
        }
    }

    return true;
}


function Fev_isValidCurrency(strCurrency, numDecimals, minValue, maxValue) {
    // Currency validation is handled by the Parse routine in the VB or CS code to ensure that all international currency formats are supported properly.
    return true;

    strCurrency = Fev_Trim(strCurrency);
    if (strCurrency == null || strCurrency == '')
        return false;

    var moneyRE = new RegExp('^([\$])?[\-]?([\$])?([0-9]*[\.]?[0-9]*)$');
    var moneyWithParenthesesRE = new RegExp('^([\$])?[\(]([\$])?([0-9]*[\.]?[0-9]*)([\$])?[\)]([\$])?$');

    if (moneyRE.test(strCurrency)) {
        var myArr = strCurrency.match(moneyRE);

        if (myArr == null)
            return false;

        if (myArr.length > 3) {
            //make sure only one $ sign
            if ((myArr[1] + myArr[2]).length > 1) {
                return false;
            }
            return Fev_isValidFloatUpToNDecimals(myArr[3], numDecimals, minValue, maxValue);
        }
    } else if (moneyWithParenthesesRE.test(strCurrency)) {
        var myArr = strCurrency.match(moneyWithParenthesesRE);
        if (myArr == null)
            return false;

        if (myArr.length > 5) {
            //make sure only one $ sign
            if ((myArr[1] + myArr[2] + myArr[4] + myArr[5]).length > 1) {
                return false;
            }
            return Fev_isValidFloatUpToNDecimals(myArr[3], numDecimals, minValue, maxValue);
        }
    }

    return false;
}


function Fev_isValidPercentage(strPercentage, numDecimals, minValue, maxValue) {
    strPercentage = Fev_Trim(strPercentage);
    if (strPercentage == null || strPercentage == '')
        return false;

    var percentageRE = new RegExp('^[\-]?([0-9]*[\.]?[0-9]*)[\%]?$');

    if (percentageRE.test(strPercentage)) {
        var myArr = strPercentage.match(percentageRE);

        if (myArr == null)
            return false;

        if (myArr.length > 1) {
            return Fev_isValidFloatUpToNDecimals(myArr[1], numDecimals, minValue, maxValue);
        }
    }

    return false;
}



function Fev_isValidEmailAddress(strEmailAddress) {
    return true; //function is too strict. see http://www.aspemporium.com/aspEmporium/tutorials/emailvalidation.asp

    if (bShowAlerts)
        checkTLD = 1;
    else
        checkTLD = 0;

    /* The following pattern is used to check if the entered e-mail address
    fits the user@domain format.  It also is used to separate the username
    from the domain. */

    var emailPat = /^(.+)@(.+)$/;

    /* The following pattern applies if the "user" is a quoted string (in
    which case, there are no rules about which characters are allowed
    and which aren't; anything goes).  E.g. "jiminy cricket"@disney.com
    is a legal e-mail address. */

    var quotedUser = "(\"[^\"]*\")";

    /* The following string represents one word in the typical username.
    For example, in john.doe@somewhere.com, john and doe are words.
    Basically, a word is either an atom or quoted string. */

    var word = "(" + atom + "|" + quotedUser + ")";

    // The following pattern describes the structure of the user

    var userPat = new RegExp("^" + word + "(\\." + word + ")*$");

    /* Finally, let's start trying to figure out if the supplied address is valid. */

    /* Begin with the coarse pattern to simply break up user@domain into
    different pieces that are easy to analyze. */

    var matchArray = strEmailAddress.match(emailPat);

    if (matchArray == null) {
        /* Too many/few @'s or something; basically, this address doesn't
        even fit the general mould of a valid e-mail address. */

        if (bShowAlerts) alert("Email address seems incorrect (check @ and .'s)");
        return false;
    }
    var strUser = matchArray[1];
    var strDomain = matchArray[2];

    // Start by checking that only basic ASCII characters are in the strings (0-127).

    for (i = 0; i < strUser.length; i++) {
        if (strUser.charCodeAt(i) > 127) {
            if (bShowAlerts) alert("Ths username contains invalid characters.");
            return false;
        }
    }
    for (i = 0; i < strDomain.length; i++) {
        if (strDomain.charCodeAt(i) > 127) {
            if (bShowAlerts) alert("Ths domain name contains invalid characters.");
            return false;
        }
    }

    // See if "user" is valid 

    if (strUser.match(userPat) == null) {
        // user is not valid
        if (bShowAlerts) alert("The username doesn't seem to be valid.");
        return false;
    }

    return Fev_isIsReallyAValidDomain(strDomain);
}


function Fev_isValidUrl(strUrl) {
    var myUrlDataArr = Fev_ParseUrl(strUrl);
    if (myUrlDataArr == null) {
        myUrlDataArr = Fev_ParseUrl("http://" + strUrl);
    }

    if (myUrlDataArr == null) {
        return false;
    } else {
        return true;
    }
}


//valid boolean values: 'T' for True, 'F' for False.
//that's it, that's all
function Fev_isValidBoolean(strBoolean) {
    return true; //disabled, because it does not handle display string values.
    strBoolean = Fev_Trim(strBoolean);
    if (strBoolean == null || strBoolean.length == '')
        return false;

    return (strBoolean == 'T' || strBoolean == 'F');
}


function Fev_isValidPassword(strPassword, minLength, maxLength) {
    strPassword = Fev_Trim(strPassword);
    if (strPassword == null || strPassword.length < minLength)
        return false;

    if (isNaN(minLength)) {
        minLength = 0;
    } else {
        minLength = parseInt(minLength);
        if (minLength < 0) {
            minLength = 0;
        }
    }

    if (isNaN(maxLength)) {
        maxLength = null;
    } else {
        maxLength = parseInt(maxLength);
        if (maxLength < minLength) {	//if maxLength < minLength, then don't even bother checking if the password is too long
            maxLength = null;
        }
    }

    if (strPassword.length < minLength)
        return false;

    if (maxLength != null && strPassword.length > maxLength)
        return false;

    return true;
}


//valid phone number formats:
//(ddd)<space or separator>ddd<separator>dddd<(ext<.> or x)<space>(1-5 digits)>
//	note:	opening+closing parentheses come together, and are optional
//			separator is either 'space', '.' or '-'... and try to match only by one kind of separator at a time
//					e.g. 333-333-3333 or (222).333.4556 or 333 333 3333 are all three OK, but 444-333.3333 is NOT
function Fev_isValidUsaPhoneNumber(strUsaPhoneNumber) {
    strUsaPhoneNumber = Fev_Trim(strUsaPhoneNumber);
    if (strUsaPhoneNumber == null || strUsaPhoneNumber == '')
        return false;
    var myREasArray = new Array('^((([0-9]{3})|[\(][0-9]{3}[\)])[', '\ ]?)?[0-9]{3}[', ']?[0-9]{4}([\ ]((ext)[\.]?|(x))[\ ]?[0-9]{1,5})?$');
    //var phoneRE = new RegExp('^(([0-9]{3})|[\(][0-9]{3}[\)])[-\.\ ]?[0-9]{3}[-\.\ ]?[0-9]{4}$');
    var phoneRE_dash = new RegExp(myREasArray.join("-"), "i");
    var phoneRE_period = new RegExp(myREasArray.join("\."), "i");
    var phoneRE_space = new RegExp(myREasArray.join("\ "), "i");
    return (phoneRE_dash.test(strUsaPhoneNumber) || phoneRE_period.test(strUsaPhoneNumber) || phoneRE_space.test(strUsaPhoneNumber));
}


//valid country format: a-z, dash, space, apostrophe, period, opening parenthesis closing parenthesis
function Fev_isValidCountry(strCountry) {
    strCountry = Fev_Trim(strCountry);
    if (strCountry == null || strCountry == '')
        return false;
    var re = new RegExp("^([a-z\-\ \'\.\(\)])*$", 'i');

    return re.test(strCountry);
}



//valid state format: 2-letter abbreviation (e.g. "CA" for California) full name (e.g. "Arkansas", "New York")
function Fev_isValidUsaState(strUsaState) {
    strUsaState = Fev_Trim(strUsaState);
    if (strUsaState == null || strUsaState == '')
        return false;

    var stateAbbrevRE = new RegExp('^(al|ak|az|ar|ca|co|ct|dc|de|fl|ga|hi|id|il|in|ia|ks|ky|la|me|md|ma|mi|mn|ms|mo|mt|ne|nv|nh|nj|nm|ny|nc|nd|oh|ok|or|pa|ri|sc|sd|tn|tx|ut|vt|va|wa|wv|wi|wy)$', 'i');
    var stateFullRE = new RegExp('^(alabama|alaska|arizona|arkansas|california|colorado|connecticut|delaware|florida|georgia|hawaii|idaho|illinois|indiana|iowa|kansas|kentucky|louisiana|maine|maryland|massachusetts|michigan|minnesota|mississippi|missouri|montana|nebraska|nevada|new hampshire|new jersey|new mexico|new york|north carolina|north dakota|ohio|oklahoma|oregon|pennsylvania|rhode island|south carolina|south dakota|tennessee|texas|utah|vermont|virginia|washington|(washington((,[\ ]?)|[\ ])((district of columbia)|(d[\.]?c[\.]?)))|west virginia|wisconsin|wyoming)$', 'i');

    return stateAbbrevRE.test(strUsaState) || stateFullRE.test(strUsaState);
}


//valid zip code formats: ddddd, ddddd-dddd
function Fev_isValidUsaZipCode(strUsaZipCode) {
    strUsaZipCode = Fev_Trim(strUsaZipCode);
    if (strUsaZipCode == null || strUsaZipCode == '')
        return false;
    var zipRE = new RegExp('^[0-9]{5}([- ]?[0-9]{4})?$')
    return zipRE.test(strUsaZipCode);
}



//valid filename: any character other than: backslash, slash, colon, asterisk (*), questionmark, double-quote, >, <, vertical bar (|)
//ends with jpg|jpe|jpeg|gif|bmp|png
function Fev_isValidImagePath(strPath) {
    strPath = Fev_Trim(strPath);
    if (strPath == null || strPath == '')
        return false;
    var imagePathRE = new RegExp('[\.](jpg|jpe|jpeg|gif|bmp|png)$', 'i');
    return imagePathRE.test(strPath) && Fev_isValidWindowsFileName(strPath);
}


//[drive]:[\(dir)]*[\(dir|filename)]{0,1}
function Fev_isValidWindowsFilePath(strPath) {
    strPath = Fev_Trim(strPath);
    if (strPath == null || strPath == '')
        return false;
    var filePathRE = new RegExp('^[a-z][\:]([\\\\][^\\\/\:\*\?\"\<\>\|]*)*$', 'i');
    return filePathRE.test(strPath);
}


//valid filename: any character other than: backslash, slash, colon, asterisk (*), questionmark, double-quote, >, <, vertical bar (|)
function Fev_isValidWindowsFileName(strFilename) {
    strFilename = Fev_Trim(strFilename);
    if (strFilename == null || strFilename == '')
        return false;
    if (strFilename.indexOf("\\") >= 0)
        return false;
    var filePathRE = new RegExp('^[^\\\/\:\*\?\"\<\>\|]*$', 'i');
    return filePathRE.test(strFilename);
}


//
// Helper Variables
//

//private variables, should not be called except by Fev_Get_Months_Long, and Fev_Get_Months_Short
var PATTERN_TIME_AMPM = '(([0]?[0-9])|10|11|12)[\:]([0-5]?[0-9])[\:]([0-5]?[0-9])([\ ]?(AM|PM))';
var PATTERN_TIME_24HR = '(([0-1]?[0-9])|20|21|22|23)[\:]([0-5]?[0-9])[\:]([0-5]?[0-9])';

var Fev_MONTHS_LONG = null;
var Fev_MONTHS_SHORT = null;

/* The following variable tells the rest of the function whether or not
to display alerts that specify why the value is invalid */

var bShowAlerts = false;

/* The following string represents the pattern for matching all special
characters.  We don't want to allow special characters in the address. 
These characters include ( ) < > @ , ; : \ " . [ ] */

var specialChars = "\\(\\)><@,;:\\\\\\\"\\.\\[\\]";

/* The following string represents the range of characters allowed in a 
username or domainname.  It really states which chars aren't allowed.*/

var validChars = "\[^\\s" + specialChars + "\]";

/* The following string represents an atom (basically a series of non-special characters.)
*/

var atom = validChars + '+';

/* The following variable tells the rest of the function whether or not
to verify that the address ends in a two-letter country or well-known
TLD.  1 means check it, 0 means don't. */

var checkTLD = 0;



//
// Validation Helper functions
//

//This function returns an array containing the error message strings of 
//all invalid validators in the page.  Duplicates are ignored.
function Fev_GetInvalidValidatorErrorMessages() {
    var i, j;
    var msgArray = new Array();
    if (!Page_IsValid) {
        for (i = 0; i < Page_Validators.length; i++) {
            if (!Page_Validators[i].isvalid && typeof (Page_Validators[i].errormessage) == "string") {
                var msg = Page_Validators[i].errormessage;
                var b = false;
                for (j = 0; j < msgArray.length; j++) {
                    if (msgArray[j] == msg) {
                        b = true;
                        break;
                    }
                }
                if (!b) {
                    msgArray[msgArray.length] = msg;
                }
            }
        }
    }
    return msgArray;
}

//returns an int between 0 and 9 (inclusive)
function Fev_ComputeLuhnChecksum(strDigits) {
    strDigits = Fev_RemoveNonDigits(strDigits);
    var digit;
    var i;
    var sum = 0;

    for (i = strDigits.length - 2; i >= 0; i -= 2) {
        digit = parseInt(strDigits.charAt(i), 10);
        digit *= 2;
        sum += ((digit > 9) ? (digit - 9) : (digit));
    }
    for (i = strDigits.length - 1; i >= 0; i -= 2) {
        digit = parseInt(strDigits.charAt(i), 10);
        sum += digit;
    }

    return (sum % 10);
}

//Returns one of the Credit Card Type constants (FEV_CREDIT_CARD_TYPE_*)
function Fev_ParseCreditCardNumberPrefix(strCardNumber, bIgnoreNonDigits) {
    //Card Types             Prefix            Width      Luhn Checksum        Example
    //American Express       34, 37            15         Mod 10 = 0           3400 0000 0000 009
    //Diners Club            300 to 305, 36    14         Mod 10 = 0           3000 0000 0000 04
    //Carte Blanche          38                14         Mod 10 = 0           3000 0000 0000 04
    //Discover               6011              16         Mod 10 = 0           6011 0000 0000 0004
    //EnRoute                2014, 2149        15         Any                  2014 0000 0000 009
    //JCB                    3                 16         Mod 10 = 0           3088 0000 0000 0009
    //JCB                    2131, 1800        15         Mod 10 = 0           
    //Master Card            51 to 55          16         Mod 10 = 0           5500 0000 0000 0004
    //Visa                   4                 13, 16     Mod 10 = 0           4111 1111 1111 1111

    if (bIgnoreNonDigits)
        strCardNumber = Fev_RemoveNonDigits(strCardNumber);

    if (strCardNumber.length < 4)
        return FEV_CREDIT_CARD_TYPE_INVALID;
    if (Fev_RemoveNonDigits(strCardNumber.substr(0, 4)).length < 4)
        return FEV_CREDIT_CARD_TYPE_INVALID;

    //Parse 1st 2 digits
    switch (parseInt(strCardNumber.substr(0, 2), 10)) {
        case 51:
        case 52:
        case 53:
        case 54:
        case 55:
            return FEV_CREDIT_CARD_TYPE_MASTER_CARD;
        case 34:
        case 37:
            return FEV_CREDIT_CARD_TYPE_AMERICAN_EXPRESS;
        case 36:
            return FEV_CREDIT_CARD_TYPE_DINERS_CLUB;
        case 38:
            return FEV_CREDIT_CARD_TYPE_CARTE_BLANCHE;
    }

    //Parse 1st 4 digits
    switch (parseInt(strCardNumber.substr(0, 4), 10)) {
        case 6011:
            return FEV_CREDIT_CARD_TYPE_DISCOVER;
        case 2014:
        case 2149:
            return FEV_CREDIT_CARD_TYPE_ENROUTE;
        case 2131:
        case 1800:
            return FEV_CREDIT_CARD_TYPE_JCB;
    }

    //Parse 1st 3 digits
    switch (parseInt(strCardNumber.substr(0, 3), 10)) {
        case 300:
        case 301:
        case 302:
        case 303:
        case 304:
        case 305:
            return FEV_CREDIT_CARD_TYPE_DINERS_CLUB;
    }

    //Parse 1st digit
    switch (parseInt(strCardNumber.substr(0, 1), 10)) {
        case 4:
            return FEV_CREDIT_CARD_TYPE_VISA;
        case 3:
            return FEV_CREDIT_CARD_TYPE_JCB;
    }

    return FEV_CREDIT_CARD_TYPE_UNKNOWN;
}

function Fev_Get_Months_Long() {
    if (Fev_MONTHS_LONG == null) {
        Fev_MONTHS_LONG = new Array('january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december');
    }
    return Fev_MONTHS_LONG;
}

function Fev_Get_Months_Short() {
    if (Fev_MONTHS_SHORT == null) {
        Fev_MONTHS_SHORT = new Array('jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', '(sep[t]?)', 'oct', 'nov', 'dec');
    }
    return Fev_MONTHS_SHORT;
}

function Fev_MonthStrToInt(strMonth) {
    var INVALID_MONTH = -1;
    if (strMonth == null || strMonth == '')
        return INVALID_MONTH;

    strMonth = strMonth.toLowerCase();
    var i;
    for (i = 0; i < Fev_Get_Months_Long().length; i++) {
        if (strMonth == Fev_Get_Months_Long()[i] || strMonth == Fev_Get_Months_Short()[i] || strMonth == (Fev_Get_Months_Short()[i] + '.')) {
            return i + 1;
        }
    }

    return -1;
}

function Fev_isValidMonth(month) {
    var myMonth = parseInt(month, 10);
    if (isNaN(myMonth)) {
        return false;
        //will need to support non numeric months
    } else {
        return (myMonth >= 1 && myMonth <= 12);
    }
}

function Fev_NormalizeYear(intYear) {
    if (intYear < 100) {
        if (intYear > 30) {
            intYear += 1900;
        } else {
            intYear += 2000;
        }
    }
    return intYear;
}

function Fev_GetHighestDayOfMonth(intMonth, intYear) {
    var isLeapYear = Fev_isLeapYear(intYear);

    var highestDayOfMonth = -1;
    switch (intMonth) {
        case 1:
        case 3:
        case 5:
        case 7:
        case 8:
        case 10:
        case 12:
            highestDayOfMonth = 31;
            break;
        case 4:
        case 6:
        case 9:
        case 11:
            highestDayOfMonth = 30;
            break;
        case 2:
            if (isLeapYear) {
                highestDayOfMonth = 29;
            } else {
                highestDayOfMonth = 28;
            }
            break;
        default:
            break;
    }

    return highestDayOfMonth;
}

function Fev_isLeapYear(strYear) {
    if ((strYear == null) || (strYear == ''))
        return false;

    var strYearFormat = new RegExp('^([0-9]{4}|[0-9]{2})');

    if (!strYearFormat.test(strYear))
        return false;

    var intYear = parseInt(strYear, 10);

    if (intYear % 400 == 0)
        return true;
    if (intYear % 100 == 0)
        return false;
    if (intYear % 4 == 0)
        return true;

    return false;
}

function Fev_ParseUrl(strUrl) {
    //[a-zA-Z0-9]([\$-_\.\+][a-zA-Z0-9])*[a-zA-Z0-9]
    //(http|https|ftp)://(<user>(:<password>)+[\@])+<host>(:<port>)+(/<url-path>)+

    var myStuffStr = "";
    var myStuffArr = null;

    //	var urlRE = new RegExp('^(http|https|ftp)\://([0-9a-z]+([\.\-][0-9a-z]+)*)([/][0-9a-z]*)*$', 'i');
    var urlRE = new RegExp('^(http|https|ftp)\://(([^\/:]+)([\:]([^\/:]*))?\@)?([a-z0-9]([a-z0-9\-\.]+[a-z0-9])?)(:([0-9]{1,5}))?([/][^\/]*)*$', 'i');

    if (!urlRE.test(strUrl)) return myStuffArr;

    var myArr = strUrl.match(urlRE);

    var strProtocol, strHost, strPath, strPort, strUsername, strPassword;

    //alert("test for " + strUrl + "...\ndoes it fit url pattern? = " + urlRE.test(strUrl));

    if (myArr != null) {
        var i = 0;
        for (i = 0; i < myArr.length; i++) {
            switch (i) {
                case 1:
                    //myStuffStr += "protocol: ";
                    strProtocol = myArr[i];
                    break;
                case 3:
                    //myStuffStr += "username: ";
                    strUsername = myArr[i];
                    break;
                case 5:
                    //myStuffStr += "password: ";
                    strPassword = myArr[i];
                    break;
                case 6:
                    //myStuffStr += "host: ";
                    strHost = myArr[i];
                    break;
                case 9:
                    //myStuffStr += "port: ";
                    strPort = myArr[i];
                    break;
                case 10:
                    //myStuffStr += "path: ";
                    strPath = myArr[i];
                    break;
                default:
                    break;
            }
            //alert(myArr[i]);
        }

        if (Fev_isIsReallyAValidDomain(strHost)) {
            myStuffArr = new Array(7);
            myStuffArr[0] = strUrl;
            myStuffArr[1] = strProtocol;
            myStuffArr[2] = strHost;
            myStuffArr[3] = strPort;
            myStuffArr[4] = strPath;
            myStuffArr[5] = strUsername;
            myStuffArr[6] = strPassword;
        }

        myStuffStr += "url: " + strUrl + "\n";
        myStuffStr += "protocol: " + strProtocol + "\n";
        myStuffStr += "host: " + strHost + "\n";
        myStuffStr += "port: " + strPort + "\n";
        myStuffStr += "path: " + strPath + "\n";
        myStuffStr += "username: " + strUsername + "\n";
        myStuffStr += "password: " + strPassword;
    }

    //alert(myStuffStr);
    //alert(myStuffStr + "\n\n" + strHost + " is Valid domain?: " + Fev_isIsReallyAValidDomain(strHost));

    //alert(strHost + " is Valid domain?: " + Fev_isIsReallyAValidDomain(strHost));

    return myStuffArr;
}

function Fev_isIsReallyAValidDomain(strDomain) {
    if (Fev_isAQuadDomain(strDomain)) {
        return Fev_isValidIP(strDomain);
    } else {
        return Fev_isValidDomain(strDomain);
    }
}

// determines if a domain is in "ddd.ddd.ddd.ddd" format
function Fev_isAQuadDomain(strDomain) {
    var ipDomainPat = new RegExp('^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$');

    var IPArray = strDomain.match(ipDomainPat);
    return (IPArray != null);
}

//given a str, detemine if it's a valid IP address
function Fev_isValidIP(strDomain) {
    var ipDomainPat = new RegExp('^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$');

    var IPArray = strDomain.match(ipDomainPat);
    if (IPArray != null) {
        // this is an IP address

        for (var i = 1; i <= 4; i++) {
            if (IPArray[i] > 255) {
                return false;
            }
        }
        return true;
    }
    return false;
}

//given a str, detemine if it's a valid domain name
function Fev_isValidDomain(strDomain) {

    /* The following pattern describes the structure of a normal symbolic
    domain, as opposed to ipDomainPat, shown above. */

    var domainPat = new RegExp("^" + atom + "(\\." + atom + ")*$");

    // Domain is symbolic name.  Check if it's valid.

    var atomPat = new RegExp("^" + atom + "$");
    var domArr = strDomain.split(".");
    var len = domArr.length;
    for (i = 0; i < len; i++) {
        if (domArr[i].search(atomPat) == -1) {
            if (bShowAlerts) alert("The domain name does not seem to be valid.");
            return false;
        }
    }

    /* The following is the list of known TLDs that an e-mail address must end with. */
    var knownDomsPat = /^(com|net|org|edu|int|mil|gov|arpa|biz|aero|name|coop|info|pro|museum)$/;

    /* domain name seems valid, but now make sure that it ends in a
    known top-level domain (like com, edu, gov) or a two-letter word,
    representing country (uk, nl), and that there's a hostname preceding 
    the domain or country. */

    if (checkTLD && domArr[domArr.length - 1].length != 2 &&
		domArr[domArr.length - 1].search(knownDomsPat) == -1) {
        if (bShowAlerts)
            alert("The address must end in a well-known domain or two letter " + "country.");
        return false;
    }

    // Make sure there's a host name preceding the domain.
    // this requires SOMETHING.TLD
    //	if (len<2) {
    //		if (bShowAlerts)
    //			alert("This address is missing a hostname!");
    //		return false;
    //	}

    // If we've gotten this far, everything's valid!
    return true;
}

