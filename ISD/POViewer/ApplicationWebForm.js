var submitcount = 0;

function checkDisable(node) {
    return ((node != null) && (node.disabled != true));
}

/*
* Avoid tabs to get focused during page load.  This is called in the master page, page directive.
*/

function avoidTabFocused() {
   if (Sys == null || Sys.Extended == null || Sys.Extended.UI == null || Sys.Extended.UI.TabContainer == null)
        return;

    Sys.Extended.UI.TabContainer.prototype._app_onload = function(sender, e) {
        if (this._cachedActiveTabIndex != -1) {
            this.set_activeTabIndex(this._cachedActiveTabIndex);
            this._cachedActiveTabIndex = -1;

            var activeTab = this.get_tabs()[this._activeTabIndex];
            if (activeTab) {
                activeTab._wasLoaded = true;
                //activeTab._setFocus(activeTab); -- disable focus on active tab in the last TabContainer
            }
        }
        this._loaded = true;
    }
}

/*
* Sets the focus on the first element that should "reasonably" receive it
*/
function Fev_FocusOnFirstFocusableFormElement() {
    var lFirstFocusableFormElementID;
    for (i = 0; i < document.forms.length; i++) {
        lFirstFocusableFormElementID = Fev_FocusOnDefaultElement(document.forms[i]);
        if (lFirstFocusableFormElementID != false) {
            return (lFirstFocusableFormElementID);
        }
    }

    return (null);
}

/*
* Sets the focus on the first element that should "reasonably" receive it. Called from SetFocus, while previous function
* called by migrated application
*/
function Fev_FocusOnFirstFocusableFormElement_FromSetFocus() {
    var lFirstFocusableFormElementID;
    if (document != null && document.forms != null && document.forms.length > 0) {
        for (i = 0; i < document.forms.length; i++) {
            lFirstFocusableFormElementID = Fev_FocusOnDefaultElement_FromSetFocus(document.forms[i]);
            if (lFirstFocusableFormElementID != false) {
                return (lFirstFocusableFormElementID);
            }
        }
    }
    return (null);
}


/*
* verifies if the element inside content area, not in the header
* IMPORTANT: if you modified the name of the content place holder in Application Generation Options, add it here to the list
* for example '|| (objElement.id.indexOf("_MyNewPlaceHolder_") != -1)
*/
function IsElementInContent(objElement) {
    if ((objElement.id.indexOf("_PageContent_") != -1)) {
        return true;
    }
    else return false;
}



function ISD_LocationErrorHandler(positionError) {
    try {
        if (positionError) {
            switch (positionError.code) {
                case 0:
                    break;

                case positionError.TIMEOUT:
                    isd_geo_location.value = "<location><error>LOCATION_ERROR_TIMEOUT</error></location>";
                    break;

                case positionError.PERMISSION_DENIED:
                    isd_geo_location.value = "<location><error>LOCATION_ERROR_PERMISSION_DENIED</error></location>";
                    break;

                case positionError.POSITION_UNAVAILABLE:
                    isd_geo_location.value = "<location><error>LOCATION_ERROR_POSITION_UNAVAILABLE</error></location>";
                    break;

                default:
                    isd_geo_location.value = "<location><error>LOCATION_ERROR_UNKNOWN</error></location>";
                    break;
            }
        }
    } catch (e) {
    }

    __doPostBack("isd_geo_location", "");
}



var isd_geo_location = null;


function ISD_ShowLocation(position) {
    var lat = position.coords.latitude;
    var lng = position.coords.longitude;
    var alt = position.coords.altitude;
    var acc = position.coords.accuracy;
    var altAcc = position.coords.altitudeAccuracy;
    var heading = position.coords.heading;
    var speed = position.coords.speed;

    var value = "<location>";
    if (lat) {
        value += ("<latitude>" + lat + "</latitude>");
    }
    if (lng) {
        value += ("<longitude>" + lng + "</longitude>");
    }
    if (alt) {
        value += ("<altitude>" + alt + "</altitude>");
    }
    if (acc) {
        value += ("<accuracy>" + acc + "</accuracy>");
    }
    if (altAcc) {
        value += ("<altitudeaccuracy>" + altAcc + "</altitudeaccuracy>");
    }
    if (speed) {
        value += ("<speed>" + speed + "</speed>");
    }
    if (heading) {
        value += ("<heading>" + heading + "</heading>");
    }
    value += ("<unit>meters</unit>");

    value += ("<donotretrievebrowserlocation>true</donotretrievebrowserlocation>");

    value += "</location>";

    isd_geo_location.value = value;

    __doPostBack("isd_geo_location", "");
}


function ISD_GeolocationInit() {
    var iframeName = "";
    if (window.frameElement != null) {
        iframeName = window.frameElement.id;
    }
    if(iframeName.indexOf("Infiniteframe") == -1){
    	isd_geo_location = document.getElementById("isd_geo_location");
    }

    if (isd_geo_location != null) {
        if (isd_geo_location.value.indexOf("<donotretrievebrowserlocation>") < 0 && isd_geo_location.value.indexOf("<error>") < 0) {
            if (navigator.geolocation) {
                isd_geo_location.value = "<location><error>LOCATION_ERROR_NO_RESPONSE</error></location>";
                navigator.geolocation.getCurrentPosition(ISD_ShowLocation, ISD_LocationErrorHandler);
            } else {
                isd_geo_location.value = "<location><error>LOCATION_ERROR_UNSUPPORTED</error></location>";
                __doPostBack("isd_geo_location", "");
            }
        }
    }
}




function ISD_CopyPageSize(dropdown) {
    var buttonCtrl = document.getElementById(dropdown.id.replace("PageSizeSelector", "PageSizeButton"));
    var pageSize = "5";

    if (buttonCtrl == null) {
        var buttonCtrl = document.getElementById(dropdown.id.replace("_PageSizeSelector", "PageSizeButton"));

        if (buttonCtrl == null) {
            return;
        }
    }
    if (dropdown.selectedIndex >= 0) {
        pageSize = dropdown.options[dropdown.selectedIndex].text;
    }

    if (navigator.appName.toUpperCase().indexOf(('Microsoft').toUpperCase()) >= 0) {
        buttonCtrl.click();
    } else {
        var l_newEvent = document.createEvent("MouseEvents");
        l_newEvent.initEvent("click", true, true);
        buttonCtrl.dispatchEvent(l_newEvent);
    }
}

function ISD_InfiScrollHandler(dropdown) {
    var buttonCtrl = document.getElementById(dropdown.id.replace("PageSize", "PageSizeButton"));

    if (buttonCtrl == null) {
        var buttonCtrl = document.getElementById(dropdown.id.replace("_PageSizeSelector", "PageSizeButton"));

        if (buttonCtrl == null) {
            return;
        }
    }
    if (navigator.appName.toUpperCase().indexOf(('Microsoft').toUpperCase()) >= 0) {
        buttonCtrl.click();
    } else {
        var l_newEvent = document.createEvent("MouseEvents");
        l_newEvent.initEvent("click", true, true);
        buttonCtrl.dispatchEvent(l_newEvent);
    }
          
}


var ISD_OpenFilterOrLanguagePanelElement = null;
var ISD_OpenFilterOrLanguageButtonElement = null;


function ISD_GetPosition(oElement, propertyName) {
    var returnValue = 0;

    try {
        while (oElement != null) {
            returnValue += eval("oElement." + propertyName);
            oElement = oElement.offsetParent;
        }
    } catch (e) {
        returnValue = 0;
    }

    return returnValue;
}



function ISD_HidePopupPanel() {
    if (ISD_OpenFilterOrLanguagePanelElement != null && ISD_OpenFilterOrLanguagePanelElement.style.visibility == "visible") {
        ISD_OpenFilterOrLanguagePanelElement.style.visibility = "hidden";
        ISD_OpenFilterOrLanguagePanelElement = null;
        ISD_OpenFilterOrLanguageButtonElement = null;
    }
}



function ISD_HandlePopupResize() {
    if (ISD_OpenFilterOrLanguagePanelElement == null) {
        return;
    }

    var leftValue = ISD_GetPosition(ISD_OpenFilterOrLanguageButtonElement, "offsetLeft");
    var topValue = ISD_GetPosition(ISD_OpenFilterOrLanguageButtonElement, "offsetTop");

    topValue += ISD_OpenFilterOrLanguageButtonElement.offsetHeight / 2 - 3;

    if (ISD_OpenFilterOrLanguageButtonElement.tagName == "A") {
        topValue += 20;
        leftValue += (gRTL ? -18 : 20);
    } else {
        topValue += 22;
    }

    try {
        if (!gRTL) {
            leftValue = leftValue - ISD_OpenFilterOrLanguagePanelElement.offsetWidth + ISD_OpenFilterOrLanguageButtonElement.offsetWidth;
        }
    } catch (e) {
    }
    if (leftValue < 0) {
        leftValue = 0;
    }

    ISD_OpenFilterOrLanguagePanelElement.style.left = leftValue + "px";
    ISD_OpenFilterOrLanguagePanelElement.style.top = topValue + "px";
}







var allowModernButtonClick = false;

function ISD_ModernButtonClick(oElement, evt) {
    if (allowModernButtonClick) {
        return false;
    }
    if (evt == null) {
        evt = window.event;
    }

    var didIt = false;

    if (evt != null) {
        if (evt.cancelBubble != null) {
            evt.cancelBubble = true;
            didIt = true;
        }

        if (evt.stopPropagation != null) {
            evt.stopPropagation();
            didIt = true;
        }
    }

    if (didIt) {
        allowModernButtonClick = true;
        oElement.childNodes[0].onclick();

        return false;
    } else {
        return true;
    }
}




function ISD_ShowPopupPanel(panelName, buttonName, oElement) {
    if (!allowModernButtonClick) {
        return false;
    }
    allowModernButtonClick = false;

    var originalPanelName = panelName;
    var idx = oElement.id.indexOf(buttonName);

    if (idx >= 0) {
        panelName = oElement.id.substring(0, idx) + panelName;

        if (document.getElementById(panelName) == null && idx > 1) {
            panelName = oElement.id.substring(0, idx - 1) + originalPanelName;
        }
    }

    var thePanel = document.getElementById(panelName);

    if (thePanel == null) {
        alert("The panel named '" + originalPanelName + "' cannot be found. It was probably deleted earlier.");

        return;
    }

    window.focus();

    /* Bug 91262 - rolled back James' disabling of Actions/Filters popup ("disabled" property only applicable in IE, not in Firefox/Chrome/Safari). This functionality was thought to be needed for Buckaroo�s sign up edit button disabling (if checkbox unchecked), but after discussion between Alan, Sanuja, and Kirill, they decided functionality not needed.
    if (!(oElement.disabled == false)) {
        return;
    }
    */

    if (thePanel.style.visibility != "visible") {
        if (ISD_OpenFilterOrLanguagePanelElement != null) {
            ISD_OpenFilterOrLanguagePanelElement.style.visibility = "hidden";
        }

        ISD_OpenFilterOrLanguagePanelElement = thePanel;
        ISD_OpenFilterOrLanguageButtonElement = oElement;

        var size1 = ISD_GetPosition(ISD_OpenFilterOrLanguagePanelElement, "offsetWidth");

        thePanel.style.visibility = "hidden";
        if (typeof (thePanel.theWidth) == "undefined") {
            thePanel.theWidth = thePanel.offsetWidth - 95;
        }

        var size2 = ISD_GetPosition(ISD_OpenFilterOrLanguagePanelElement, "offsetWidth");

        ISD_OpenFilterOrLanguagePanelWidth = size2 - size1;

        thePanel.style.visibility = "visible";

        ISD_HandlePopupResize();
    } else {
        ISD_OpenFilterOrLanguagePanelElement = thePanel;
        ISD_OpenFilterOrLanguageButtonElement = oElement;
        ISD_HidePopupPanel();
    }
}



function ISD_HandlePopupUnload() {
    ISD_OpenFilterOrLanguagePanelElement = null;
    ISD_OpenFilterOrLanguageButtonElement = null;
}


window.onunload = ISD_HandlePopupUnload;
window.onresize = ISD_HandlePopupResize;








/**************************************************************************************
*  Function    : SubmitHRefOnce(objElement, msg)                                     *
*  Description : This function should be used for the onclick HTML attribute for a   *
*                'a href' to ensure that the button cannot be clicked                *
*                twice.  It changes the href URL to an alert instead of the previous *
*                href.  This href will then be reset on the postback, and the button *
*                will also be enabled by the postback.  Note that this only works    *
*                for an 'a href' at this time (ThemeButtons included).  It is not    *
*                tested for any of the other buttons such as ImageButton, LinkButton *
*                or others.                                                          *
*  Parameters  : objElement: the button.  Typically it is 'this'                     *
*                msg: The message to report when the user clicks on the button again *
**************************************************************************************/
function SubmitHRefOnce(objElement, msg) {
    var ClientValidate = MyPage_ClientValidate();
    if (ClientValidate) {
        submitcount += 1;
    }
    else {
        submitcount = 0;
        return true;
    }
    var strTagName = objElement.tagName;
    if (strTagName != null) {
        strTagName = strTagName.toLowerCase();
    }
    else {
        submitcount = 0;
        return true;
    }
    switch (strTagName) {
        case "a":
            if (submitcount > 1) {
                if (msg != "") {
                    objElement.href = 'javascript:alert("' + msg + '");';
                }
                submitcount += 1;
                return false;
            }

        case "input":
            if (submitcount > 1) {
                if (msg != "") {
                    alert(msg);
                }
                submitcount += 1;
                return false;
            }
    }
    return true;
}

function SubmitHRefOnceForMTM(objElement, msg) {
    submitcount += 1;
    var strTagName = objElement.tagName;
    if (strTagName != null) {
        strTagName = strTagName.toLowerCase();
    }
    else {
        submitcount = 0;
        return true;
    }
    switch (strTagName) {
        case "a":
            if (submitcount > 1) {
                objElement.href = 'javascript:alert("' + msg + '");';
                submitcount += 1;
                return false;
            }

        case "input":
            if (submitcount > 1) {
                alert(msg);
                submitcount += 1;
                return false;
            }
    }
    return true;
}

function MyPage_ClientValidate(validationGroup) {
    Page_InvalidControlToBeFocused = null;
    if (typeof (Page_Validators) == "undefined") {
        return true;
    }
    var i;
    for (i = 0; i < Page_Validators.length; i++) {
        ValidatorValidate(Page_Validators[i], validationGroup, null);
    }
    ValidatorUpdateIsValid();
    //ValidationSummaryOnSubmit(validationGroup);
    Page_BlockSubmit = !Page_IsValid;
    return Page_IsValid;
}

var gSetFocusOnFCKEditor = false;

function IsVisible(objElement) {
    try {
        while (objElement != null) {
            if (typeof (objElement.className) != "undefined" && objElement.className == "popupWrapper") {
                return false;
            }
            if (typeof (objElement.style) != "undefined" && typeof (objElement.style.visibility) != "undefined" && objElement.style.visibility == "hidden") {
                return false;
            }
            objElement = objElement.parentElement;
        }
    } catch (e) {
    }

    return true;
}



/*
* Sets the focus on the first element that should "reasonably" receive it
*/
function Fev_FocusOnDefaultElement_FromSetFocus(objForm) {
    if (objForm && (objForm != null) && (objForm.length > 0)) {
        for (i = 0; i < objForm.length; i++) {
            var objElement = objForm.elements[i];

            // if FCKEditor appears before the control upon which focus would normally be set...
            // (note that all FCKEditors have an <input> component with id, "...___Config",
            // so that is used as the identifier)
            if (objElement.id.indexOf("___Config") != -1) {
                continue;
                // if you wish to include FCKEditor in the controls where focus could be set by default,
                // uncomment next two lines of code which indicate that focus is to be set
                // (later by FCKeditor_OnComplete()) on the FCKEditor: 

                // gSetFocusOnFCKEditor = true;
                // return true;
            }

            // if you wish to include Header controls in the list of focusable controls comment out this check
            if (!IsElementInContent(objElement)) continue;

            if (Fev_IsFocusableElement(objElement)) {
                var strType = Fev_GetElementType(objElement);

                if (objElement.className.indexOf("Pagination_Input") == 0) {
                    continue;
                }

                if (objElement.className.indexOf("Search_Input") == 0 &&
		     objElement.outerHTML.indexOf("Search_InputHint") > 0) {
                    continue;
                }

                if (!IsVisible(objElement)) {
                    continue;
                }

                //we know (strType != null) because it was checked within Fev_IsFocusableElement().
                //NOTE: SELECT tags interfere with mousewheel scrolling when they have focus
                // NOTE: if you want to ignore 'select' tags (dropdown list for example) you have to uncomment
                // the following code:
                //                if (strType.toLowerCase().indexOf("select") == 0)
                //                {
                //                   
                //                }
                //                else
                //                {
                // if object and all it's parents are visible...
                if (Fev_IsElementVisible(objElement)) {
                    // if the FCKEditor does not appear before the control upon which focus would normally be set...
                    if (gSetFocusOnFCKEditor == false) {
                        // sam - Bug 84611 - don't set focus here (focus will be set by Kirill's FixFocus.js code); just return id of focusable control
                        // just set focus on the "normal" control
                        // objElement.focus();
                        // return true;
                        return objElement.id;
                    }
                    // } closing tag for ignore 'select' tag
                }
            }
        }
    }
    return false;
}

/*
* returns true if the element can receive focus
*/
function Fev_IsFocusableElement(objElement) {
    if (objElement &&
        (objElement != null) &&
        Fev_IsElementEnabled(objElement) &&
        Fev_IsElementVisible(objElement) &&
        Fev_IsElementEditable(objElement)) {
        var strType = Fev_GetElementType(objElement);
        if (strType != null) {
            if ((strType == "text") || (strType == "textarea") || (strType.toLowerCase().indexOf("select") == 0) || (strType.toString().charAt(0) == "s")) {
                return true;
            }
        }
    }
    return false;
}



/*
* returns true if the element is enabled
*/
function Fev_IsElementEnabled(objElement) {
    if (objElement && (objElement != null)) {
        if (!(objElement.disabled == false)) {
            return false;
        }
        return true;
    }
    return false;
}

/*
* returns true if the element's content is editable by the user
*/
function Fev_IsElementEditable(objElement) {
    if (objElement && (objElement != null)) {
        if (objElement.readOnly) {
            return false;
        }
        var strType = Fev_GetElementType(objElement);
        if (strType == null) {
            strType = "";
        }
        if (!objElement.isContentEditable &&
        ((strType.toLowerCase().indexOf("select") != 0) && (IE || (strType.toLowerCase().indexOf("text") != 0))) &&
        (typeof (objElement.isContentEditable) != 'undefined')) {
            return false;
        }
        return true;
    }
    return false;
}

/*
* returns true if the element is visible to the user
*/
function Fev_IsElementVisible(objElement) {
    if (objElement && (objElement != null)) {
        if (objElement.style && (objElement.style != null)) {
            if (objElement.style.display && (objElement.style.display.toLowerCase() == 'none')) {
                return false;
            }
            if (objElement.style.visibility && (objElement.style.visibility.toLowerCase() == 'hidden')) {
                return false;
            }
            /*
            if (objElement.style.visibility && (objElement.style.visibility.toLowerCase() == 'inherit'))
            {
            var objParentElement = Fev_GetParentElement(objElement);
            if (objParentElement && (objParentElement != null) && (!Fev_IsElementVisible(objParentElement)))
            {
            return false;
            }
            }
            */
        }

        var objParentElement = Fev_GetParentElement(objElement);
        if (objParentElement && (objParentElement != null)) {
            return Fev_IsElementVisible(objParentElement);
        }
        else {
            return true;
        }
    }
    return false;
}

/*
* returns true if the element responds directly to Enter key presses
* return true for:
*     Textarea, Select/Dropdown, Input Buttons (Submit/Button/Image/Reset),
*     A tags
* return false for everything else, including:
*     Input type=[Radio/Checkbox/Text/Password/File]
*     IMG tags
*/
function Fev_IsElementUsesEnterKey(objElement) {
    if (objElement && (objElement != null)) {
        var strType = Fev_GetElementType(objElement);
        if (strType != null) strType = strType.toLowerCase();
        switch (strType) {
            case "textarea":
            case "select":
            case "submit":
            case "button":
            case "image":
            case "reset":
                return true;
                break;
            case "radio":
            case "checkbox":
            case "text":
            case "password":
            case "file":
            case "select-multiple":
            case "select-single":
            case "select-one":
                return false;
                break;
            default:
                break;
        }

        var strTagName = Fev_GetElementTagName(objElement);
        if (strTagName != null) strTagName = strTagName.toLowerCase();
        switch (strTagName) {
            case "textarea":
            case "select":
            case "a":
                return true;
                break;
            case "img":
            case "input":
            default:
                break;
        }
    }
    return false;
}

function Fev_GetParentElement(objElement) {
    if (objElement && (objElement != null)) {
        if (objElement.parentNode && (objElement.parentNode != null)) {
            return objElement.parentNode;
        }
        if (objElement.parentElement && (objElement.parentElement != null)) {
            return objElement.parentElement;
        }
    }
    return null;
}

function Fev_GetElementType(objElement) {
    if (objElement && (objElement != null)) {
        if (objElement.type) {
            return objElement.type;
        }
    }
    return null;
}

function Fev_GetElementTagName(objElement) {
    if (objElement && (objElement != null)) {
        if (objElement.tagName) {
            return objElement.tagName;
        }
    }
    return null;
}

function Fev_GetEventSourceElement(objEvent) {
    if (objEvent && (objEvent != null)) {
        // if IE...
        if (objEvent.srcElement) {
            return objEvent.srcElement;
        }
        // if Firefox...
        else if (objEvent.target) {
            return objEvent.target;
        }
    }
    return null;
}

function Fev_IsFormSubmitKeyPress(event) {
    // for IE...
    if (window.event) {
        var e = window.event;
        var bIsEnterKeyPress = ((e.keyCode == 13) && (e.type == 'keypress'));
        if (bIsEnterKeyPress) {
            var eventSrc = Fev_GetEventSourceElement(e);

            if (!Fev_IsElementUsesEnterKey(eventSrc)) {
                return true;
            }
        }
    }
    // for Netscape/Firefox
    else if (event.which) {
        var bIsEnterKeyPress = (event.which == 13);
        if (bIsEnterKeyPress) {
            var eventSrc = Fev_GetEventSourceElement(event);
            if (!Fev_IsElementUsesEnterKey(eventSrc)) {
                return true;
            }
        }
    }

    return false;
}



/**************************************************************************************
*  Function    : clickLinkButtonText()                                               *
*  Description : onclick event handler for HTML table/row shell surrounding button   *
*                    text link.  Locates the anchor in the center table cell and     *
*                    invokes Fev_ClickButton (passing it the anchor's button id) to  *
*                    simulate a physical clicking of the button text link.           *
*  Parameters  : pButtonTableOrRowNode, html table/row shell receiving the onclick   *
*                    event, and which surrounds the button text link to be clicked   *
*                event, browser-generated onclick event object                       *
*  Assumptions : Only "button" and "menu item" HTML table/row shells will call this  *
*                    function.                                                       *
*  ISD Feature : "Button/Menu Item Image Edges Clickable"                            *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function clickLinkButtonText(pButtonTableOrRowNode, event) {
    // make sure to cancel bubbling of clicks.
    if (!event) return;
    event.cancelBubble = true;
    if (event.stopPropagation) event.stopPropagation();

    // also check to make sure the target was not the inner area.   
    // target is used by Firefox, srcElement is used by IE
    if (event.target && event.target.toString().toLowerCase().indexOf("dopostback") > -1) return;
    if (event.srcElement && event.srcElement.toString().toLowerCase().indexOf("dopostback") > -1) return;

    var lAnchorNodeArray = pButtonTableOrRowNode.getElementsByTagName("a");

    // if "button", "horizontal menu item", "vertical menu item middle row" clicked...
    if ((lAnchorNodeArray != null) && (lAnchorNodeArray.length == 1)) {
        Fev_ClickButton(lAnchorNodeArray.item(0).id, event);
    }
    else // if "vertical menu item upper/lower row" clicked...
    {
        var lParentTableNode = pButtonTableOrRowNode.parentNode;
        var lChildrenNodeArray = lParentTableNode.getElementsByTagName("tr");
        // alert("clickLinkButtonText(lChildrenNodeArray.length=" + lChildrenNodeArray.length + ")");

        if (lChildrenNodeArray != null) {
            var lClickedRowFound = false;
            var lCurrentRowItemNumber = 1; // ignore vertical menu edge top row

            // locate the clicked row (this will either be one row above or below
            //     the row containing the vertical menu item to be clicked); terminate search
            //     before vertical menu edge bottom row
            while ((lClickedRowFound == false) && (lCurrentRowItemNumber < lChildrenNodeArray.length - 1)) {
                if (lChildrenNodeArray.item(lCurrentRowItemNumber) != pButtonTableOrRowNode) {
                    lCurrentRowItemNumber++;
                }
                else {
                    // alert("clickLinkButtonText(lCurrentRowItemNumber=" + lCurrentRowItemNumber + ")");
                    lClickedRowFound = true;
                }
            }

            if (lClickedRowFound == true) {
                // if row above first vertical menu item was clicked...
                if (lCurrentRowItemNumber == 1) {
                    // vertical menu item to be clicked must be below clicked row
                    lAnchorNodeArray = lChildrenNodeArray.item(lCurrentRowItemNumber + 1).getElementsByTagName("a");
                    // if row above vertical menu item was clicked...
                    if ((lAnchorNodeArray != null) && (lAnchorNodeArray.length == 1)) {
                        Fev_ClickButton(lAnchorNodeArray.item(0).id, event);
                    }
                }
                // if row below last vertical menu item was clicked...
                else if (lCurrentRowItemNumber == (lChildrenNodeArray.length - 2)) {
                    // vertical menu item to be clicked must be above clicked row
                    lAnchorNodeArray = lChildrenNodeArray.item(lCurrentRowItemNumber - 1).getElementsByTagName("a");
                    ((lAnchorNodeArray != null) && (lAnchorNodeArray.length == 1))
                    {
                        Fev_ClickButton(lAnchorNodeArray.item(0).id, event);
                    }
                }
                // if row of any other vertical menu item was clicked...
                else {
                    lAnchorNodeArray = lChildrenNodeArray.item(lCurrentRowItemNumber + 1).getElementsByTagName("a");
                    // if row above vertical menu item was clicked...
                    if ((lAnchorNodeArray != null) && (lAnchorNodeArray.length == 1)) {
                        Fev_ClickButton(lAnchorNodeArray.item(0).id, event);
                    }
                    // if row below vertical menu item was clicked...
                    else {
                        lAnchorNodeArray = lChildrenNodeArray.item(lCurrentRowItemNumber - 1).getElementsByTagName("a");
                        ((lAnchorNodeArray != null) && (lAnchorNodeArray.length == 1))
                        {
                            Fev_ClickButton(lAnchorNodeArray.item(0).id, event);
                        }
                    }
                }
            }
        }
    }
}


function Fev_ClickButton(buttonId, event) {
    // make sure to cancel bubbling of clicks.
    if (!event) return;
    event.cancelBubble = true;
    if (event.stopPropagation) event.stopPropagation();

    var buttonIdWithUnderscores = buttonId;

    var button = document.getElementById(buttonId);

    // If button is null, then try replacing $ with _ and look again.
    if (button == null) {
        while (buttonIdWithUnderscores.indexOf("$") != -1) {
            buttonIdWithUnderscores = buttonIdWithUnderscores.replace("$", "_");
        }

        button = document.getElementById(buttonIdWithUnderscores);
    }

    // Still nothing?  Try appending _Button
    if (button == null) {
        button = document.getElementById(buttonIdWithUnderscores + '_Button');
    }

    // Still nothing?  Try appending __Button
    if (button == null) {
        button = document.getElementById(buttonIdWithUnderscores + '__Button');
    }

    if (button) {
        var nav = navigator.appName;
        if (nav.toUpperCase().indexOf(('Microsoft').toUpperCase()) >= 0) {
            button.click();
        }
        else {
            /* for enter key capture on buttons without href's... */
            if ((event.keyCode == 13) && (!button.href)) {
                var l_newEvent = document.createEvent("MouseEvents");
                l_newEvent.initEvent("click", true, true);
                button.dispatchEvent(l_newEvent);
            }
            else {
                var anHRef;
                // retrieve the entire href, stripping out (if any) the preceding "javascript:" string
                if (button.href.toLowerCase().indexOf("javascript:") >= 0) {
                    anHRef = button.href.substring("javascript:".length, button.href.length);
                }
                else {
                    anHRef = button.href;
                }

                // convert all HTML-encoded quotes into true quotes
                anHRef = anHRef.replace("&quot;", '"');

                // convert all HTML-encoded spaces into true-spaces
                anHRef = anHRef.replace(/%20/g, ' ');

                // call the javascript built-in function to execute the href string (in effect, this is analogous
                //     to IE's button.click(), but without having to do the complicated parsing of the href string
                //     to decide between regular "doPostBack"s and "doPostBackWithOptions"s)
                eval(anHRef);
            }
        }

        return true;
        // }
    }
    return false;
}

//Sets the value or selection of the form element, independent of the element's type.
function Fev_SetFormControlValue(objElement, strValue) {
    var strTagName = Fev_GetElementTagName(objElement);
    if (strTagName != null) strTagName = strTagName.toLowerCase();
    switch (strTagName) {
        case "textarea":
            objElement.value = strValue;
            return true;
            break;
        case "select":
            var currentIndex = objElement.selectedIndex;
            objElement.value = strValue;
            if (objElement.selectedIndex < 0) {
                objElement.selectedIndex = currentIndex;
                return false;
            }
            return true;
            break;
        case "input":
            switch (objElement.type.toLowerCase()) {
                case "text":
                case "password":
                case "hidden":
                    objElement.value = strValue;
                    return true;
                    break;
                case "file":
                    //can't programatically set the value of file controls
                    return false;
                case "checkbox":
                    if ((strValue == null) || (strValue == '')) {
                        objElement.checked = false;
                        return true;
                        break;
                    }
                    else if (strValue == objElement.value) {
                        objElement.checked = true;
                        return true;
                        break;
                    }
                    else {
                        //the specified value matches niether the checked nor unchecked state
                        //objElement.checked = true;
                        //objElement.value = strValue;
                        //return true;
                        break;
                    }
                case "radio":
                    if (strValue == null) {
                        //uncheck all radio buttons in the group
                        objElement.checked = true;
                        objElement.checked = false;
                        return true;
                        break;
                    }
                    else if (strValue == objElement.value) {
                        objElement.checked = true;
                        return true;
                        break;
                    }
                    else {
                        var f = objElement.form;
                        var allRadioButtonsInGroup = f.elements(objElement.name)
                        for (i = 0; i < allRadioButtonsInGroup.length; i++) {
                            var rb = allRadioButtonsInGroup[i];
                            if (strValue == rb.value) {
                                rb.checked = true;
                                return true;
                            }
                        }
                        //the specified value matches the checked state of none of the radio buttons
                        //objElement.checked = true;
                        //objElement.checked = false;
                        //return true;
                        break;
                    }
                default:
                    break;
            }
        default:
            break;
    }
    return false;
}

//Inserts the value into a list element, independent of the element's type.
function Fev_ReplaceLastListControlOption(objListElement, strValue, strText) {
    var strTagName = Fev_GetElementTagName(objListElement);
    if (strTagName != null) strTagName = strTagName.toLowerCase();
    switch (strTagName) {
        case "select":
            var objOption = objListElement.options[objListElement.options.length - 1];
            objOption.value = strValue;
            objOption.text = strText;
            //objOption.innerText = strText;
            return true;
            break;
        default:
            break;
    }
    return false;
}

function Fev_HandleFormSubmitKeyPress(buttonId, event) {
    if (Fev_IsFormSubmitKeyPress(event)) {
        if (Fev_ClickButton(buttonId, event)) {
            return true;
        }
    }
    return false;
}


/**************************************************************************************
*  Function    : toggleRegions()                                                     *
*  Description : Cycles between "hiding filter", "hiding filters and pagination",    *
*                    "hiding all" (including table data), and "showing all" regions. *
*  Parameters  : aRegionName, html id of the region to be collapsed                  *
*  ISD Feature : "Show/Hide Filter/Pagination"                                       *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function toggleRegions(aAnchorNode) {
    var lToggleRegionIconNode = aAnchorNode.childNodes.item(0);

    if (lToggleRegionIconNode.id == "ToggleRegionIcon") {
        if (lToggleRegionIconNode.src.indexOf("ToggleHideFilters") != -1) {
            lToggleRegionIconNode.src = lToggleRegionIconNode.src.replace("ToggleHideFilters", "ToggleHidePagination");
            // lToggleRegionIconNode.alt = "Hide Pagination";

            var lFilterRegionNode = getRegion(aAnchorNode, "FilterRegion");
            if (lFilterRegionNode != null) {
                lFilterRegionNode.style.display = "none";
            }
            var lCategoryRegionNode = getRegion(aAnchorNode, "CategoryRegion");
            if (lCategoryRegionNode != null) {
                lCategoryRegionNode.style.display = "none";
            }
        }
        else if (lToggleRegionIconNode.src.indexOf("ToggleHidePagination") != -1) {
            lToggleRegionIconNode.src = lToggleRegionIconNode.src.replace("ToggleHidePagination", "ToggleHideAll");
            // lToggleRegionIconNode.alt = "Hide All";

            var lPaginationRegionNode = getRegion(aAnchorNode, "PaginationRegion");
            var lTotalRecordsRegionNode = getRegion(aAnchorNode, "CollapsibleRegionTotalRecords");
            if ((lPaginationRegionNode != null) && (lTotalRecordsRegionNode != null)) {
                lPaginationRegionNode.style.display = "none";
                lTotalRecordsRegionNode.style.display = "";
            }
        }
        else if (lToggleRegionIconNode.src.indexOf("ToggleHideAll") != -1) {
            lToggleRegionIconNode.src = lToggleRegionIconNode.src.replace("ToggleHideAll", "ToggleShowAll");
            // lToggleRegionIconNode.alt = "Show All";

            var lCollapsibleRegionNode = getRegion(aAnchorNode, "CollapsibleRegion");
            if (lCollapsibleRegionNode != null) {
                lCollapsibleRegionNode.style.display = "none";
            }
        }
        else if (lToggleRegionIconNode.src.indexOf("ToggleShowAll") != -1) {
            lToggleRegionIconNode.src = lToggleRegionIconNode.src.replace("ToggleShowAll", "ToggleHideFilters");
            // lToggleRegionIconNode.alt = "Hide Filters";

            var lCollapsibleRegionNode = getRegion(aAnchorNode, "CollapsibleRegion");
            if (lCollapsibleRegionNode != null) {
                lCollapsibleRegionNode.style.display = "";
            }
            var lFilterRegionNode = getRegion(aAnchorNode, "FilterRegion");
            if (lFilterRegionNode != null) {
                lFilterRegionNode.style.display = "";
            }
            var lCategoryRegionNode = getRegion(aAnchorNode, "CategoryRegion");
            if (lCategoryRegionNode != null) {
                lCategoryRegionNode.style.display = "";
            }
            var lPaginationRegionNode = getRegion(aAnchorNode, "PaginationRegion");
            if (lPaginationRegionNode != null) {
                lPaginationRegionNode.style.display = "";
            }
            var lTotalRecordsRegionNode = getRegion(aAnchorNode, "CollapsibleRegionTotalRecords");
            if (lTotalRecordsRegionNode != null) {
                lTotalRecordsRegionNode.style.display = "none";
            }
        }

        // reposition any scrolling tables' "fixed header" row
        refreshFixedHeaderRows();
    }
}


/**************************************************************************************
*  Function    : getRegion()                                                         *
*  Description : Retrieves a reference to the specified collapsible region           *
*                   associated with the table containing the specified anchor node.  *
*  Parameters  : aAnchorNode, toggle regions button which has been clicked           *
*                aRegionName, region to be collapsed                                 *
*  ISD Feature : "Show/Hide Filter/Pagination"                                       *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function getRegion(aAnchorNode, aRegionName) {
    var rRegionNode = null;
    var lMainTableNode = aAnchorNode.parentNode.parentNode.parentNode.parentNode.parentNode.parentNode.parentNode.parentNode;
    // alert("getRegion(lMainTableNode.nodeName=" + lMainTableNode.nodeName + ",lMainTableNode.className=" + lMainTableNode.className + ")");
    var lContainedTableNodesArray = lMainTableNode.getElementsByTagName("table");

    // alert("getRegion(lContainedTableNodesArray.length=" + lContainedTableNodesArray.length + ")");
    for (var i = 0; i < lContainedTableNodesArray.length; i++) {
        if (lContainedTableNodesArray[i].id == aRegionName) {
            // alert("getRegion(lContainedTableNodesArray[" + i + "].id=" + lContainedTableNodesArray[i].id + ")");
            rRegionNode = lContainedTableNodesArray[i];
            break;
        }
    }

    // alert("getRegion(rRegionNodeIsNull=" + (rRegionNode == null) + ")");
    return (rRegionNode);
}


/**************************************************************************************
*  Function    : adjustPageSize()                                                    *
*  Description : onkeyup event handler to increment/decrement page size value within *
*                    specified lower and upper bounds.                               *
*  Parameters  : aPageSizeTextboxNode, table cell containing page size textbox       *
*                    which caught the onkeyup event)                                 *
*                event, onkeyup event                                                *
*                aLowerBound, lower bound for the page size value                    *
*                aUpperBound, upper bound for the page size value                    *
*  ISD Feature : "Increment/Decrement Numerical Fields"                              *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function adjustPageSize(aPageSizeTextboxNode, aKeyCode, aLowerBound, aUpperBound) {
    // if (justDoIt == true)
    // {
    // myAlert("adjustPage(event.which=" + event.which + ",event.keyCode=" + event.keyCode + ")");

    if (aPageSizeTextboxNode != null) {
        var lWhichCode = aKeyCode;

        // if up arrow, or plus key...
        if ((lWhichCode == 38) || (lWhichCode == 107)) {
            // strip "+" character if it has been appended to page size value
            while ((lWhichCode == 107) && (aPageSizeTextboxNode.value.charAt(aPageSizeTextboxNode.value.length - 1) == "+")) {
                aPageSizeTextboxNode.value = (aPageSizeTextboxNode.value).substring(0, aPageSizeTextboxNode.value.length - 1);
            }

            // if page size not initialized or contains invalid characters...
            if ((aPageSizeTextboxNode.value == "") || (isNaN(aPageSizeTextboxNode.value))) {
                // set initial value as "1"
                aPageSizeTextboxNode.value = 10;
            }
            else {
                // upper bounds check
                if (aPageSizeTextboxNode.value < aUpperBound) {
                    aPageSizeTextboxNode.value = new Number(aPageSizeTextboxNode.value) + 1;
                }
            }
        }
        // else if down arrow, or minus key...
        else if ((lWhichCode == 40) || (lWhichCode == 109)) {
            // strip "-" character if it has been appended to page size value
            while ((lWhichCode == 109) && (aPageSizeTextboxNode.value.charAt(aPageSizeTextboxNode.value.length - 1) == "-")) {
                aPageSizeTextboxNode.value = (aPageSizeTextboxNode.value).substring(0, aPageSizeTextboxNode.value.length - 1);
            }

            // if page size not initialized or contains invalid characters...
            if ((aPageSizeTextboxNode.value == "") || (isNaN(aPageSizeTextboxNode.value))) {
                // set initial value as "1"
                aPageSizeTextboxNode.value = 10;
            }
            else {
                // lower bounds check
                if (aPageSizeTextboxNode.value > aLowerBound) {
                    aPageSizeTextboxNode.value = new Number(aPageSizeTextboxNode.value) - 1;
                }
            }
        }
    }
    // }
}


/**************************************************************************************
*  Function    : adjustCurrency()                                                    *
*  Description : onkeyup event handler to increment/decrement currency.              *
*  Parameters  : aInputTextbox, html textbox containing the currency value to be     *
*                    incremented/decremented                                         *
*                aCurrencySymbol, the currency symbol which prepended to the         *
*                    actual currency value                                           *
*                aCurrencyDecimalSeparator, the symbol which divides the "whole"     *
*                    portion of the currency from the "fractional" part              *
*				  aIsCurrencySeparatorAtEnd, boolean indicating whether currency      *
*                    symbol trails or precedes currency value                        *
*  ISD Feature : "Increment/Decrement Numerical Fields"                              *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function adjustCurrency(aInputTextbox, aKeyCode, aCurrencySymbol, aCurrencyDecimalSeparator, aIsCurrencySeparatorAtEnd) {
    // if (justDoIt == true)
    // {
    // var lWhichCode = event.keyCode;
    var lWhichCode = aKeyCode;

    // if up arrow, or plus key...
    if ((lWhichCode == 38) || (lWhichCode == 107) || (lWhichCode == 40) || (lWhichCode == 109)) {
        if ((aCurrencySymbol != "") && (aCurrencyDecimalSeparator != "")) {
            // strip "+" character if it has been appended to currency value
            while ((lWhichCode == 107) && (aInputTextbox.value.charAt(aInputTextbox.value.length - 1) == "+")) {
                aInputTextbox.value = (aInputTextbox.value).substring(0, aInputTextbox.value.length - 1);
            }

            // strip "-" character if it has been appended to currency value
            while ((lWhichCode == 109) && (aInputTextbox.value.charAt(aInputTextbox.value.length - 1) == "-")) {
                aInputTextbox.value = (aInputTextbox.value).substring(0, aInputTextbox.value.length - 1);
            }

            // if currency value not initialized...
            if (aInputTextbox.value == "") {
                if (aIsCurrencySeparatorAtEnd.indexOf("False") != -1) {
                    // set initial value (with leading currency symbol)
                    aInputTextbox.value = aCurrencySymbol + "1" + aCurrencyDecimalSeparator + "00";
                }
                else {
                    // set initial value (with trailing currency symbol)
                    aInputTextbox.value = "1" + aCurrencyDecimalSeparator + "00" + aCurrencySymbol;
                }
            }
            else {
                if ((aInputTextbox.value).indexOf(aCurrencyDecimalSeparator) == -1) {
                    aInputTextbox.value = aInputTextbox.value + aCurrencyDecimalSeparator + "00";
                }

                var lCurrencyArray = (aInputTextbox.value).replace(aCurrencySymbol, "").split(aCurrencyDecimalSeparator);

                var lCurrencyWhole = null;
                var lParenthesesRepresentationOfNegativeValue = false;
                // account for "parentheses" representation of negative value
                if ((aInputTextbox.value.indexOf("(") == 0) && (aInputTextbox.value.indexOf(")") == aInputTextbox.value.length - 1)) {
                    lParenthesesRepresentationOfNegativeValue = true;
                    lCurrencyArray[0] = "-" + lCurrencyArray[0];
                }

                if ((lWhichCode == 38) || (lWhichCode == 107)) {
                    lCurrencyWhole = new Number(lCurrencyArray[0].replace(/[^0-9,-]/g, "")) + 1;
                }
                // ((lWhichCode == 40) || (lWhichCode == 109))
                else {
                    lCurrencyWhole = new Number(lCurrencyArray[0].replace(/[^0-9,-]/g, "")) - 1;
                }

                lCurrencyArray[1] = lCurrencyArray[1].replace(/[^0-9]/g, "")
                if (lCurrencyArray[1].length == 1) {
                    lCurrencyArray[1] = lCurrencyArray[1] + "0";
                }

                var lCurrencyFraction = new Number(lCurrencyArray[1]);

                if ((lCurrencyFraction < 10) && (lCurrencyFraction >= 0)) {
                    lCurrencyFraction = "0" + lCurrencyFraction;
                }

                if (lCurrencyWhole >= 0) {
                    if (aIsCurrencySeparatorAtEnd.indexOf("False") != -1) {
                        aInputTextbox.value = aCurrencySymbol + lCurrencyWhole + aCurrencyDecimalSeparator + lCurrencyFraction;
                    }
                    else {
                        aInputTextbox.value = lCurrencyWhole + aCurrencyDecimalSeparator + lCurrencyFraction + aCurrencySymbol;
                    }
                }
                else {
                    if (aIsCurrencySeparatorAtEnd.indexOf("False") != -1) {
                        if (lParenthesesRepresentationOfNegativeValue == false) {
                            aInputTextbox.value = "-" + aCurrencySymbol + Math.abs(lCurrencyWhole) + aCurrencyDecimalSeparator + lCurrencyFraction;
                        }
                        else {
                            aInputTextbox.value = "(" + aCurrencySymbol + Math.abs(lCurrencyWhole) + aCurrencyDecimalSeparator + lCurrencyFraction + ")";
                        }
                    }
                    else {
                        if (lParenthesesRepresentationOfNegativeValue == false) {
                            aInputTextbox.value = "-" + Math.abs(lCurrencyWhole) + aCurrencyDecimalSeparator + lCurrencyFraction + aCurrencySymbol;
                        }
                        else {
                            aInputTextbox.value = "(" + Math.abs(lCurrencyWhole) + aCurrencyDecimalSeparator + lCurrencyFraction + aCurrencySymbol + ")";
                        }
                    }
                }
            }
        }
    }
    // }
}



/**************************************************************************************
*  Function    : adjustInteger()                                                     *
*  Description : onkeyup event handler to increment/decrement integer fields.        *
*  Parameters  : aInputTextbox, html textbox containing the integer value to be      *
*                    incremented/decremented                                         *
*  ISD Feature : "Increment/Decrement Numerical Fields"                              *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function adjustInteger(aInputTextbox, aKeyCode) {
    // if (justDoIt == true)
    // {
    // var lWhichCode = event.keyCode;
    var lWhichCode = aKeyCode;
    var lIsPercentage = false;

    // if up arrow, or plus key...
    if ((lWhichCode == 38) || (lWhichCode == 107)) {
        if (aInputTextbox.value.charAt(aInputTextbox.value.length - 1) == "%") {
            // strip "%"
            aInputTextbox.value = (aInputTextbox.value).replace(/%/g, "");
            lIsPercentage = true;
        }

        // strip "+" character if it has been appended to integer value
        while ((lWhichCode == 107) && (aInputTextbox.value.charAt(aInputTextbox.value.length - 1) == "+")) {
            aInputTextbox.value = (aInputTextbox.value).substring(0, aInputTextbox.value.length - 1);
        }

        // if currency value not initialized or contains invalid characters...
        if ((aInputTextbox.value == "") || (isNaN(aInputTextbox.value))) {
            // set initial value
            aInputTextbox.value = "1";
        }
        else {
            // myAlert("adjustInteger(aInputTextbox.value=" + aInputTextbox.value + ")");
            aInputTextbox.value = new Number(aInputTextbox.value) + 1;
        }

        if (lIsPercentage) {
            // post-pend "%" since originally present
            aInputTextbox.value += " %";
        }

    }
    // if down arrow, or minus key...
    else if ((lWhichCode == 40) || (lWhichCode == 109)) {
        if (aInputTextbox.value.charAt(aInputTextbox.value.length - 1) == "%") {
            // strip "%"
            aInputTextbox.value = (aInputTextbox.value).replace(/%/g, "");
            lIsPercentage = true;
        }

        // strip "-" character if it has been appended to integer value
        while ((lWhichCode == 109) && (aInputTextbox.value.charAt(aInputTextbox.value.length - 1) == "-")) {
            aInputTextbox.value = (aInputTextbox.value).substring(0, aInputTextbox.value.length - 1);
        }

        // if currency value not initialized or contains invalid characters...
        if ((aInputTextbox.value == "") || (isNaN(aInputTextbox.value))) {
            // set initial value
            aInputTextbox.value = "1";
        }
        else {
            // myAlert("adjustInteger(aInputTextbox.value=" + aInputTextbox.value + ")");
            aInputTextbox.value = new Number(aInputTextbox.value) - 1;
        }

        if (lIsPercentage) {
            // post-pend "%" since originally present
            aInputTextbox.value += " %";
        }

    }
    // }
}

/**************************************************************************************
*  Function    : createNewDate()                                                     *
*  Description : Create and return a new date object based on the value in the       *
*                    specified textbox and the current date pattern.                 *
*  Parameters  : aInputTextbox, textbox containing the current date to be            *
*                    incremented/decremented                                         *
*  Assumptions : parseDatePattern() has already been called, so that the format      *
*                    of the date is known.                                           *
*  ISD Feature : "Increment/Decrement Numerical Fields"                              *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function createNewDate(aInputTextbox) {
    // myAlert("createNewDate(aInputTextbox.value=" + aInputTextbox.value + ")");

    var rNewDate = new Date();
    var lDateStringArray;

    if (gDateSeparator1 == gDateSeparator2) {
        lDateStringArray = (aInputTextbox.value).split(gDateSeparator1);
    }
    else // (gDateSeparator1 != gDateSeparator2)
    {
        var lTempArray1 = (aInputTextbox.value).split(gDateSeparator1);
        var lDatePortion1 = lTempArray1[0];
        var lTempArray2 = lTempArray1[1].split(gDateSeparator2);
        var lDatePortion2 = lTempArray2[0];
        if (lTempArray2.length == 1) {
            lDateStringArray = new Array(lDatePortion1, lDatePortion2);
        }
        else if (lTempArray2.length > 1) {
            lDateStringArray = new Array(lDatePortion1, lDatePortion2, lTempArray2[1]);
        }
    }

    if (gDatePatternArray != null) {
        if ((gDatePatternArray.length == 3) &&
		    (gDatePatternArray[0].charAt(0) == "m") &&
		    (gDatePatternArray[1].charAt(0) == "d") &&
		    (gDatePatternArray[2].charAt(0) == "y")) {
            rNewDate.setTime(Date.parse(aInputTextbox.value));
        }
        else if ((gDatePatternArray.length == 3) &&
		    (gDatePatternArray[0].charAt(0) == "d") &&
		    (gDatePatternArray[1].charAt(0) == "m") &&
		    (gDatePatternArray[2].charAt(0) == "y")) {
            // Date.parse expects date in mm/dd/yyyy format, so swap date and month portions if date pattern is dd/mm/yyyy
            rNewDate.setTime(Date.parse(new String(lDateStringArray[1] + gDateSeparator1 + lDateStringArray[0] + gDateSeparator1 + lDateStringArray[2])));
        }
        else {
            for (var i = 0; i < (gDatePatternArray.length); i++) {
                switch (gDatePatternArray[i].charAt(0)) {
                    case "m":
                        // alert("createNewDate(lDateStringArrayM[" + i + "]=" + lDateStringArray[i] + ")");
                        // alert("createNewDate(lDateStringArrayM[" + i + "]-1=" + lDateStringArray[i]-1 + ")");
                        rNewDate.setMonth(lDateStringArray[i] - 1);
                        break;
                    case "d":
                        // myAlert("createNewDate(lDateStringArrayD[" + i + "]=" + lDateStringArray[i] + ")");
                        rNewDate.setDate(lDateStringArray[i]);
                        break;
                    case "y":
                        // myAlert("createNewDate(lDateStringArrayY[" + i + "]=" + lDateStringArray[i] + ")");
                        // if year string is only two characters long...
                        if (lDateStringArray[i].length == 2) {
                            // prepend default century
                            rNewDate.setYear("20" + lDateStringArray[i]);
                        }
                        else {
                            rNewDate.setYear(lDateStringArray[i]);
                        }
                        break;
                }
            }
        }
    }

    return (rNewDate);
}


/**************************************************************************************
*  Function    : displayDate()                                                       *
*  Description : Display a date in the specified textbox.                            *
*  Parameters  : aInputTextbox, textbox into which to display date                   *
*                aDate, date to be displayed in specified textbox                    *
*  Assumptions : parseDatePattern() has already been called, so that the display     *
*                    format of the date is known.                                    *
*  ISD Feature : "Increment/Decrement Numerical Fields"                              *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function displayDate(aInputTextbox, aDate) {
    aInputTextbox.value = "";

    if (gDatePatternArray != null) {
        for (var i = 0; i < (gDatePatternArray.length); i++) {
            switch (gDatePatternArray[i].charAt(0)) {
                case "m":
                    // month pattern is two characters long, but the current month is
                    //     only a single digit...
                    if ((gDatePatternArray[i].length == 2) && (aDate.getMonth() < 9)) {
                        // prepend a "0" to month string
                        aInputTextbox.value += "0" + new String(aDate.getMonth() + 1);
                    }
                    else {
                        aInputTextbox.value += new String(aDate.getMonth() + 1);
                    }
                    break;
                case "d":
                    aInputTextbox.value += aDate.getDate();
                    break;
                case "y":
                    var lDateYearString = new String(aDate.getFullYear());
                    // if (lDateYearString.length < 4)
                    if (aDate.getFullYear() < 1000) {
                        // correct browser bug which returns "1xx" for the year "20xx"
                        aDate.setFullYear(aDate.getFullYear() + 1900);
                    }
                    aInputTextbox.value += aDate.getFullYear();
                    break;
            }

            // post-pend date separator except for last portion of date
            if (i == 0) {
                aInputTextbox.value += gDateSeparator1;
            }
            else if ((i == 1) && (gDateDayPosition != 0)) {
                aInputTextbox.value += gDateSeparator2;
            }
        }
    }
}


/**************************************************************************************
*  Function    : printPage()                                                         *
*  Description : Invokes the system's print program (to print the current page).     *
*  ISD Feature : "Print Page"                                                        *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function printPage() {
    // if (justDoIt == true)
    // {
    window.print();
    // }
}

/**************************************************************************************
*  Function    : getParentByTagName()                                                *
*  Description : Return the closest parent with a particular tag name                *
*  Parameters  : tag, child tag to be the starting tag to search up                  *
*  Parameters  : tagname, name of the parent tag                                     *
*  Assumptions : The edit button is contained in the first cell of the table row in  *
*                    focus.                                                          *                 
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function getParentByTagName(tag, tagname) {
    var obj_parent = tag.parentNode;
    if (!obj_parent) return null;
    if (obj_parent.tagName.toUpperCase() == tagname.toUpperCase()) return obj_parent;
    else return getParentByTagName(obj_parent, tagname);
}


/**************************************************************************************
*  Function    : RedirectByViewButton()                                              *
*  Description : Invokes the view button server side click event in the selected row *
*                    row) by programmatically clicking the record's edit button.     *
*  Parameters  : e, event object                                                     *
*  Assumptions : The view button is contained in the first cell of the table row in  *
*                    focus.                                                          *                 
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function RedirectByViewButton(e) {
    if (justDoIt == false)
        return;

    var iconCellContents = null;
    var rTableRowClickable = false;

    var clickedElement;
    // Firefox
    if (e.target) {
        clickedElement = e.target;
    }
    // IE or Chrome
    else {
        clickedElement = e.srcElement;
    }
    if (clickedElement.nodeName == "INPUT" ||
        clickedElement.nodeName == "TEXTAREA" ||
        clickedElement.nodeName == "SELECT" ||
        clickedElement.nodeName == "OPTION" ||
        clickedElement.nodeName == "BUTTON" ||
        clickedElement.nodeName == "LINK" ||
        clickedElement.nodeName == "MAP" ||
        clickedElement.nodeName == "A" ||
        clickedElement.nodeName == "HR")
        return;
    var tableRow = getParentByTagName(clickedElement, "TR");

    while (tableRow != null) {
        iconCellContents = tableRow.getElementsByTagName("input");

        for (var i = 0; i < iconCellContents.length; i++) {
            if (iconCellContents[i].id.indexOf("ViewButton") != -1 || iconCellContents[i].id.indexOf("ViewRowButton") != -1) {
                iconCellContents[i].click();
                rTableRowClickable = true;
                return rTableRowClickable;
            }
        }
        tableRow = getParentByTagName(tableRow, "TR")
    }

    return null;

}


/**************************************************************************************
*  Description : Global variables used by the following functions:                   * 
*                    moveToNextTableRow()                                            *
*                    moveToPreviousTableRow()                                        *
*                    moveToThisTableRow()                                            *
*                    updateCurrentTableAndIndex()                                    *
*                    highlightTableRow()                                             *
*                    clickEditButtonOfTableRowInFocus()                              *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
var justDoIt = true;
var currentTable = null;
var currentRow = null;
var currentRowIndex = 0;

/**************************************************************************************
*  Function    : captureUpDownKey()                                                  *
*  Description : Captures an "up/down arrow" and "enter" keyboard event, and calls   *
*                    the respective function to process the event.                   *
*  Parameters  : pTableInFocus, html table receiving the keyboard event              *
*                event, browser-generated event object                               *
*  Assumptions : Only table panels will call this function.                          *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function captureUpDownKey(pTableInFocus, event) {

    // capture current scroll position for "maintain position in tables" feature 
    setCurrentBrowserCoordinates();

    if (justDoIt == true) {
        // if focus is not on a drop-down list, nor the page size entry field (otherwise
        // drop-down list navigation via up/down/enter keypress takes precedence)    
        if ((event.srcElement == null) || ((event.srcElement.nodeName != "SELECT") && ((event.srcElement.id).indexOf("PageSize") == -1))) {

            if (event.keyCode) {

                // if key down...
                if (event.keyCode == 40) {
                    event.returnValue = false;
                    event.cancel = true;
                    event.cancelBubble = true;
                    if (event.stopPropagation) event.stopPropagation();
                    moveToNextTableRow(pTableInFocus);
                }
                // if key up...
                else if (event.keyCode == 38) {
                    event.returnValue = false;
                    event.cancel = true;
                    event.cancelBubble = true;
                    if (event.stopPropagation) event.stopPropagation();
                    moveToPreviousTableRow(pTableInFocus);
                }
                // if enter key...
                else if (event.keyCode == 13) {
                    if (clickEditButtonOfTableRowInFocus() == true) {
                        event.returnValue = false;
                        event.cancel = true;
                        event.cancelBubble = true;
                        if (event.stopPropagation) event.stopPropagation();
                    }
                    // else let event bubble up to "enter key capture" code for the above column filter button
                }
            }
        }
    }
}


/**************************************************************************************
*  Function    : moveToNextTableRow()                                                *
*  Description : Upon "down arrow" keypress, disables "up/down arrow navigation"     *
*                    highlight color on the current table row, and enables same on   *
*                    the next table row.                                             *
*  Parameters  : pTableInFocus, html table receiving the "down arrow" keyboard event *
*  Assumptions : None.                                                               *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function moveToNextTableRow(pTableInFocus) {
    var tableInFocus;
    var tableRows;
    var maxRowIndex;
    var tableCells;

    if (justDoIt == true) {

        if (pTableInFocus != null) {

            // if focus is still within same table...
            if (currentTable == pTableInFocus) {
                // determine the number of rows (including "header row") in this table
                var maxRowIndex = getNumberOfTableRows(pTableInFocus);

                if (maxRowIndex > 0) {
                    if (currentRowIndex >= maxRowIndex - 1) {
                        // wrap highlighting
                        currentRowIndex = 0;
                    }

                    // if current row is not the last row of this table...
                    if ((currentRowIndex >= 0) && (currentRowIndex < maxRowIndex - 1)) {

                        if (tableRowHighlightable(getTableRow(currentRowIndex + 1)) == true) {

                            // unhighlight the current row
                            unhighlightTableRow(currentRow);

                            // make previous row of this table the current row
                            currentRowIndex++;

                            // highlight the (new) current row
                            highlightTableRow(getTableRow(currentRowIndex));
                        }
                    }
                }
            }
            else {
                // make this new table in focus the current table
                currentTable = pTableInFocus;

                moveToNextTableRow(currentTable);
            }
        }
    }
}

/**************************************************************************************
*  Function    : moveToPreviousTableRow()                                            *
*  Description : Upon "up arrow" keypress, disables the "up/down arrow navigation"   *
*                    highlight color on the current table row, and enables same on   *
*                    the previous table row.                                         *
*  Parameters  : pTableInFocus, html table receiving the "down arrow" keyboard event *
*  Assumptions : None.                                                               *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function moveToPreviousTableRow(pTableInFocus) {

    if (justDoIt == true) {
        if (pTableInFocus != null) {
            // if focus is still within same table...
            if (currentTable == pTableInFocus) {
                // determine the number of rows (including "header row") in this table
                var maxRowIndex = getNumberOfTableRows(pTableInFocus);

                if (maxRowIndex > 0) {
                    if (currentRowIndex <= 1) {
                        // wrap highlighting
                        currentRowIndex = maxRowIndex;
                    }

                    // if current row is not the first row of this table...
                    if ((currentRowIndex > 1) && (currentRowIndex <= maxRowIndex)) {
                        if (tableRowHighlightable(getTableRow(currentRowIndex - 1)) == true) {
                            // unhighlight the current row
                            unhighlightTableRow(currentRow);

                            // make previous row of this table the current row
                            currentRowIndex--;

                            // highlight the (new) current row
                            highlightTableRow(getTableRow(currentRowIndex));
                        }
                    }
                }
            }
            else {
                // make this new table in focus the current table
                currentTable = pTableInFocus;

                moveToPreviousTableRow(currentTable);
            }
        }
    }
}

/**************************************************************************************
*  Function    : moveToThisTableRow()                                                *
*  Description : Upon "radio button select", disables the "up/down arrow navigation" *
*                    highlight color on the current table row, and enables same on   *
*                    the newly selected table row.                                   *
*  Parameters  : pTableCell, "radio button" table cell selected                      *
*  Assumptions : Only "radio button" table cells will call this function.            *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function moveToThisTableRow(pTableCell) {
    // capture current scroll position for "maintain position in tables" feature 
    setCurrentBrowserCoordinates();

    if (justDoIt == true) {

        if (pTableCell != null) {

            var tableRow = pTableCell.parentNode;

            if (tableRow.nodeName == "TD") {
                tableRow = tableRow.parentNode;
            }

            if (tableRowHighlightable(tableRow) == true) {

                var iconCellContents = tableRow.getElementsByTagName("input");

                for (var i = (iconCellContents.length - 1); i >= 0; i--) {
                    if (iconCellContents[i].type == "checkbox") {
                        iconCellContents[i].focus();
                        break;
                    }
                }

                // if current row highlighted...
                if (currentTable != null) {
                    unhighlightTableRow(currentRow);
                }

                // determine current table and index resulting from focus change
                updateCurrentTableAndIndex(tableRow);

                // highlight (new) current table row
                highlightTableRow(tableRow);
            }
        }
    }
}


/**************************************************************************************
*  Function    : getTableRow()                                                       *
*  Description : Retrieve the table row specified by pTableRowIndex in the "current" *
*                    table.                                                          *
*  Parameters  : pTableRowIndex, index of table row to retrieve                      *
*  Assumptions : Global "currentTable" points to a valid table.                      *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function getTableRow(pTableRowIndex) {
    var rTableRow = null;

    if (justDoIt == true) {
        if (currentTable != null) {
            var lTableRows = currentTable.getElementsByTagName("tr");
            var lTableRowIndex = 1;

            // if there are enough rows in the current table...
            if (pTableRowIndex < lTableRows.length) {
                // while table row not found...
                for (var i = 1; i < lTableRows.length; i++) {
                    // if table row is part of main table (i.e., not a nested table row)...
                    if (lTableRows[i].parentNode.parentNode == currentTable) {
                        // if this is the specified table row index...
                        if (lTableRowIndex == pTableRowIndex) {
                            // save a reference to this row
                            rTableRow = lTableRows[i];
                            break;
                        }
                        // else move on to the next table row in main table
                        else {
                            lTableRowIndex++;
                        }
                    }
                }
            }
        }
    }

    // alert("getTableRow(rTableIsNull=" + (rTableRow == null) + ",currentRowIndex=" + currentRowIndex + ",pTableRowIndex=" + pTableRowIndex + ")");
    return rTableRow;
}


/**************************************************************************************
*  Function    : getNumberOfTableRows()                                              *
*  Description : Returns the number of table rows in the specified main table.       *
*  Parameters  : pTable, reference to table whose row count is to be returned        *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function getNumberOfTableRows(pTable) {
    var rNumberOfTableRows = 0;

    if (justDoIt == true) {
        if (pTable != null) {
            var lTableRows = pTable.getElementsByTagName("tr");

            for (var i = 0; i < lTableRows.length; i++) {
                // if table row is part of main table (i.e., not a nested table row)...
                if (lTableRows[i].parentNode.parentNode == currentTable) {
                    rNumberOfTableRows++;
                }
            }
        }
    }

    // alert("getNumberOfTableRows(rNumberOfTableRows=" + rNumberOfTableRows + ")");
    return rNumberOfTableRows;
}


/**************************************************************************************
*  Function    : updateCurrentTableAndIndex()                                        *
*  Description : Updates the global variables, currentTable and currentRowIndex,     *
*                    indicating the new table and row in focus.                      *
*  Parameters  : pTableRow, new table row in focus                                   *
*  Assumptions : pTableRow is a row in the current table.                            *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function updateCurrentTableAndIndex(pTableRow) {
    var tableRows;
    var maxTableIndex;

    if (justDoIt == true) {

        // update current table
        currentTable = pTableRow.parentNode;
        currentRowIndex = 0;

        var lTableRows = currentTable.getElementsByTagName("tr");
        var lTableRowIndex = 1;

        for (var i = 1; i < lTableRows.length; i++) {
            // if table row is part of main table (i.e., not a nested table row)...
            if (lTableRows[i].parentNode == currentTable) {
                // if current table row found
                if (lTableRows[i] == pTableRow) {
                    // update current table row index
                    currentRowIndex = lTableRowIndex;
                    break;
                }
                // else move on to the next table row in main table
                else {
                    lTableRowIndex++;
                }
            }
        }

        // alert("updateCurrentTableAndIndex(currentRowIndex=" + currentRowIndex + ")"); 
    }
}

/**************************************************************************************
*  Function    : unhighlightTableRow()                                               *
*  Description : For the specified table row, unchecks the "selection checkbox", and *
*                    disables the "up/down arrow navigation" highlight color on its  *
*                    table cells.                                                    *
*  Parameters  : pTableRow, table row to be unhighlighted                            *
*  Assumptions : None.                                                               *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function unhighlightTableRow(pTableRow) {

    var iconCellContents = null;

    if (justDoIt == true) {

        if (pTableRow != null) {

            // retrieve all "input" items within table row
            iconCellContents = pTableRow.getElementsByTagName("input");

            var lCheckboxPresent = false;
            var lCheckboxChecked = false;
            if (iconCellContents != null) {
                for (var i = 0; i <= (iconCellContents.length - 1); i++) {
                    // if selection checkbox present within table row...
                    if ((iconCellContents[i].type == "checkbox") && (iconCellContents[i].id.indexOf("RecordRowSelection") != -1 || iconCellContents[i].id.indexOf("SelectRow") != -1)) {
                        lCheckboxPresent = true;
                        if (iconCellContents[i].checked == true) {
                            lCheckboxChecked = true;
                        }
                        break;
                    }
                }
            }

            if (lCheckboxPresent) {
                if (lCheckboxChecked) {
                    // unhighlight row
                    tableCells = pTableRow.getElementsByTagName("td");
                    for (var i = 0; i < tableCells.length; i++) {
                        if (tableCells[i].parentNode == pTableRow) {
                            if ((tableCells[i].className == "tic") ||
		                    	(tableCells[i].className == "tich") ||
				                (tableCells[i].className == "icon_cell") ||
		                    	(tableCells[i].className == "icon_cell_highlighted")) {
                                tableCells[i].className = "tics";
                            }
                            else if ((tableCells[i].className == "ticnb") ||
		                    	(tableCells[i].className == "tichnb")) {
                                tableCells[i].className = "ticsnb";
                            }
                            else if ((tableCells[i].className == "ticwb") ||
		                    	(tableCells[i].className == "tichwb")) {
                                tableCells[i].className = "ticswb";
                            }
                            else if ((tableCells[i].className == "tichb") ||
		                    	(tableCells[i].className == "tichhb")) {
                                tableCells[i].className = "ticshb";
                            }
                            else if ((tableCells[i].className == "ttc") ||
		                    	(tableCells[i].className == "ttch") ||
		                        (tableCells[i].className == "table_cell") ||
		                    	(tableCells[i].className == "table_cell_highlighted")) {
                                tableCells[i].className = "ttcs";
                            }
                            else if ((tableCells[i].className == "tice") ||
		                    	(tableCells[i].className == "tiche")) {
                                tableCells[i].className = "ticse";
                            }
                            // alert("unhighlightTableRow(unhighlightingCheckedRow... currentRowIndex=" + currentRowIndex + ")");
                        }
                    }
                }
                else {
                    // unhighlight row
                    tableCells = pTableRow.getElementsByTagName("td");
                    for (var i = 0; i < tableCells.length; i++) {
                        if (tableCells[i].parentNode == pTableRow) {
                            if ((tableCells[i].className == "tics") ||
		                    	(tableCells[i].className == "tich") ||
		                    	(tableCells[i].className == "icon_cell_selected") ||
		                    	(tableCells[i].className == "icon_cell_highlighted")) {
                                tableCells[i].className = "tic";
                            }
                            else if ((tableCells[i].className == "ticsnb") ||
		                    	(tableCells[i].className == "tichnb")) {
                                tableCells[i].className = "ticnb";
                            }
                            else if ((tableCells[i].className == "ticswb") ||
		                    	(tableCells[i].className == "tichwb")) {
                                tableCells[i].className = "ticwb";
                            }
                            else if ((tableCells[i].className == "ticshb") ||
		                    	(tableCells[i].className == "tichhb")) {
                                tableCells[i].className = "tichb";
                            }
                            else if ((tableCells[i].className == "ttcs") ||
		                    		 (tableCells[i].className == "ttch") ||
		                    		 (tableCells[i].className == "table_cell_selected") ||
		                    		 (tableCells[i].className == "table_cell_highlighted")) {
                                tableCells[i].className = "ttc";
                            }
                            else if ((tableCells[i].className == "ticse") ||
		                    		 (tableCells[i].className == "tiche")) {
                                tableCells[i].className = "tice";
                            }
                            // alert("unhighlightTableRow(unhighlightingUncheckedRow... currentRowIndex=" + currentRowIndex + ")");
                        }
                    }

                }

                // alert("unhighlightTableRow(currentRowIndex=" + currentRowIndex + ")");
            }
            // otherwise, disable table row unhighlighting
        }
    }
}


/**************************************************************************************
*  Function    : highlightTableRow()                                                 *
*  Description : For the specified table row, checks the "selection checkbox", and   *
*                    enables the "up/down arrow navigation" highlight color on its   *
*                    table cells.                                                    *
*  Parameters  : pTableRow, table row to be highlighted                              *
*  Assumptions : None.                                                               *
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function highlightTableRow(pTableRow) {

    var iconCellContents = null;

    if (justDoIt == true) {

        if (pTableRow != null) {

            // retrieve all "input" items within table row
            iconCellContents = pTableRow.getElementsByTagName("input");

            var lCheckboxPresent = false;
            if (iconCellContents != null) {
                for (var i = 0; i <= (iconCellContents.length - 1); i++) {
                    // if selection checkbox present within table row...
                    if ((iconCellContents[i].type == "checkbox") && (iconCellContents[i].id.indexOf("RecordRowSelection") != -1 || iconCellContents[i].id.indexOf("SelectRow") != -1)) {
                        lCheckboxPresent = true;
                        iconCellContents[i].focus();
                        break;
                    }
                }
            }

            if (lCheckboxPresent) {
                // highlight row
                tableCells = pTableRow.getElementsByTagName("td");
                for (var i = 0; i < tableCells.length; i++) {
                    if (tableCells[i].parentNode == pTableRow) {
                        if ((tableCells[i].className == "tic") ||
		                	(tableCells[i].className == "tics") ||
		                	(tableCells[i].className == "icon_cell") ||
		                	(tableCells[i].className == "icon_cell_selected")) {
                            tableCells[i].className = "tich";
                        }
                        else if ((tableCells[i].className == "ticnb") ||
		                    	(tableCells[i].className == "ticsnb")) {
                            tableCells[i].className = "tichnb";
                        }
                        else if ((tableCells[i].className == "ticwb") ||
		                    	(tableCells[i].className == "ticswb")) {
                            tableCells[i].className = "tichwb";
                        }
                        else if ((tableCells[i].className == "tichb") ||
		                    	(tableCells[i].className == "ticshb")) {
                            tableCells[i].className = "tichhb";
                        }
                        else if ((tableCells[i].className == "ttc") ||
		                		 (tableCells[i].className == "ttcs") ||
		                		 (tableCells[i].className == "table_cell") ||
		                		 (tableCells[i].className == "table_cell_selected")) {
                            tableCells[i].className = "ttch";
                        }
                        else if ((tableCells[i].className == "tice") ||
		                		 (tableCells[i].className == "ticse")) {
                            tableCells[i].className = "tiche";
                        }

                        // save reference to current highlighted row
                        currentRow = pTableRow;
                    }
                }

                // alert("highlightTableRow(currentRowIndex=" + currentRowIndex + ",currentRowIsNull=" + (currentRow == null) + ")");
            }
        }
    }
}

/**************************************************************************************
*  Function    : tableRowHighlightable()                                             *
*  Description : Returns whether the table row contains a "selection checkbox".      *
*  Parameters  : None.                                                               *
*  Assumptions : None.                                                               *                 
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function tableRowHighlightable(pTableRow) {

    var rTableRowHighlightable = false;
    var iconCellContents = null;
    var headerCellContents = null;
    var tableRows = null;

    // retrieve all "input" items within table row
    iconCellContents = pTableRow.getElementsByTagName("input");

    var lCheckboxNode = null;
    if (iconCellContents != null) {
        for (var i = 0; i <= (iconCellContents.length - 1); i++) {
            // if selection checkbox present within table row...
            if ((iconCellContents[i].type == "checkbox") && (iconCellContents[i].id.indexOf("RecordRowSelection") != -1 || iconCellContents[i].id.indexOf("SelectRow") != -1)) {
                lCheckboxNode = iconCellContents[i];
                break;
            }
        }
    }

    if (lCheckboxNode != null) {
        rTableRowHighlightable = true;
    }

    return (rTableRowHighlightable);
}

/**************************************************************************************
*  Function    : clickEditButtonOfTableRowInFocus()                                  *
*  Description : Invokes the edit record page of the selected record (in focus table *
*                    row) by programmatically clicking the record's edit button.     *
*  Parameters  : None.                                                               *
*  Assumptions : The edit button is contained in the first cell of the table row in  *
*                    focus.                                                          *                 
*  ISD Feature : "Up/Down Arrow Keypress Navigation"                                 *
*  Authors     : Samson Wong & Cocosoft B.V.                                         *
**************************************************************************************/
function clickEditButtonOfTableRowInFocus() {
    var iconCellContents = null;
    var rTableRowClickable = false;

    if (justDoIt == true) {

        if (currentTable != null) {

            if (currentRow != null) {

                iconCellContents = currentRow.getElementsByTagName("input");

                for (var i = 0; i < iconCellContents.length; i++) {
                    // alert("clickEditButtonOfTableRowInFocus(iconCellContents.item(" + i + ").id=" + iconCellContents[i].id + ")");
                    if (iconCellContents[i].id.indexOf("EditButton") != -1) {
                        iconCellContents[i].click();
                        rTableRowClickable = true;
                        break;
                    }
                }
            }
        }
    }

    return (rTableRowClickable);
}


/**************************************************************************************
*  Function    : isChildSelectionCheckboxOf()                                        *
*  Description : Determines whether selection checkbox is an immediate child         *
*                    checkbox of the current parent table.                           *
*  Parameters  : aParentTable, current parent table.                                 *
*                aCheckbox, selection checkbox                                       *
*  Assumptions : None.                                                               *
*  ISD Feature : "Toggle All Checkboxes"                                             *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function isChildSelectionCheckboxOf(aParentTable, aCheckbox) {
    var lParentNode = aCheckbox.parentNode;
    while (lParentNode.nodeName != "TABLE") {
        lParentNode = lParentNode.parentNode;
    }

    return (aParentTable == lParentNode);
}


/**************************************************************************************
*  Function    : toggleAllCheckboxes()                                               *
*  Description : Checks/unchecks all "icon cell" checkboxes (and highlights/         *
*                    unhighlights their corresponding rows) if the "select all"      *
*                    checkbox is checked/unchecked.                                  *
*  Parameters  : aMainCheckboxNode, reference to "select all" checkbox.              *
*  Assumptions : This onclick event handler should only be used by the "select all"  *
*                    checkbox.                                                       *
*  ISD Feature : "Select All Checkbox"                                               *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function toggleAllCheckboxes(aMainCheckboxNode) {

    var lTableNode = aMainCheckboxNode;

    // find parent table
    while (lTableNode.nodeName != "TABLE") {
        lTableNode = lTableNode.parentNode;
    }

    // retrieve all "input" items within parent table    
    var lInputArray = lTableNode.getElementsByTagName("input");

    // if ToggleAllCheckbox has been checked...
    if (aMainCheckboxNode.checked == true) {

        for (i = 0; i < lInputArray.length; i++) {

            // if immediate child selection checkbox or another ToggleAllCheckbox present within table row...
            if (isChildSelectionCheckboxOf(lTableNode, lInputArray[i])) {
                if ((lInputArray[i].type == "checkbox") &&
                    (lInputArray[i].id.indexOf("RecordRowSelection") != -1 || lInputArray[i].id.indexOf("SelectRow") != -1 || lInputArray[i].id.indexOf("ToggleAll") != -1)) {
                    // check immediate child checkbox
                    lInputArray[i].checked = true;
                    selectTableRow(lInputArray[i].parentNode.parentNode);
                }
            }
        }
    }
    // if ToggleAllCheckbox has been unchecked...
    else {

        for (i = 0; i < lInputArray.length; i++) {

            // if immediate child selection checkbox or another ToggleAllCheckbox present within table row...            
            if (isChildSelectionCheckboxOf(lTableNode, lInputArray[i])) {
                if ((lInputArray[i].type == "checkbox") &&
                    (lInputArray[i].id.indexOf("RecordRowSelection") != -1 || lInputArray[i].id.indexOf("SelectRow") != -1 || lInputArray[i].id.indexOf("ToggleAll") != -1)) {
                    // uncheck immediate child checkbox
                    lInputArray[i].checked = false;
                    unselectTableRow(lInputArray[i].parentNode.parentNode);
                }
            }
        }
    }
}


/**************************************************************************************
*  Function    : unselectTableRow()                                                  *
*  Description : Disables "select" highlight color on the specified table row.       *
*  Parameters  : aTableRow, reference to table row whose "select" highlight color is *
*                    to be disabled.                                                 *
*  ISD Feature : "Select All Checkbox"                                               *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function unselectTableRow(aTableRow) {

    if (justDoIt == true) {

        if (aTableRow != null) {

            // unselect row
            tableCells = aTableRow.getElementsByTagName("td");
            for (var i = 0; i < tableCells.length; i++) {

                // if table row cell in main table (i.e., not a nested table row cell)...
                if (tableCells[i].parentNode == aTableRow) {
                    if ((tableCells[i].className == "tics") ||
	                	(tableCells[i].className == "icon_cell_selected")) {
                        tableCells[i].className = "tic";
                    }
                    else if (tableCells[i].className == "ticsnb") {
                        tableCells[i].className = "ticnb";
                    }
                    else if (tableCells[i].className == "ticswb") {
                        tableCells[i].className = "ticwb";
                    }
                    else if ((tableCells[i].className == "ttcs") ||
	                		 (tableCells[i].className == "table_cell_selected")) {
                        tableCells[i].className = "ttc";
                    }
                    else if (tableCells[i].className == "ticse") {
                        tableCells[i].className = "tice";
                    }
                    // alert("unselectTableRow(unselecting... tableCells.item(" + i + ").nodeName=" + tableCells[i].nodeName + ")");
                }
            }
        }
    }
}


/**************************************************************************************
*  Function    : selectTableRow()                                                    *
*  Description : Enables "select" highlight color on the specified table row.        *
*  Parameters  : aTableRow, reference to table row whose "select" highlight color is *
*                    to be enabled.                                                  *
*  ISD Feature : "Select All Checkbox"                                               *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function selectTableRow(aTableRow) {

    if (justDoIt == true) {

        if (aTableRow != null) {

            // select row
            tableCells = aTableRow.getElementsByTagName("td");
            for (var i = 0; i < tableCells.length; i++) {

                // if table row cell in main table (i.e., not a nested table row cell)...
                if (tableCells[i].parentNode == aTableRow) {
                    if ((tableCells[i].className == "tic") ||
	                	(tableCells[i].className == "icon_cell")) {
                        tableCells[i].className = "tics";
                    }
                    else if (tableCells[i].className == "ticnb") {
                        tableCells[i].className = "ticsnb";
                    }
                    else if (tableCells[i].className == "ticwb") {
                        tableCells[i].className = "ticswb";
                    }
                    else if ((tableCells[i].className == "ttc") ||
	                		 (tableCells[i].className == "table_cell")) {
                        tableCells[i].className = "ttcs";
                    }
                    else if (tableCells[i].className == "tice") {
                        tableCells[i].className = "ticse";
                    }
                    // alert("selectTableRow(selecting... tableCells.item(" + i + ").nodeName=" + tableCells[i].nodeName + ")");
                }
            }
        }
    }
}


function onLoad() {
    goToCurrentBrowserCoordinates();
    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function() { submitcount = 0; });
}


/**************************************************************************************
*  Function    : setCurrentBrowserCoordinates()                                      *
*  Description : Records current browser focus location based upon user input        *
*                    (scroll, click, or keypress).                                   *
*  Parameters  : None.                                                               *
*  ISD Feature : "Maintain position in tables"                                       *
*  Authors     : Akesh Gupta, Light Speed Solutions                                  *
**************************************************************************************/
function setCurrentBrowserCoordinates() {
    var scrollX, scrollY;

    // if (justDoIt == true) {
    var pageLeftCoordinate = document.getElementById("pageLeftCoordinate");
    var pageTopCoordinate = document.getElementById("pageTopCoordinate");

    // do not scroll in pre-v3.2.1 apps (which do not contain the hidden scroll coordinates fields)         
    if (!pageLeftCoordinate || !pageTopCoordinate) return;

    if (document.all) {
        if (!document.documentElement.scrollLeft)
            scrollX = document.body.scrollLeft;
        else
            scrollX = document.documentElement.scrollLeft;

        if (!document.documentElement.scrollTop)
            scrollY = document.body.scrollTop;
        else
            scrollY = document.documentElement.scrollTop;
    }
    else {
        scrollX = window.pageXOffset;
        scrollY = window.pageYOffset;
    }

    // alert("setCurrentBrowserCoordinates(x=" + scrollX + ",y=" + scrollY + ")");
    pageLeftCoordinate.value = scrollX;
    pageTopCoordinate.value = scrollY;
    // }
}

/**************************************************************************************
*  Function    : goToCurrentBrowserCoordinates()                                     *
*  Description : Moves to the browser coordinates previously saved by                *
*                    setCurrentBrowserCoordinates().                                 *
*  Parameters  : None.                                                               *
*  ISD Feature : "Maintain position in tables"                                       *
*  Authors     : Akesh Gupta, Light Speed Solutions                                  *
**************************************************************************************/
function goToCurrentBrowserCoordinates() {
    // if (justDoIt == true) {
    var pageLeftCoordinate = document.getElementById("pageLeftCoordinate");
    var pageTopCoordinate = document.getElementById("pageTopCoordinate");

    // do not scroll in pre-v3.2.1 apps (which do not contain the hidden scroll coordinates fields) 
    if (!pageLeftCoordinate || !pageTopCoordinate) return;

    // do not scroll if not a doPostBack() reload of page
    if ((pageLeftCoordinate.value == "") && (pageTopCoordinate.value == "")) return;

    var scrollX = pageLeftCoordinate.value;
    var scrollY = pageTopCoordinate.value;
    // alert("goToCurrentBrowserCoordinates(x=" + scrollX + ",y=" + scrollY + ")");
    window.scrollTo(scrollX, scrollY);
    // }
}

/**************************************************************************************
*  Function    : dropDownListTypeAhead()                                             *
*  Description : Moves focus to select option which matches string entered on        *
*                    keyboard.                                                       *
*  Parameters  : dropdownlist, select element catching the keypress events.          *
*                caseSensitive, indicates whether or not keypresses and select       *
*                    option values need to match by case.                            *
*  ISD Feature : "Dropdown List Type Ahead"                                          *
*  Authors     : Akesh Gupta & Samson Wong                                           *
**************************************************************************************/
function dropDownListTypeAhead(dropdownlist, caseSensitive) {

    // if (justDoIt == true) {
    // Make sure the control is a drop down list.
    if (dropdownlist.type != 'select-one') return;

    // check the keypressBuffer attribute is defined on the dropdownlist
    var undefined;

    // if enter key captured...
    if ((window.event) && (window.event.keyCode == 13)) {
        // explicitly perform filtering
        // setTimeout("__doPostBack('" + window.event.srcElement.id + "','')", 0);

        // per Howie, allow dropdownlist to perform postback
        return true;
    }

    window.event.cancelBubble = true;

    if (dropdownlist.keypressBuffer == undefined) {
        dropdownlist.keypressBuffer = "";
    }

    // get the key that was pressed
    var key;

    if (event.keyCode) {
        key = String.fromCharCode(window.event.keyCode);
    }
    else if (event.which) {
        key = String.fromCharCode(event.which);
    }

    dropdownlist.keypressBuffer += key;

    if (!caseSensitive) {
        // convert buffer to lowercase"
        dropdownlist.keypressBuffer = dropdownlist.keypressBuffer.toLowerCase();
    }

    // find if it is the start of any of the options
    var optionsLength = dropdownlist.options.length;

    for (var n = 0; n < optionsLength; n++) {
        var optionText = dropdownlist.options[n].text;
        if (!caseSensitive) {
            optionText = optionText.toLowerCase();
        }
        if (optionText.indexOf(dropdownlist.keypressBuffer, 0) == 0) {
            dropdownlist.selectedIndex = n;

            // if (dropdownlist.keypressBuffer.length > 1) {
            //  alert("dropDownListTypeAhead(match, keypressBuffer=" + dropdownlist.keypressBuffer + ",selectedIndex=" + dropdownlist.selectedIndex + ")");
            // }

            // cancel the default behavior since we have selected our own value
            window.event.returnValue = false;
            return false;
        }
    }

    // alert("dropDownListTypeAhead(reset, keypressBuffer=" + dropdownlist.keypressBuffer + ")");

    // reset initial key to be inline with default behavior
    dropdownlist.keypressBuffer = key;
    // }

    // give default behavior
    return true;
}

/**************************************************************************************
*  Description : Event handlers (scroll, click, and keypress) active for all pages.  *
*  Parameters  : None.                                                               *
*  ISD Feature : "Maintain position in tables"                                       *
*  Authors     : Akesh Gupta, Light Speed Solutions                                  *
**************************************************************************************/
window.onload = onLoad;
window.onscroll = setCurrentBrowserCoordinates;
window.onclick = setCurrentBrowserCoordinates;
window.onkeypress = setCurrentBrowserCoordinates;




/**************************************************************************************
*  Description : Global variables used by "Detail Rollever Popup" feature.           *
*  ISD Feature : "Detail Rollover Popup"                                             *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
var gDisplayInnerHTML = 0;
var gPersist = false;
var gPopupTimer = null;
var gCurrentInnerHTML = '';
var gRTL = false;


/**************************************************************************************
*  Function    : setRTL()                                                            *
*  Description : Sets the boolean to indicate that the application is RTL.           *
*  ISD Feature : "Detail Rollover Popup"                                             *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function setRTL() {
    gRTL = true;
}


/**************************************************************************************
*  Function    : clearRTL()                                                          *
*  Description : Clears the boolean to indicate that the application is not RTL.     *
*  ISD Feature : "Detail Rollover Popup"                                             *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function clearRTL() {
    gRTL = false;
}


/**************************************************************************************
*  Function    : delayRolloverPopup()                                                *
*  Description : Starts a timer, and invokes the specified function upon timer       *
*                    expiration.                                                     *
*  Parameters  : aFunction, a piece of JavaScript code to execute.                   *
*  ISD Feature : "Detail Rollover Popup"                                             *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function delayRolloverPopup(aFunction, aDelay) {

    // if valid piece of JavaScript passed in...
    if (aFunction != null) {
        if ((aDelay == null) || (aDelay <= 0)) {
            // set default delay to 500ms
            aDelay = 500;
        }

        // clear any previous pending popup invocation
        if (gPopupTimer != null) {
            clearTimeout(gPopupTimer);
            gPopupTimer = null;
        }

        // reinvoke delayed popup
        gPopupTimer = setTimeout(aFunction, aDelay);
    }
}

/**************************************************************************************
*  Function    : detailRolloverPopup()                                              *
*  Description : Displays "content" (returned from AJAX call) in a popup.            *
*  Parameters  : aTitle, string to be displayed in title bar of popup                *
*                aContent, string containing HTML to be displayed in body of popup.  *
*                aPersist, boolean indicating whether popup should remain even on    *
*                    mouseout.                                                       *
*                aWidth, default width of AJAX popup                                 *
*                aHeight, default height of AJAX popup                               *
*                aIsScrollable, boolean indicating whether scroll bar should be      *
*                    displayed if content is too long/wide for popup with specified  *
*                    width and height                                                *
*  ISD Feature : "Detail Rollover Popup"                                             *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function detailRolloverPopup(aTitle, aCloseBtnText, aContent, aPersist, aWidth, aHeight, aIsScrollable) {

    // if default size of popup is not specified...
    if ((aWidth == null) || (aHeight == null)) {
        // set default size as 300x200px
        aWidth = 300;
        aHeight = 200;
    }
    // ...else if specified sizes are "too small/large"...
    else {
        // set a min/max size
        if (aWidth < 100) {
            aWidth = 100;
        }
        else if (aWidth > 1000) {
            aWidth = 1000;
        }

        if (aHeight < 100) {
            aHeight = 100;
        }
        else if (aHeight > 1000) {
            aHeight = 1000;
        }
    }

    if (aIsScrollable) {
        // define scrollable region
        aContent = '<div style="clear:both;height:' + aHeight + 'px;width:' + aWidth + 'px;overflow:auto;">' + aContent + '</div>';
    }

    var lPageOffsetX;
    var lPageOffsetY;
    var lClientHeight;
    var lClientWidth;

    // determine browser window scrolled position
    lPageOffsetX = $(this).scrollLeft();
    lPageOffsetY = $(this).scrollTop();

    // determine current browser window dimensions in IE
    if (document.all) {
        lClientHeight = document.documentElement.clientHeight;
        lClientWidth = document.documentElement.clientWidth;
    }
    else // in Firefox
    {
        lClientHeight = window.innerHeight;
        lClientWidth = window.innerWidth;
    }

    // determine mouse cursor position (top left, top right, bottom left, or bottom right) relative to current browser window
    var lRelativeX = gEventClientX - lPageOffsetX;
    var lRelativeY = gEventClientY - lPageOffsetY;
    var lInLeftHalf;
    var lInTopHalf;

    if (lRelativeX <= (lClientWidth / 2)) {
        if (!gRTL) {
            lInLeftHalf = true;
        }
        else {
            lInLeftHalf = false;
        }
    }
    else {
        if (!gRTL) {
            lInLeftHalf = false;
        }
        else {
            lInLeftHalf = true;
        }
    }

    if (lRelativeY <= (lClientHeight / 2)) {
        lInTopHalf = true;
    }
    else {
        lInTopHalf = false;
    }

    // determine PNG support based on broswer version (for IE6 or lower, we'll need to use css filters to simulate PNG transparency)
    var lPNGSupported = true;

    /* remove support for non-PNG-supporting IE6 (this will resolve the non-compliant "filter" css errors)
    if (navigator.appName == "Microsoft Internet Explorer")
    {
    var lIEVersion = 0;
    if (navigator.appVersion.indexOf("MSIE") != -1)
    {
    var lIEAppVersionStringArray = navigator.appVersion.split("MSIE");
    lIEVersion = parseFloat(lIEAppVersionStringArray[1]);
    }

    		if (lIEVersion < 7)
    {
    lPNGSupported = false;
    }
    }
    */

    // correct for IE RTL offset
    if ((document.all) && (gRTL)) {
        gEventClientX -= (document.documentElement.scrollWidth - lClientWidth + 20);
    }

    // create appropriate html shell to display popup in correct location relative to mouse cursor position
    var lInnerHTML;
    if (lInLeftHalf && lInTopHalf) {
        // alert("detailRolloverPopup(inNW)");
        gEventClientX = gEventClientX + 10;
        if (gRTL) {
            gEventClientX -= 450;
        }
        gEventClientY = gEventClientY - 60;

        lInnerHTML = '<table cellpadding="0" cellspacing="0" border="0" class="popupWrapper" style="visibility: visible;"><tr><td class="detailRolloverTL">&nbsp;</td><td class="detailRolloverT" style="vertical-align:middle;"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="detailRolloverTitle"><div class="detailRolloverTitlePadding"><br/><br/></div>'
	                                + aTitle
	                                + '</td><td class="detailRolloverPopupCloseButtonAlignment"><a onclick="gPersist=false;detailRolloverPopupClose();" onmouseover="document.getElementById(\'detailRolloverPopupCloseButton\').src=\'../Images/closeButtonOver.gif\';" onmouseout="document.getElementById(\'detailRolloverPopupCloseButton\').src=\'../Images/closeButton.gif\';" title="' + aCloseBtnText + '"><img id="detailRolloverPopupCloseButton" src="../Images/closeButton.gif" border="0"></a></td></tr></table></td><td class="detailRolloverTR">&nbsp;</td></tr><td class="detailRolloverL"><img src="../Images/';

        if (!gRTL) {
            lInnerHTML += 'detailRolloverPoint.png';
        }
        else {
            lInnerHTML += 'detailRolloverPoint.rtl.png';
        }

        lInnerHTML += '"></td><td class="detailRolloverC">'
	                                + aContent
	                                + '</td><td class="detailRolloverR">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td></tr><tr><td class="detailRolloverBL">&nbsp;</td><td class="detailRolloverB">&nbsp;</td><td class="detailRolloverBR">&nbsp;</td></tr></table>';
    }
    else if (!lInLeftHalf && lInTopHalf) {
        // alert("detailRolloverPopup(inNE)");
        gEventClientX = gEventClientX - (140 + aWidth);
        if (gRTL) {
            gEventClientX += 450;
        }
        gEventClientY = gEventClientY - 60;

        lInnerHTML = '<table cellpadding="0" cellspacing="0" border="0" class="popupWrapper" style="visibility: visible;"><tr><td class="detailRolloverTL">&nbsp;</td><td class="detailRolloverT" style="vertical-align:middle;"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="detailRolloverTitle"><div class="detailRolloverTitlePadding"><br/><br/></div>'
	                                + aTitle
	                                + '</td><td class="detailRolloverPopupCloseButtonAlignment"><a onclick="gPersist=false;detailRolloverPopupClose();" onmouseover="document.getElementById(\'detailRolloverPopupCloseButton\').src=\'../Images/closeButtonOver.gif\';" onmouseout="document.getElementById(\'detailRolloverPopupCloseButton\').src=\'../Images/closeButton.gif\';" title="' + aCloseBtnText + '"><img id="detailRolloverPopupCloseButton" src="../Images/closeButton.gif" border="0"></a></td></tr></table></td><td class="detailRolloverTR">&nbsp;</td></tr><td class="detailRolloverL">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td class="detailRolloverC">'
	                                + aContent
	                                + '</td><td class="detailRolloverR"><img src="../Images/';

        if (!gRTL) {
            lInnerHTML += 'detailRolloverPoint.rtl.png';
        }
        else {
            lInnerHTML += 'detailRolloverPoint.png';
        }

        lInnerHTML += '"></td></tr><tr><td class="detailRolloverBL">&nbsp;</td><td class="detailRolloverB">&nbsp;</td><td class="detailRolloverBR">&nbsp;</td></tr></table>';
    }
    else if (lInLeftHalf && !lInTopHalf) {
        // alert("detailRolloverPopup(inSW)");
        gEventClientX = gEventClientX + 6;
        if (gRTL) {
            gEventClientX -= 450;
        }
        gEventClientY = gEventClientY - (45 + aHeight);

        lInnerHTML = '<table cellpadding="0" cellspacing="0" border="0" class="popupWrapper" style="visibility: visible;"><tr><td class="detailRolloverTL">&nbsp;</td><td class="detailRolloverT" style="vertical-align:middle;"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="detailRolloverTitle"><div class="detailRolloverTitlePadding"><br/><br/></div>'
	                                + aTitle
	                                + '</td><td class="detailRolloverPopupCloseButtonAlignment"><a onclick="gPersist=false;detailRolloverPopupClose();" onmouseover="document.getElementById(\'detailRolloverPopupCloseButton\').src=\'../Images/closeButtonOver.gif\';" onmouseout="document.getElementById(\'detailRolloverPopupCloseButton\').src=\'../Images/closeButton.gif\';" title="' + aCloseBtnText + '"><img id="detailRolloverPopupCloseButton" src="../Images/closeButton.gif" border="0"></a></td></tr></table></td><td class="detailRolloverTR">&nbsp;</td></tr><td class="detailRolloverL" style="padding-bottom:15px;vertical-align:bottom;"><img src="../Images/';

        if (!gRTL) {
            lInnerHTML += 'detailRolloverPoint.btt.png';
        }
        else {
            lInnerHTML += 'detailRolloverPoint.btt.rtl.png';
        }

        lInnerHTML += '"></td><td class="detailRolloverC" >'
	                                + aContent
	                                + '</td><td class="detailRolloverR">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td></tr><tr><td class="detailRolloverBL">&nbsp;</td><td class="detailRolloverB">&nbsp;</td><td class="detailRolloverBR">&nbsp;</td></tr></table>';
    }
    else // (!lInLeftHalf && !InTopHalf)
    {
        // alert("detailRolloverPopup(inSE)");
        gEventClientX = gEventClientX - (140 + aWidth);
        if (gRTL) {
            gEventClientX += 450;
        }
        gEventClientY = gEventClientY - (45 + aHeight);

        lInnerHTML = '<table cellpadding="0" cellspacing="0" border="0" class="popupWrapper" style="visibility: visible;"><tr><td class="detailRolloverTL">&nbsp;</td><td class="detailRolloverT" style="vertical-align:middle;"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="detailRolloverTitle"><div class="detailRolloverTitlePadding"><br/><br/></div>'
	                                + aTitle
	                                + '</td><td class="detailRolloverPopupCloseButtonAlignment"><a onclick="gPersist=false;detailRolloverPopupClose();" onmouseover="document.getElementById(\'detailRolloverPopupCloseButton\').src=\'../Images/closeButtonOver.gif\';" onmouseout="document.getElementById(\'detailRolloverPopupCloseButton\').src=\'../Images/closeButton.gif\';" title="' + aCloseBtnText + '"><img id="detailRolloverPopupCloseButton" src="../Images/closeButton.gif" border="0"></a></td></tr></table></td><td class="detailRolloverTR">&nbsp;</td></tr><td class="detailRolloverL">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td class="detailRolloverC" >'
	                                + aContent
	                                + '</td><td class="detailRolloverR" style="padding-bottom:15px;vertical-align:bottom;"><img src="../Images/';

        if (!gRTL) {
            lInnerHTML += 'detailRolloverPoint.btt.rtl.png';
        }
        else {
            lInnerHTML += 'detailRolloverPoint.btt.png';
        }

        lInnerHTML += '"></div></td></tr><tr><td class="detailRolloverBL">&nbsp;</td><td class="detailRolloverB">&nbsp;</td><td class="detailRolloverBR">&nbsp;</td></tr></table>';
    }

    gPersist = aPersist;
    var popupNode = document.getElementById("detailPopup");
    popupNode.innerHTML = lInnerHTML;
    popupNode.style.top = (gEventClientY) + "px";
    popupNode.style.left = (gEventClientX) + "px";

}


/**************************************************************************************
*  Function    : detailRolloverPopupClose()                                          *
*  Description : Closes (previously invoked by onmouseover/onclick event) popup.     *
*  Parameters  : None.                                                               *
*  ISD Feature : "Detail Rollover Popup"                                             *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function detailRolloverPopupClose() {


    // clear any previous pending popup invocation
    if (gPopupTimer != null) {
        clearTimeout(gPopupTimer);
        gPopupTimer = null;
    }

    if (gPersist != true) {
        // document.getElementById("detailPopup").innerHTML = "";
        gPopupTimer = setTimeout('document.getElementById("detailPopup").innerHTML = "";', 250);
    }
}

/**************************************************************************************
*  Function    : SaveMousePosition()                                                 *
*  Description : Saves the mouse position for use by detailRolloverPopup         *
*  Parameters  : event, reference to mouseover/onclick event                 *
**************************************************************************************/

var gEventClientX = 0;
var gEventClientY = 0;

// save latest coordinates (based on last mouse movement) instead of using those saved
// an AJAX-popup-delay (default 500ms) earlier
var IE = document.all ? true : false;
if (!IE) document.captureEvents(Event.MOUSEMOVE)
document.onmousemove = SaveMousePosition;

function SaveMousePosition(evt) {
    gEventClientX = mouseX(evt);
    gEventClientY = mouseY(evt);
}

function mouseX(evt) {
    evt = evt || window.event;
    if (evt.pageX) return evt.pageX;
    else if (evt.clientX)
        return evt.clientX + (document.documentElement.scrollLeft ?
            document.documentElement.scrollLeft :
            document.body.scrollLeft);
    else return null;
}


function mouseY(evt) {
    evt = evt || window.event;
    if (evt.pageY) return evt.pageY;
    else if (evt.clientY)
        return evt.clientY + (document.documentElement.scrollTop ?
            document.documentElement.scrollTop :
            document.body.scrollTop);
    else return null;
}


/**************************************************************************************
*  Description : Global variables used by "Date Formatter" feature.                  *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
var gDateSeparator1 = "/";      // single character separator of first two components of date string ("m"s, "d"s, and "y"s)
var gDateSeparator2 = "/";      // single character separator of last two components of date string ("m"s, "d"s, and "y"s)
var gPreviousDatePattern = ""; // last recorded date pattern
var gDatePatternArray = null;   // split portions of date pattern
var gDateMonthPosition = 1;    // position of month portion within date pattern
var gDateDayPosition = 2;      // position of day portion within date pattern
var gDateYearPosition = 3;     // position of year portion within date pattern
var gDateFormatterState = "0"  // current date formatter state machine state
var gDateStringEntered = "";   // last value in date textbox
var gCurrentValidDateArray = new Array(3);


// Check browser version
var isNav4 = false, isNav5 = false, isIE4 = false

if (navigator.appName == "Netscape") {
    if (navigator.appVersion < "5") {
        isNav4 = true;
        isNav5 = false;
    }
    else
        if (navigator.appVersion > "4") {
        isNav4 = false;
        isNav5 = true;
    }
}
else {
    isIE4 = true;
}


/**************************************************************************************
*  Function    : initializeDateFormatter()                                           *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function initializeDateFormatter(aInputTextbox) {
    gDateSeparator1 = "/";
    gDateSeparator2 = "/";
    gPreviousDatePattern = "";
    gDatePatternArray = null;
    gDateMonthPosition = 1;
    gDateDayPosition = 2;
    gDateYearPosition = 3;
    gDateFormatterState = "0";
    gCurrentValidDateString = new Array(3);
    gDateStringEntered = "";
}

function myAlert(aAlertString) {
    var debug = false;
    if (debug) {
        alert(aAlertString);
    }
}

/**************************************************************************************
*  Function    : toggleEnableDisableDateFormatter()                                  *
*  Description : Enables/disables Date Formatter.  On onfocus change (tabbing or     *
*                    onclick), pasting, backspacing/deleting, or left/right          *
*                    arrowing, date formatter is enabled if the date textbox is      *
*                    empty; disabled, otherwise (in which case the user is allowed   *
*                    to enter whatever he/she wishes, and date validation is only    *
*                    performed upon onblur).                                         *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*                aDatePattern, date pattern (containing some combination of "m"s,    *
*                    "s"s, "y"s, and "separators" to which the user-inputted date    *
*                     string is to be formated                                       *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function toggleEnableDisableDateFormatter(aInputTextbox, aDatePattern) {

    aInputTextbox.style.background = "#ffffff";
    initializeDateFormatter(aInputTextbox);

    // myAlert("onfocus:gPreviousDatePattern(" + gPreviousDatePattern + "), aDatePattern(" + aDatePattern + ")");
    // re-parse date pattern only if different from that in previous call
    if (gPreviousDatePattern != aDatePattern) {
        // parse date pattern
        if (!parseDatePattern(aInputTextbox, aDatePattern)) {
            goToNextState("DisableDateFormatter");
            return false;
        }
    }

    if (aInputTextbox.value != "") {
        // myAlert("toggleEnableDisableDateFormatter(disabling:" + aInputTextbox.value + ")");
        goToNextState("DisableDateFormatter");
    }
    // else {
    // myAlert("toggleEnableDisableDateFormatter(enabling:" + aInputTextbox.value + ")");
    // }
}


/**************************************************************************************
*  Function    : DateFormat()                                                        *
*  Description : This event handler accepts user-inputted date string, and           *
*                    auto-formats it according to the required date pattern.         *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*                aDateStringEntered, current contents (value) in the input textbox   * 
*                aEvent, reference to event (onkeyup) causing this event handler to  *
*                    be called                                                       *
*                aDatePattern, date pattern (containing some combination of "m"s,    *
*                    "s"s, "y"s, and "separators" to which the user-inputted date    *
*                     string is to be formated                                       *
*  Returns:    : false, if an invalid date digit is entered (it is automatically     *
*                    cleared for the user)                                           *
*                true, if valid date digit is entered                                *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function DateFormat(aInputTextbox, aDateStringEntered, aEvent, aDatePattern) {

    // if (justDoIt == true) {

    var whichCode;
    if (typeof (aEvent) == "number") {
        whichCode = aEvent;
    }
    else {
        whichCode = (window.Event) ? aEvent.which : aEvent.keyCode;
    }

    // if backspace, delete, left arrow, or right arrow...
    /*
    if ( (whichCode == 8) || (whichCode == 46) || (whichCode == 37) || (whichCode == 39) ) {

            if (!toggleEnableDisableDateFormatter(aInputTextbox, aDatePattern)) {
    return false;
    }
    }
    */
    // if Ctrl-v...
    /*
    else if (whichCode == 86) {
    // allow "pasting" of "copied" text into date field, but disable date formatter because
    //    user could have pasted anything (date validation will still be performed onblur)
    goToNextState("DisableDateFormatter");
    }
    */
    // if "up arrow" or "plus"
    if ((whichCode == 38) || (whichCode == 107)) {
        if ((gDatePatternArray == null) || (gPreviousDatePattern == "") || (gPreviousDatePattern != aDatePattern)) {
            toggleEnableDisableDateFormatter(aInputTextbox, aDatePattern);
        }

        while ((whichCode == 107) && (aInputTextbox.value.charAt(aInputTextbox.value.length - 1) == "+")) {
            aInputTextbox.value = (aInputTextbox.value).substring(0, aInputTextbox.value.length - 1);
        }

        // if date field not initialized...
        if (aInputTextbox.value == "") {
            // display today's date
            var lCurrentDate = new Date();
            displayDate(aInputTextbox, lCurrentDate);
        }
        else {
            if (presubmitDateValidation(aInputTextbox, aDatePattern)) {
                // create new date object based on current contents of date field
                var lCurrentDate = createNewDate(aInputTextbox);

                // if not a credit card expiration date (which lacks a day field)...
                if (gDateDayPosition != 0) {
                    // increment to next day (1000ms/s * 60s/min + 60min/hr + 24hr/day = 86400000ms/day)
                    lCurrentDate.setTime(lCurrentDate.getTime() + 86400000);
                }
                else {
                    if (lCurrentDate.getMonth() != 11) {
                        lCurrentDate.setMonth(lCurrentDate.getMonth() + 1);
                    }
                    else {
                        if (new Number(lCurrentDate.getYear()) < 9999) {
                            lCurrentDate.setMonth(0);
                            lCurrentDate.setYear(lCurrentDate.getYear() + 1);
                        }
                    }
                }

                // display new date
                displayDate(aInputTextbox, lCurrentDate);
            }
        }
    }
    // if "down arrow" or "minus"
    else if ((whichCode == 40) || (whichCode == 109)) {
        if ((gDatePatternArray == null) || (gPreviousDatePattern == "") || (gPreviousDatePattern != aDatePattern)) {
            toggleEnableDisableDateFormatter(aInputTextbox, aDatePattern);
        }

        while ((whichCode == 109) && (aInputTextbox.value.charAt(aInputTextbox.value.length - 1) == "-")) {
            aInputTextbox.value = (aInputTextbox.value).substring(0, aInputTextbox.value.length - 1);
        }

        // if date field not initialized...
        if (aInputTextbox.value == "") {
            // display today's date
            var lCurrentDate = new Date();
            displayDate(aInputTextbox, lCurrentDate);
        }
        else {
            if (presubmitDateValidation(aInputTextbox, aDatePattern)) {

                // create new date object based on current contents of date field
                var lCurrentDate = createNewDate(aInputTextbox);

                // if not a credit card expiration date (which lacks a day field)...
                if (gDateDayPosition != 0) {
                    // decrement to previous day (1000ms/s * 60s/min + 60min/hr + 24hr/day = 86400000ms/day)
                    lCurrentDate.setTime(lCurrentDate.getTime() - 86400000);
                }
                else {
                    if (lCurrentDate.getMonth() != 0) {
                        lCurrentDate.setMonth(lCurrentDate.getMonth() - 1);
                    }
                    else {
                        if (new Number(lCurrentDate.getYear()) > 1000) {
                            lCurrentDate.setMonth(11);
                            lCurrentDate.setYear(lCurrentDate.getYear() - 1);
                        }
                    }
                }

                // display new date
                displayDate(aInputTextbox, lCurrentDate);
            }
        }
    }
    /*  
    else
    {
    // if date formatter not disabled...
    if ((gDateFormatterState != "4") || (aInputTextbox.value.length == 1)) {
            
    // re-parse date pattern only if different from that in previous call
    if (gPreviousDatePattern != aDatePattern) { 
    // parse date pattern
    if (!parseDatePattern(aInputTextbox, aDatePattern)) {
    goToNextState("DisableDateFormatter");
    return false;
    }       
    }
                
    // convert numpad digit entries into regular (top of) keyboard digits
    if ((whichCode >=96) && (whichCode <=105)) {
    whichCode -= 48;
    }
    else if ((whichCode == 111) || (whichCode == 191)) {
    // date separator "/" returns whichCode 111 (from numpad) and 191 (from keyboard), but should be 47
    whichCode = 47;
    }
                
    aInputTextbox.value = gDateStringEntered + String.fromCharCode(whichCode);
        
    var lLastCharEntered = (aInputTextbox.value).charAt((aInputTextbox.value).length-1);
    // myAlert("DateFormat(lLastCharEntered=" + lLastCharEntered + ",whichCode=" + whichCode + ")");
            
    var lValidDigits = "1234567890";    
    // if last character entered is not a numerical digit nor the date separator...
    if ((lValidDigits.indexOf(lLastCharEntered) == -1) && (lLastCharEntered != gDateSeparator1) && (lLastCharEntered != gDateSeparator2)) {
    // sam (original) - not needed
    // sam - fixed bug in original code where once one invalid character is accepted (because of "quick typing" race condition)
    //     all further alphabetic checking fails (i.e., all subsequent invalid characters are accepted)
    //if (alphaCheck.indexOf(gDateStringEntered.charAt(gDateStringEntered.length-1)) >= 1)  
    //{
    clearLastCharEntered(aInputTextbox);
        
    return false;
    }
                
    if (gPreviousDatePattern != "") {
                
    // enter state machine
    switch(gDateFormatterState) {
    case "0": // empty date string
    if (gDateMonthPosition == 1) {
    processFirstMonthDigit(aInputTextbox, gDateStringEntered);
    }
    else if (gDateDayPosition == 1) {
    processFirstDayDigit(aInputTextbox, gDateStringEntered);
    }
    // year portion of date pattern is in first position
    else {
    processFirstYearDigit(aInputTextbox, gDateStringEntered);
    }
    break;
    case "0.1": // validating first portion of date string, and at least one digit has already been entered for it
    if (gDateMonthPosition == 1) {
    processSecondMonthDigit(aInputTextbox, gDateStringEntered);
    }
    else if (gDateDayPosition == 1) {
    processSecondDayDigit(aInputTextbox, gDateStringEntered);
    }
    // year portion of date pattern is in first position
    else {
    processSucceedingYearDigit(aInputTextbox, gDateStringEntered);
    }               
    break;
    case "1": // first portion of date string validated, awaiting first digit of second portion
    if (gDateMonthPosition == 2) {
    processFirstMonthDigit(aInputTextbox, gDateStringEntered);
    }
    else if (gDateDayPosition == 2) {
    processFirstDayDigit(aInputTextbox, gDateStringEntered);
    }
    // year portion of date pattern is in second position
    else {
    processFirstYearDigit(aInputTextbox, gDateStringEntered);
    }               
    break;
    case "1.1": // validating second portion of date sring, and at least one digit has already been entered for it
    if (gDateMonthPosition == 2) {
    processSecondMonthDigit(aInputTextbox, gDateStringEntered);
    }
    else if (gDateDayPosition == 2) {
    processSecondDayDigit(aInputTextbox, gDateStringEntered);
    }
    // year portion of date pattern is in second position
    else {
    processSucceedingYearDigit(aInputTextbox, gDateStringEntered);
    }               
    break;
    case "2":
    if (gDateMonthPosition == 3) {
    processFirstMonthDigit(aInputTextbox, gDateStringEntered);
    }
    else if (gDateDayPosition == 3) {
    processFirstDayDigit(aInputTextbox, gDateStringEntered);
    }
    // year portion of date pattern is in third position
    else if (gDateYearPosition == 3) {
    processFirstYearDigit(aInputTextbox, gDateStringEntered);
    }   
    // no third date portion (e.g., credit card expiration date mm/yyyy)
    else {
    // clear last digit entered; disallow all addition digit entry (await onblur date validation)
    aInputTextbox.value = aInputTextbox.value.substring(0, gDateStringEntered.length-1);
    gDateFormatterState = "3";
    }           
    break;
    case "2.1":
    if (gDateMonthPosition == 3) {
    processSecondMonthDigit(aInputTextbox, gDateStringEntered);
    }
    else if (gDateDayPosition == 3) {
    processSecondDayDigit(aInputTextbox, gDateStringEntered);
    }
    // year portion of date pattern is in third position
    else {
    processSucceedingYearDigit(aInputTextbox, gDateStringEntered);
    }               
    break;
    case "3":
    // disallow all addition digit entry (await onblur date validation)
    aInputTextbox.value = aInputTextbox.value.substring(0, gDateStringEntered.length);
    break;
    }
    }
    }
    }
    */

    // save current valid string entered
    gDateStringEntered = aInputTextbox.value;

    return true;
    // }
}


/**************************************************************************************
*  Function    : goToNextState()                                                     *
*  Description : Updates the state machine to the next state following               *
*                    "portionUpdated".                                               *
*  Parameters  : portionUpdated, last state of parser                                *
*  Returns:    : None.                                                               *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function goToNextState(portionUpdated) {
    switch (portionUpdated) {
        case "FirstMonthDigit":
            switch (gDateMonthPosition) {
                case 1:
                    gDateFormatterState = "0.1";
                    break;
                case 2:
                    gDateFormatterState = "1.1";
                    break;
                case 3:
                    gDateFormatterState = "2.1";
                    break;
            }
            break;
        case "SecondMonthDigit":
            switch (gDateMonthPosition) {
                case 1:
                    gDateFormatterState = "1";
                    break;
                case 2:
                    gDateFormatterState = "2";
                    break;
                case 3:
                    gDateFormatterState = "3";
                    break;
            }
            break;
        case "FirstDayDigit":
            switch (gDateDayPosition) {
                case 1:
                    gDateFormatterState = "0.1";
                    break;
                case 2:
                    gDateFormatterState = "1.1";
                    break;
                case 3:
                    gDateFormatterState = "2.1";
                    break;
            }
            break;
        case "SecondDayDigit":
            switch (gDateDayPosition) {
                case 1:
                    gDateFormatterState = "1";
                    break;
                case 2:
                    gDateFormatterState = "2";
                    break;
                case 3:
                    gDateFormatterState = "3";
                    break;
            }
            break;
        case "FirstYearDigit":
            switch (gDateYearPosition) {
                case 1:
                    gDateFormatterState = "0.1";
                    break;
                case 2:
                    gDateFormatterState = "1.1";
                    break;
                case 3:
                    gDateFormatterState = "2.1";
                    break;
            }
            break;
        case "SucceedingYearDigit":
            switch (gDateYearPosition) {
                case 1:
                    gDateFormatterState = "1";
                    break;
                case 2:
                    if (gDateDayPosition != 0) {
                        gDateFormatterState = "2";
                    }
                    // else if special case of "credit card expiration date field" (i.e., without "day" value), early terminate date formatter
                    else {
                        gDateFormatterState = "3";
                    }
                    break;
                case 3:
                    gDateFormatterState = "3";
                    break;
            }
            break;
        case "DisableDateFormatter":
            gDateFormatterState = "4";
            break;
    }
}

/**************************************************************************************
*  Function    : clearPreviousCharEntered()                                          *
*  Description : Clears the previous date digit entered, and adjusts the state       *
*                    machine accordingly.                                            *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*                gDateStringEntered, current contents (value) in the input textbox   *
*  Returns:    : None.                                                               *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function clearPreviousCharEntered(aInputTextbox) {
    /*
    switch(gDateFormatterState) {
    case "0.0":
    break;
            
    case "0.1":
    if (gDateYearPosition ==1) {
    // clear previous date digit        
    aInputTextbox.value = aInputTextbox.value.substring(0, aInputTextbox.value.length-1);
                
    // reset current valid date string
    gCurrentValidDateArray[0].charAt(gDatePatterArray.length-1) = gDatePatternArray[0].charAt(gDatePatterArray.length-1);
                
    if (gCurrentValidDateArray[0].indexOf() {
    // remain in current state machine state
    gDateFormatterState = "0.1"
    }
    else {
    // reset state machine state
    gDateFormatterState = "0.0"
    }
    }
    else {
    // clear only date digit        
    aInputTextbox.value = "";
                
    // reset current valid date string
    gCurrentValidDateArray[0] = gDatePatternArray[0];
                
    // reset state machine state
    gDateFormatterState = "0.0";
    }
    break;
    case "1.0":
    // clear date separator and last date digit
    aInputTextbox.value = aInputTextbox.value.substring(0, aInputTextbox.value.length-2);

            // reset current valid date string
    gCurrentValidDateArray[0].charAt(gDatePatterArray.length-1) = gDatePatternArray[0].charAt(gDatePatterArray.length-1);
            
    // reset state machine state
    gDateFormatterState = "0.1";
        
    break;
    case "1.1":
        
    break;
    case "2.0":
        
    break;
    case "2.1":
        
    break;
    case "3.0":
        
    break;
    }
    */
}


/**************************************************************************************
*  Function    : parseDatePattern()                                                  *
*  Description : Parses, validates, and records the input date pattern to which the  *
*                     user-inputted date string will be formatted.                   *
*  Parameters  : aDatePattern, date pattern (should be composed of a combination of  *
*                    "m"s, "d"s, "y"s, and "separators").                            *
*  Returns:    : true, if date pattern is valid.                                     *
*                false, if date pattern is invalid.                                  *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function parseDatePattern(aInputTextbox, aDatePattern) {

    var lDatePattern = aDatePattern;
    //lDatePattern = "yyyy/mm/dd";

    // initialize global variables
    initializeDateFormatter(aInputTextbox);

    // strip all occurrences of "m"s, "d"s, and "y"s
    lDatePattern = stripChar(lDatePattern, "m");
    if (lDatePattern != "invalid date pattern") {
        lDatePattern = stripChar(lDatePattern, "d");
    }
    else {
        return false;
    }
    if (lDatePattern != "invalid date pattern") {
        lDatePattern = stripChar(lDatePattern, "y");
    }
    else {
        return false;
    }

    if (lDatePattern == "invalid date pattern") {
        return false;
    }

    // strip extraneous spaces in Hungarian and Slovak date patterns
    // while (lDatePattern.indexOf(" ") != -1)
    // {
    //   lDatePattern = lDatePattern.replace(" ", "");
    //   aDatePattern = aDatePattern.replace(" ", "");
    // }

    // strip extraneous trailing separator in Slovak date pattern
    // if ((lDatePattern.length == 3) && (lDatePattern.charAt(2) == ".")) {
    //  lDatePattern = lDatePattern.substring(0,lDatePattern.length-1);
    //  aDatePattern = aDatePattern.substring(0,aDatePattern.length-1);
    // }

    // myAlert("parseDatePattern(lDatePattern=" + lDatePattern + ",aDatePattern=" + aDatePattern + ")");

    // determine date separator
    // alert("lDatePattern.length(" + lDatePattern.length + ")");
    if ((lDatePattern.length == 2) || (lDatePattern.length == 1)) {

        if (lDatePattern.length == 2) {
            gDateSeparator1 = lDatePattern.charAt(0);
            gDateSeparator2 = lDatePattern.charAt(1);
        }
        else // (lDatePattern.length == 1)
        {
            gDateSeparator1 = lDatePattern.charAt(0);
            gDateSeparator2 = lDatePattern.charAt(0);
        }

        if (gDateSeparator1 == gDateSeparator2) {
            // split date pattern into date component portions
            gDatePatternArray = aDatePattern.split(gDateSeparator1);
        }
        else // (gDateSeparator1 != gDateSeparator2)
        {
            var lTempArray1 = aDatePattern.split(gDateSeparator1);
            var lDatePortion1 = lTempArray1[0];
            var lTempArray2 = lTempArray1[1].split(gDateSeparator2);
            var lDatePortion2 = lTempArray2[0];
            if (lTempArray2.length == 1) {
                gDatePatternArray = new Array(lDatePortion1, lDatePortion2);
            }
            else if (lTempArray2.length > 1) {
                gDatePatternArray = new Array(lDatePortion1, lDatePortion2, lTempArray2[1]);
            }
        }

        // alert("gDatePatternArray.length(" + gDatePatternArray.length + ")");
        if ((gDatePatternArray.length == 3) || (gDatePatternArray.length == 2)) {

            // now that an actual date pattern is being passed in via the event handlers, initialize date portion positions
            gDateMonthPosition = 0;
            gDateDayPosition = 0;
            gDateYearPosition = 0;

            for (var i = 0; i < (gDatePatternArray.length); i++) {
                // alert("gDatePatternArray[" + i + "](" + gDatePatternArray[i] + ")");
                switch (gDatePatternArray[i].charAt(0)) {
                    case "m":
                        gDateMonthPosition = i + 1;
                        break;
                    case "d":
                        gDateDayPosition = i + 1;
                        break;
                    case "y":
                        gDateYearPosition = i + 1;
                        break;
                }

                gCurrentValidDateArray[i] = gDatePatternArray[i];
            }

            // alert("parseDatePattern.mdyPositions(" + gDateMonthPosition + "," + gDateDayPosition + "," + gDateYearPosition + ")");
            // alert("parseDatePattern(gCurrentValidDateArray[0]=" + gCurrentValidDateArray[0] + ",gCurrentValidDateArray[1]=" + gCurrentValidDateArray[1] + ",gCurrentValidDateArray[2]=" + gCurrentValidDateArray[2] + ")");

            // record date pattern
            gPreviousDatePattern = aDatePattern;

            return true;
        }
    }

    // clear recorded date pattern
    gPreviousDatePattern = "";

    return false;
}


/**************************************************************************************
*  Function    : stripChar()                                                         *
*  Description : Helper function to removes all occurrences of an alphabetic         *
*                     character from an input string.                                *
*  Parameters  : pString, date pattern composed of a combination of "m"s, "d"s, and  *
*                    "y"s.                                                           *
*                pCharToStrip, alphabetic character to be removed from pString.      *
*  Returns:    : Original input string with alphabetic character removed.            *
*  ISD Feature : "Date Formatter"                                                    *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function stripChar(pString, pCharToStrip) {
    var indexOfCharToEliminate = -1;
    var indexOfPreviousCharEliminated = -1;
    var lDone = false;

    while (!lDone) {
        if (pString.length == 0) {
            lDone = true;
        }
        else {
            indexOfCharToEliminate = pString.indexOf(pCharToStrip);

            // myAlert("stripChar(pString=" + pString + ",pCharToStrip=" + pCharToStrip + ",indexOfCharToEliminate=" + indexOfCharToEliminate + ")");

            if (indexOfCharToEliminate == -1) {
                lDone = true;
            }
            else {

                if ((indexOfPreviousCharEliminated == -1) ||
                     ((indexOfPreviousCharEliminated != -1) && (indexOfPreviousCharEliminated == indexOfCharToEliminate))) {
                    // remove single character from input string
                    pString = pString.substring(0, indexOfCharToEliminate) + pString.substring(indexOfCharToEliminate + 1, (pString.length));

                    // record index of last character eliminated (the next, if any, character to be eliminated must be in the same location
                    //    as this character removed, i.e., the individual "m"s, "d"s, and "y"s, respectively, must be adjacent to each other,
                    //    otherwise the date pattern is invalid)
                    indexOfPreviousCharEliminated = indexOfCharToEliminate;
                }
                else {
                    // myAlert("stripCharInvalid(pString=" + pString + ",pCharToStrip=" + pCharToStrip + ")");
                    return ("invalid date pattern");
                }
            }
        }
    }
    return (pString);
}


/**************************************************************************************
*  Function    : clearLastCharEntered()                                              *
*  Description : Helper function to remove the last character entered in the input   *
*                     textbox.                                                       *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*  Returns:    : true, if last character successfully removed.                       *
*                false, if reference to input textbox invalid.                       *
*  ISD Feature : "Date Formatter"                                                    *
*  Authors     : Richard Gorremans (xbase@volcano.net), www.spiritwolfx.com, and     *
*                    Samson Wong                                                     *
**************************************************************************************/
function clearLastCharEntered(aInputTextbox) {

    // myAlert("clearLastCharEntered(lastChar=" + aInputTextbox.value.charAt(aInputTextbox.value.length-1) + ")");
    if (aInputTextbox) {
        if (isNav4) {
            aInputTextbox.value = "";
            aInputTextbox.focus();
            aInputTextbox.select();
        }
        else {
            if (aInputTextbox.value.length > 1) {
                // clear last character, but retain the rest of (previously-entered) date string        
                aInputTextbox.value = aInputTextbox.value.substring(0, ((aInputTextbox.value.length) - 1));
            }
            else {
                aInputTextbox.value = "";
            }
        }
        return true;
    }
    return false;
}


/**************************************************************************************
*  Function    : presubmitDateValidation()                                           *
*  Description : onblur event handler to determine if date string entered is valid.  *
*                    Changes the date textbox's background color to pink if invalid. *
*  Parameters  : aInputTextbox, reference to the html textbox into which the user    *
*                    enters the date string                                          *
*                aDatePattern, date pattern (containing some combination of "m"s,    *
*                    "s"s, "y"s, and "separators" to which the user-inputted date    *
*                     string is to be formated                                       *
*  ISD Feature : "Date Formatter"                                                    *
*  Authors     : Samson Wong                                                         *
**************************************************************************************/
function presubmitDateValidation(aInputTextbox, aDatePattern) {
    var lInputTextboxArray;
    var lDatePatternArray;
    var lDateMonthString;
    var lDateDayString;
    var lDateYearString;
    var lValidDigits;
    var lDateValid = true; // assume valid date string unless discovered otherwise

    // myAlert("presubmitDateValidation(aInputTextbox.value=" + aInputTextbox.value + ",aDatePattern=" + aDatePattern + ")");
    // myAlert("presubmitDateValidation(gPreviousDatePattern=" + gPreviousDatePattern + ",aDatePattern=" + aDatePattern + ")");

    // re-parse date pattern only if different from that in previous call
    if (gPreviousDatePattern != aDatePattern) {

        // parse date pattern
        if (!parseDatePattern(aInputTextbox, aDatePattern)) {
            goToNextState("DisableDateFormatter");
            return false;
        }
    }

    if (aInputTextbox.value.length > 0) {
        if (gDateSeparator1 == gDateSeparator2) {
            // split date pattern into date component portions
            lDatePatternArray = aDatePattern.split(gDateSeparator1);
            lInputTextboxArray = aInputTextbox.value.split(gDateSeparator1);
        }
        else // (gDateSeparator1 != gDateSeparator2)
        {
            lDatePatternArray = new Array(3);
            var lTempArray1 = aDatePattern.split(gDateSeparator1);
            lDatePatternArray[0] = lTempArray1[0];
            var lTempArray2 = lTempArray1[1].split(gDateSeparator2);
            lDatePatternArray[1] = lTempArray2[0];
            lDatePatternArray[2] = lTempArray2[1];

            lInputTextboxArray = new Array(3);
            var lTempArray1 = aInputTextbox.value.split(gDateSeparator1);
            lInputTextboxArray[0] = lTempArray1[0];
            var lTempArray2 = lTempArray1[1].split(gDateSeparator2);
            lInputTextboxArray[1] = lTempArray2[0];
            lInputTextboxArray[2] = lTempArray2[1];

        }


        if (lDatePatternArray.length != lInputTextboxArray.length) {
            lDateValid = false;
        }

        if (lDatePatternArray.length == 3) {
            // extract individual month, day, and year strings
            switch (gDateMonthPosition) {
                case 1:
                    lDateMonthString = lInputTextboxArray[0];
                    break;
                case 2:
                    lDateMonthString = lInputTextboxArray[1];
                    break;
                case 3:
                    lDateMonthString = lInputTextboxArray[2];
                    break;
            }
            switch (gDateDayPosition) {
                case 1:
                    lDateDayString = lInputTextboxArray[0];
                    break;
                case 2:
                    lDateDayString = lInputTextboxArray[1];
                    break;
                case 3:
                    lDateDayString = lInputTextboxArray[2];
                    break;
            }
            switch (gDateYearPosition) {
                case 1:
                    lDateYearString = lInputTextboxArray[0];
                    break;
                case 2:
                    lDateYearString = lInputTextboxArray[1];
                    break;
                case 3:
                    lDateYearString = lInputTextboxArray[2];
                    break;
            }

            // myAlert("lDateMonthString(" + lDateMonthString + ")");
            // myAlert("lDateDayString(" + lDateDayString + ")");
            // myAlert("lDateYearString(" + lDateYearString + ")");

            // validate month string
            if ((lDateMonthString != null) && (lDateMonthString.length <= 2)) {
                // if two digit month string...
                if (lDateMonthString.length == 2) {
                    // if first digit is "0"...
                    if (lDateMonthString.charAt(0) == "0") {
                        lValidDigits = "123456789";
                        // if second digit is not "1"-"9"...
                        if (lValidDigits.indexOf(lDateMonthString.charAt(1)) == -1) {
                            lDateValid = false;
                        }
                    }
                    // if first digit is "1"...
                    else if (lDateMonthString.charAt(0) == "1") {
                        lValidDigits = "012";
                        // if second digit is not "0"-"2"...
                        if (lValidDigits.indexOf(lDateMonthString.charAt(1)) == -1) {
                            lDateValid = false;
                        }
                    }
                    // invalid first month digit
                    else {
                        lDateValid = false;
                    }
                }
                // if single digit month string...
                else if (lDateMonthString.length == 1) {
                    lValidDigits = "123456789";
                    // if single digit is not "1"-"9"...
                    if (lValidDigits.indexOf(lDateMonthString.charAt(0)) == -1) {
                        lDateValid = false;
                    }
                }
                // zero-lengthed month string (i.e., consecutive date separators in date textbox)
                else {
                    lDateValid = false;
                }
            }
            // too many characters in month string
            else {
                lDateValid = false;
            }

            // validate day string
            if ((lDateDayString != null) && (lDateDayString.length <= 2)) {
                // if two digit day string...
                if (lDateDayString.length == 2) {
                    // if first digit is "0"...
                    if (lDateDayString.charAt(0) == "0") {
                        lValidDigits = "123456789";
                        // if second digit is not "1"-"9"...
                        if (lValidDigits.indexOf(lDateDayString.charAt(1)) == -1) {
                            lDateValid = false;
                        }
                    }
                    // if first digit is "1" or "2"...
                    else if ((lDateDayString.charAt(0) == "1") || (lDateDayString.charAt(0) == "2")) {
                        lValidDigits = "0123456789";
                        // if second digit is not "0"-"9"...
                        if (lValidDigits.indexOf(lDateDayString.charAt(1)) == -1) {
                            lDateValid = false;
                        }
                    }
                    // if first digit is "3"...
                    else if (lDateDayString.charAt(0) == "3") {
                        lValidDigits = "01";
                        // if second digit is not "0" or "1"...
                        if (lValidDigits.indexOf(lDateDayString.charAt(1)) == -1) {
                            lDateValid = false;
                        }
                    }
                    // invalid first day digit
                    else {
                        lDateValid = false;
                    }
                }
                // if single digit day string...
                else if (lDateDayString.length == 1) {
                    lValidDigits = "123456789";
                    // if single digit is not "1"-"9"...
                    if (lValidDigits.indexOf(lDateDayString.charAt(0)) == -1) {
                        lDateValid = false;
                    }
                }
                // zero-lengthed day string (i.e., consecutive date separators in date textbox)
                else {
                    lDateValid = false;
                }
            }
            // too many digits in day string
            else {
                lDateValid = false;
            }

            // validate year string
            if ((lDateYearString != null) && (lDateYearString.length != 2) && (lDateYearString.length != 4)) {
                lDateValid = false;
            }
        }
        // special case of "credit card expiration date"...
        else if (lDatePatternArray.length == 2) {
            lInputTextboxArray = aInputTextbox.value.split(gDateSeparator1);

            // extract individual month and year strings
            lDateMonthString = lInputTextboxArray[0];
            lDateYearString = lInputTextboxArray[1];

            // myAlert("lDateMonthString(" + lDateMonthString + ")");
            // myAlert("lDateYearString(" + lDateYearString + ")");

            // validate month string
            if ((lDateMonthString != null) && (lDateMonthString.length <= 2)) {
                // if two digit month string...
                if (lDateMonthString.length == 2) {
                    // if first digit is "0"...
                    if (lDateMonthString.charAt(0) == "0") {
                        lValidDigits = "123456789";
                        // if second digit is not "1"-"9"...
                        if (lValidDigits.indexOf(lDateMonthString.charAt(1)) == -1) {
                            lDateValid = false;
                        }
                    }
                    // if first digit is "1"...
                    else if (lDateMonthString.charAt(0) == "1") {
                        lValidDigits = "012";
                        // if second digit is not "0"-"2"...
                        if (lValidDigits.indexOf(lDateMonthString.charAt(1)) == -1) {
                            lDateValid = false;
                        }
                    }
                    // invalid first month digit
                    else {
                        lDateValid = false;
                    }
                }
                // if single digit month string...
                else if (lDateMonthString.length == 1) {
                    lValidDigits = "123456789";
                    // if single digit is not "1"-"9"...
                    if (lValidDigits.indexOf(lDateMonthString.charAt(0)) == -1) {
                        lDateValid = false;
                    }
                }
                // zero-lengthed month string (i.e., consecutive date separators in date textbox)
                else {
                    lDateValid = false;
                }
            }
            // too many characters in month string
            else {
                lDateValid = false;
            }

            // validate year string
            if ((lDateYearString != null) && (lDateYearString.length != 2) && (lDateYearString.length != 4)) {
                lDateValid = false;
            }
        }
        else {
            lDateValid = false;
        }

        /*
        if (lDateValid == false) {
        // change date text field background color to pink
        aInputTextbox.style.background = "pink";
        }
        */
    }

    if (lDateValid == false) {
        // clear recorded date pattern
        gPreviousDatePattern = "";
    }

    return (lDateValid);
}


function updateTarget(targetName, selectedValue, selectedDisplayValue) {
    var w = getParentWindow()
    var target = w.document.getElementById(targetName);
    if (target != null) {
        if (target.tagName.toUpperCase() == 'SELECT') {
            // sam - always replace last dropdown list entry before selecting entry via Fev_SetFormControlValue()
            // because Firefox/Netscape does not support adding additional entries
            // var bSuccess = Fev_SetFormControlValue(target, selectedValue);
            var bSuccess = false;

            if (!bSuccess) {
                // sam - replace last dropdown list entry (instead inserting a new list item) because Firefox/Netscape
                // does not support adding additional entries
                if (insertListControlValue(w.document, target, selectedValue, selectedDisplayValue) ||
                    Fev_ReplaceLastListControlOption(target, selectedValue, selectedDisplayValue)) {
                    //try setting the selection again
                    bSuccess = Fev_SetFormControlValue(target, selectedValue);
                }
            }

            if (bSuccess) {
                if (target != null) {
                    if (navigator.appName == "Netscape") {
                        var myevent = w.document.createEvent("HTMLEvents")
                        myevent.initEvent("change", true, true)
                        target.dispatchEvent(myevent);
                    }
                    else { // IE
                        target.fireEvent('onchange');
                    }
                }
            }
        }
        else if (selectedValue == null && selectedDisplayValue == null) {
            w.document.getElementById(targetName).value = w.document.getElementById(targetName).value + " ";
        }
        else {
            w.updateQuickSelectorItem(targetName, selectedValue, selectedDisplayValue, "Replace", false);
        }
    }
    
    if (window.opener && !window.opener.closed) {
        submitNewWindowPage();
    }
    else {
        submitPopupPage(window.parent);
    }

}

/******************************************************************************************************/
/* sam - this function should only be used for IE (Firefox/Netscape does not support "options.add()") *
/******************************************************************************************************/
//Inserts the value into a list element, independent of the element's type.
function insertListControlValue(objDocument, objListElement, strValue, strText) {
    var strTagName = Fev_GetElementTagName(objListElement);
    switch (strTagName.toLowerCase()) {
        case "select":
            var objOption = objDocument.createElement("OPTION");
            objOption.value = strValue;
            objOption.text = strText;
            objListElement.options.add(objOption);
            return true;
            break;
        default:
            break;
    }
    return false;
}


/**************************************************************************************
*  Description : Global variables used by "JavaScript Date Selector" feature.        *
*  ISD Feature : "JavaScript Date Selector"                                          *
*  Authors     : Julian Robichaux, http://www.nsftools.com, and Samson Wong          *
**************************************************************************************/
var dateSelectorDivID = "dateSelector";
var iFrameDivID = "dateSelectoriframe";

var dayArrayShort = new Array('Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa');
var dayArrayMed = new Array('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
var dayArrayLong = new Array('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
var monthArrayShort = new Array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
var monthArrayMed = new Array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec');
var monthArrayLong = new Array('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');

// these variables define the date formatting we're expecting and outputting.
// If you want to use a different format by default, change the defaultDateSeparator
// and defaultDateFormat variables either here or on your HTML page.
var defaultDateSeparator = "/";        // common values would be "/" or "."
var defaultDateFormat = "mdy"    // valid values are "mdy", "dmy", and "ymd"
var dateSeparator = defaultDateSeparator;
var dateFormat = defaultDateFormat;
var mobileCurrentCalendarSender = null;


function mobileCalendarShownIntercept(e, h) {
    if (e == "years" || e == "months") {
        return;
    }

    mobileCurrentCalendarSender(e, h);
}



function mobileCalendarShown(sender, e) {
    mobileCurrentCalendarSender = sender;
    sender._switchMode = mobileCalendarShownIntercept;
}

/**************************************************************************************
*  Function    : getFieldDate()                                                      *
*  Description : Converts a string to a JavaScript Date objec                        *
*  Parameters  : dateString, date string to be converted into a JavaScript Date      *
*                    object.                                                         *
*  Returns:    : The date string as a JavaScript Date object.                        *
*  ISD Feature : "JavaScript Date Selector"                                          *
*  Authors     : Julian Robichaux, http://www.nsftools.com, and Samson Wong          *
**************************************************************************************/
function getFieldDate(dateString) {
    var dateVal;
    var dArray;
    var d, m, y;

    try {
        dArray = splitDateString(dateString);
        if (dArray) {
            switch (dateFormat) {
                case "dmy":
                    d = parseInt(dArray[0], 10);
                    m = parseInt(dArray[1], 10) - 1;
                    y = parseInt(dArray[2], 10);
                    break;
                case "ymd":
                    d = parseInt(dArray[2], 10);
                    m = parseInt(dArray[1], 10) - 1;
                    y = parseInt(dArray[0], 10);
                    break;
                case "mdy":
                default:
                    d = parseInt(dArray[1], 10);
                    m = parseInt(dArray[0], 10) - 1;
                    y = parseInt(dArray[2], 10);
                    break;
            }
            dateVal = new Date(y, m, d);
        } else if (dateString) {
            dateVal = new Date(dateString);
        } else {
            dateVal = new Date();
        }
    } catch (e) {
        dateVal = new Date();
    }

    return dateVal;
}


/**************************************************************************************
*  Function    : splitDateString()                                                   *
*  Description : Splits a date string into an array of elements, using common date   *
*                    separators.                                                     *
*  Parameters  : dateString, date string to be converted into a JavaScript Date      *
*                    object.                                                         *
*  Returns:    : The split date array, if operation successful; false, otherwise.    *
*  ISD Feature : "JavaScript Date Selector"                                          *
*  Authors     : Julian Robichaux, http://www.nsftools.com, and Samson Wong          *
**************************************************************************************/
function splitDateString(dateString) {
    var dArray;
    if (dateString.indexOf("/") >= 0)
        dArray = dateString.split("/");
    else if (dateString.indexOf(".") >= 0)
        dArray = dateString.split(".");
    else if (dateString.indexOf("-") >= 0)
        dArray = dateString.split("-");
    else if (dateString.indexOf("\\") >= 0)
        dArray = dateString.split("\\");
    else
        dArray = false;

    return dArray;
}


/**************************************************************************************
*  Function    : DisplayPopupWindowCallBackWith20()                                  *
*  Description : Displays a popup window with the content received from Ajax method  *
*		            of .NET 2.0 application											  *
*  Parameters  : result is the data recieved from ajax method                        *        
*  Assumptions : Only Ajax method will call this                                     *
*  ISD Feature :                                                                     *
*  Authors     : Sowmya.                                                             *
**************************************************************************************/

function PopupDisplayWindowCallBackWith20(result) {
    // The detailRollOverPopup() displays the content returned from the AJAX call in a popup window 
    // It accepts three parameters: 
    // - aTitle, string to be displayed in the title bar of the popup window.
    // - aContent, string containing HTML to be displayed in the body of the popup. 
    // - aPersist, boolean indicating whether the popup should remain visible even on mouseout.

    detailRolloverPopup(result[0], result[1], result[2], result[3], result[4], result[5], result[6]);
}

function FCKUpdateLinkedField(id) {
    try {
        if (typeof (FCKeditorAPI) == "object") {
            FCKeditorAPI.GetInstance(id).UpdateLinkedField();
        }
    }
    catch (err) {
    }
}

function setSearchBoxText(promptString, name) {
    var searchControl = document.getElementById(name);
    if (searchControl != null) {
        if (searchControl.value == "" || searchControl.value == promptString) {
            searchControl.value = promptString;
            searchControl.className = 'Search_InputHint';
            searchControl.blur();
        }
        else {
            searchControl.className = 'Search_Input';
        }
    }
}

function validateSelector(sender, args) {
    var val = document.getElementById(sender.id.replace('RequiredFieldValidator', '_Value')).value;
    var list = JSON.parse(val).List;
    if (val == "" || JSON.parse(val) == null || JSON.parse(val).List == null || JSON.parse(val).List.length == 0 || JSON.parse(val).List[0].Value == "--PLEASE_SELECT--") {
        args.IsValid = false;
    }
}

function selectorMultiSelectRowClick(pClickedRow, targetName, selectedValue, selectedDisplayValue, separator) {
    if (pClickedRow != null) {
        if ((pClickedRow.className == "QStr") || (pClickedRow.className == "QStrHighlighted")) {
            pClickedRow.className = "QStrSelected";
            updateQuickSelectorItem(targetName, selectedValue, selectedDisplayValue, "Add", false);
        }
        else {
            pClickedRow.className = "QStr";
            updateQuickSelectorItem(targetName, selectedValue, selectedDisplayValue, "Remove", false);
        }
    }
}

//function updateQuickSelectorItem(targetName, selectedValue, selectedDisplayValue) {
//    var w = getParentWindow();
//    w.UpdateTarget(targetName, selectedValue, selectedDisplayValue, "", "Replace");
//    ClosePopupPage();
//}

function getParentWindow() {
    var w;
    if (window.opener && !window.opener.closed) {
        w = window.opener;
    }
    else {
        w = window.parent;
    }
    return w;
}

function updateQuickSelectorItem(targetName, selectedValue, selectedDisplayValue, operation, sorted) {


    var newItem = new Object();
    newItem.Value = selectedValue;
    newItem.Text = selectedDisplayValue;
    var list = new Array();
    list[list.length] = newItem;
    updateQuickSelectorItems(targetName, list, operation, sorted);
}

var targetName;
function updateQuickSelectorItems(targetName, jsonListItems, operation, commit) {
    var valueHiddenCtrl = document.getElementById(targetName + "_Value");
    var list = JSON.parse(valueHiddenCtrl.value).List;
    if (operation == "Replace") {
        list = new Array();
    }
    if (operation == "Add" || operation == "Replace") {
        for (var i = 0; i < jsonListItems.length; i++) {
            var newItem = new Object();
            newItem.Value = jsonListItems[i].Value;
            newItem.Text = jsonListItems[i].Text;
            list[list.length] = newItem;
        }
    }
    else if (operation == "Remove") {
        var tempList = new Array();
        for (var i = 0; i < list.length; i++) {
            for (var j = 0; j < jsonListItems.length; j++) {
                if (list[i].Value != jsonListItems[j].Value || list[i].Text != jsonListItems[j].Text) {
                    var newItem = new Object();
                    newItem.Value = list[i].Value;
                    newItem.Text = list[i].Text;
                    tempList[tempList.length] = newItem;
                }
            }
        }
        list = tempList;
    }


    var listInStr = "{\"List\":" + JSON.stringify(list) + "}";
    if (commit) {
        PageMethods.SortListItems(listInStr, UpdateQSButtonAndClosePopup, null, targetName);
    }
    else {
        UpdateQSButton(listInStr, targetName);
    }

}

function UpdateQSButton(result, targetName) {
    var separator = ", ";
    var list = JSON.parse(result).List;
    var newVal = new Object();
    newVal.List = list;
    


    var valueHiddenCtrl = document.getElementById(targetName + "_Value");
    valueHiddenCtrl.value = JSON.stringify(newVal);

    var newDisplayText = "";
    for (var i = 0; i < list.length; i++) {
        newDisplayText += list[i].Text + separator;
    }
    newDisplayText = newDisplayText.substring(0, newDisplayText.length - separator.length);


    var linkCtrl = document.getElementById(targetName + "_Link");
    linkCtrl.title = newDisplayText;

    var fieldMaxLengthHiddenCtrl = document.getElementById(targetName + "_FieldMaxLength");
    var fieldMaxLength = parseInt(fieldMaxLengthHiddenCtrl.value)
    if (newDisplayText.length > fieldMaxLength) {
        linkCtrl.innerHTML = newDisplayText.substring(0, fieldMaxLength) + "...";
    }
    else {
        linkCtrl.innerHTML = newDisplayText;
    }

    if (linkCtrl.innerHTML == "") {
        linkCtrl.innerHTML = "&nbsp;&nbsp;&nbsp;&nbsp;";
    }


}


function UpdateQSButtonAndClosePopup(result, targetName) {
    var list = JSON.parse(result).List;
    var valueHiddenCtrl = document.getElementById(targetName + "_Value");

    var hasChanges = true;
    if (valueHiddenCtrl.value == "{\"List\":" + JSON.stringify(list) + "}") {
        hasChanges = false;
    }

	UpdateQSButton(result, targetName);

    if (hasChanges) {
        var target = document.getElementById(targetName);
        submitPopupPage(window);
    }
    else {
        closeChildModalPopup();
    }

}

function disableParent() {
    var lModalDiv = document.createElement("div");
    lModalDiv.id = "modalDivID";
    lModalDiv.className = "modal";
    document.body.appendChild(lModalDiv);
}

function enableParent() {
    var lModalDiv = document.getElementById("modalDivID");
    document.body.removeChild(lModalDiv);
}


function closePopupPage() {
    if (window.opener && !window.closed) {
        window.close();
    }
    else {
        var p = window.parent;
        var dialog = p.$("#dialog");
        dialog.css("display", "none");
        var lModalDiv = p.$("#modalDivID");
        lModalDiv.remove();
        var qsIframe = p.$("#QuickPopupIframe");
        qsIframe.prop("src", "");
    }
}

function closeChildModalPopup() {
    var p = window;
    var dialog = p.$("#dialog");
    dialog.css("display", "none");
    var lModalDiv = p.$("#modalDivID");
    lModalDiv.remove();
    var qsIframe = p.$("#QuickPopupIframe");
    qsIframe.prop("src", "");
}

function submitPopupPage(w) {
    if (w.autoPostBackForPopup) {
        w.__doPostBack(w.popupTarget.id, "");
    }
    var dialog = w.$("#dialog");
    dialog.css("display", "none");
    var lModalDiv = w.$("#modalDivID");
    lModalDiv.remove();
    var qsIframe = w.$("#QuickPopupIframe");
    qsIframe.prop("src", "");
}

function submitNewWindowPage() {
    var w = window.opener;
    if (w.autoPostBackForPopup) {
        w.__doPostBack(w.popupTarget.id, "");
    }
    window.close();
}

/**************************************************************************************
*  Function    : initializePopupPage()                                               *
*  Description : Initialize the link of the iframe and disable the background        *
*  Parameters  : src is the URL to be shown on popup                                 *
*  ISD Feature : Quick selector popup.  Button click popup                           *
*  Authors     : Yuenho Leung                                                        *
**************************************************************************************/
var gPopupX = 0;
var gPopupY = 0;
var autoPostBackForPopup;
var popupTarget;
var newWindow;
function initializePopupPage(ctrlToPostback, src, autopostback, evt) {
    autoPostBackForPopup = autopostback;
    popupTarget = ctrlToPostback;

    var qsIframe = $("#QuickPopupIframe");
    var dialog = $("#dialog");
    if (dialog.css("display") == "none") {
        gPopupX = gEventClientX;
        gPopupY = gEventClientY;

        qsIframe.prop("src", src);
        disableParent();
    }

    if (evt != null) {
        if (evt.cancelBubble != null) {
            evt.cancelBubble = true;
        }

        if (evt.stopPropagation != null) {
            evt.stopPropagation();
        }
    }
}

function initializePopupPage2(ctrlToPostback, src, autopostback, evt) {
    initializePopupPage(ctrlToPostback, src, autopostback, evt);
    openPopupPage("QPageSize", window);
}


function initializeNewWindow(ctrlToPostback, src, autopostback, evt) {
    autoPostBackForPopup = autopostback;
    popupTarget = ctrlToPostback;

    if (newWindow != null && !newWindow.closed) {
        newWindow.close();
    }
    newWindow = window.open(src, '_blank', 'width=900, height=700, resizable, scrollbars, modal=yes');


    if (evt != null) {
        if (evt.cancelBubble != null) {
            evt.cancelBubble = true;
        }

        if (evt.stopPropagation != null) {
            evt.stopPropagation();
        }
    }
}


/**************************************************************************************
*  Function    : openPopupPage()                                                   *
*  Description : Display quick selection or other popup with a specific width and height            *
*  Parameters  : width and height                                                    *
*  ISD Feature : Quick selector popup.  Quick Add button                             *
*  Authors     : Yuenho Leung                                                        *
**************************************************************************************/
function openPopupPage(cssClass, p) {
    if (p == null){    
        if (window.parent == window) {
            return;
        }
        p = window.parent;
    }
    var qsIframe = p.$("#QuickPopupIframe");
    var dialog = p.$("#dialog");
    if (dialog == null || qsIframe == null) {
        return;
    }

    // comparing the popup iframe's window on the parent page and the current window.  Check if they are the same.
    // if they are not the same, this indicates that this page is not opened as popup and should exist this function immediately/
    if (qsIframe[0] != null && qsIframe[0].contentWindow !== window) {
        return;
    }

    if (dialog.css("display") == "none" && qsIframe.prop("src") != "" && qsIframe.prop("src") != null) {
        dialog.css("display", "block");
    }
    dialog.attr('class', "QDialog " + cssClass);
     
    var width = "1050"
    var height = "500"
    
    for (var i = 0; i < document.styleSheets.length; i++) {
        var styleSheet = document.styleSheets[i];
        var cssRules = styleSheet.rules; // chrome, IE
        if (!cssRules) cssRules = styleSheet.cssRules; // firefox

        for (var j = 0; j < cssRules.length; j++) {
            var rule = cssRules[j];
            if (rule.selectorText == "." + cssClass) {
                try {
                    width = parseInt(rule.style.getPropertyValue('width').replace("px", ""), 10);
                }
                catch (e) {
                    try {
                        width = parseInt(rule.style.width.replace("px", ""), 10);
                    }
                    catch (e) {
                    }
                }
                try {
                    height = parseInt(rule.style.getPropertyValue('height').replace("px", ""), 10);
                }
                catch (e) {
                    try {
                    }
                    catch (e) {
                        height = parseInt(rule.style.height.replace("px", ""), 10);
                    }
                }
            }
        }
    }
    p.positionIFramePopup(dialog, width, height);

}

/**************************************************************************************
*  Function    : IsShowOnPopup()                                                   *
*  Description : Determine if the current page is shown on modal popup             *
*  ISD Feature : Quick selector popup.  Quick Add button                             *
*  Authors     : Yuenho Leung                                                        *
**************************************************************************************/
function IsShowOnPopup() {

    if (window.parent == window) {
        return false;
    }
    var p = window.parent;
    var qsIframe = p.$("#QuickPopupIframe");
    var dialog = p.$("#dialog");
    if (dialog == null || qsIframe == null) {
        return false;
    }

    // comparing the popup iframe's window on the parent page and the current window.  Check if they are the same.
    // if they are not the same, this indicates that this page is not opened as popup and should exist this function immediately/
    if (qsIframe[0] != null && qsIframe[0].contentWindow !== window) {
        return false;
    }
    return true;
}

/**************************************************************************************
*  Function    : positionIFramePopup()                                               *
*  Description : control the location of the iframe popup based on the clicked mouse *
*                    text link.  Locates the anchor in the center table cell and     *
*                    position                                                        *
*  Parameters  : None                                                                *
*  Assumptions : gEventClientX and gEventClientY were the clicked position           *
*  ISD Feature : Quick selector popup.  Quick Add button                             *
*  Authors     : Yuenho Leung                                                        *
**************************************************************************************/
function positionIFramePopup(aDialog, aWidth, aHeight) {
    var lPageOffsetX = 0;
    var lPageOffsetY = 0;
    var lClientHeight;
    var lClientWidth;
   
    // determine browser window scrolled position
    lPageOffsetX = $(this).scrollLeft();
    lPageOffsetY = $(this).scrollTop();

    // determine current browser window dimensions in IE
    if (document.all) {
        lClientHeight = document.documentElement.clientHeight;
        lClientWidth = document.documentElement.clientWidth;
    }
    else // in Firefox
    {
        lClientHeight = window.innerHeight;
        lClientWidth = window.innerWidth;
    }

    // alert("lClientWidth(" + lClientWidth + "),lClientHeight(" + lClientHeight + "),aCenterIt(" + aCenterIt + ")"); 

    // if popup larger than half browser window size...
    if ((aWidth > (lClientWidth / 2)) || (aHeight > (lClientHeight / 2))) {
        // center popup
        gPopupX = ((lClientWidth - aWidth) / 2) + lPageOffsetX;
        gPopupY = ((lClientHeight - aHeight) / 2) + lPageOffsetY; 
    }
    else { // position popup "next" to cursor click
        // determine mouse cursor position (top left, top right, bottom left, or bottom right) relative to current browser window
        var lRelativeX = gPopupX - lPageOffsetX;
        var lRelativeY = gPopupY - lPageOffsetY;
        var lInLeftHalf;
        var lInTopHalf;

        if (lRelativeX <= (lClientWidth / 2)) {
            if (!gRTL) {
                lInLeftHalf = true;
            }
            else {
                lInLeftHalf = false;
            }
        }
        else {
            if (!gRTL) {
                lInLeftHalf = false;
            }
            else {
                lInLeftHalf = true;
            }
        }

        if (lRelativeY <= (lClientHeight / 2)) {        
            lInTopHalf = true;
        }
        else {
            lInTopHalf = false;
        }

        // correct for IE RTL offset
        if ((document.all) && (gRTL)) {
            gPopupX -= (document.documentElement.scrollWidth - lClientWidth + 20);
        }

        // create appropriate html shell to display popup in correct location relative to mouse cursor position
        var lInnerHTML;
        if (lInLeftHalf && lInTopHalf) {
            // alert("detailRolloverPopup(inNW)");
            gPopupX = gPopupX - 20;
            if (gRTL) {
                gPopupX -= 300;
                
            }
            gPopupY = gPopupY + 10;
        }
        else if (!lInLeftHalf && lInTopHalf) {
            // alert("detailRolloverPopup(inNE)");
            gPopupX = gPopupX - aWidth + 20;
            if (gRTL) {
                gPopupX += 300;
            }
            gPopupY = gPopupY + 10;

        }
        else if (lInLeftHalf && !lInTopHalf) {
            // alert("detailRolloverPopup(inSW)");
            gPopupX = gPopupX - 20;
            if (gRTL) {
                gPopupX -= 300;
            }
            gPopupY = gPopupY - aHeight - 10;
        }
        else // (!lInLeftHalf && !InTopHalf)
        {
            // alert("detailRolloverPopup(inSE)");
            gPopupX = gPopupX - aWidth + 20;
            if (gRTL) {
                gPopupX += 300;
            }
            gPopupY = gPopupY - aHeight - 10;
        }
    }

    // never display off screen top and left
    if (gPopupX < 0) {
        gPopupX = 0;
    }
    if (gPopupY < 0) {
        gPopupY = 0;
    }

    aDialog.css("top", gPopupY + "px");
    aDialog.css("left", gPopupX + "px");
}


function replaceClassName(tagName, fromClassName, toClassName) {
    var elements = document.getElementsByTagName(tagName);
    for (var i = 0; i < elements.length; i++) {
        if (elements[i].className == fromClassName) {
            elements[i].className = toClassName;
        }
    }
}


/*************************************************************************************
*  Function    : QStrMouseover(), QStrMouseout()                                     *
*  Description : Workaround for Bug 91732 (In IE10, QuickSelector Row                *
*                   Selection/Highlighting Via CSS Hover Not Refreshing). These      *
*                   methods basically re-assigns the hover or selected class name to *
*                   "remind" (refresh) IE.                                           *
*  Parameters  : pRow, reference to currently moused-over/out row in QuickSelector   *
*  ISD Feature : Quick Selector popup                                                *
*  Author      : Samson Wong                                                         *
**************************************************************************************/
function QStrMouseover(pRow) {
    if (pRow != null) {
        if (pRow.className == 'QStr') {
            // re-assign row class for hover highlighting
            pRow.className = 'QStr';
        }
    }
}

function QStrMouseout(pRow) {
    if (pRow != null) {
        if (pRow.className == 'QStr') {
            // re-assign row class for hover highlighting
            pRow.className = 'QStr';
        } else if (pRow.className == 'QStrSelected') {
            // re-assign row class for selected highlighting
            pRow.className = 'QStrSelected';
        }
    }
}

/*************************************************************************************
*  Function    : AddRemoveValuesForMTM(), CheckMTMValInHiddenVar(),                  *  
*                AddMTMValInHiddenVar()                                              *
*  Description : Purpose of these methods is to add, remove the values in the hidden *
*                variables. Values are selected and unselected by the user on the UI.*
*  Parameters  : clicked checkbox, hidden variables, selected value                  *
*  ISD Feature : Many To Many Panel                                                  *
*  Author      : Ankit Vijayvargiya                                                  *
**************************************************************************************/
function AddRemoveValuesForMTM(pClickedCbx, addVarTargetName, removeVarTargetName, selectedValue) {
    if (pClickedCbx != null) {
        var newItem = new Object();
        newItem.Value = selectedValue;
        
        var list = new Array();
        list[list.length] = newItem;

        if (document.getElementById(pClickedCbx).checked == true) {
            if (CheckMTMValInHiddenVar(removeVarTargetName, list) == false) {
                AddMTMValInHiddenVar(addVarTargetName, list);
            }
        }
        else if (document.getElementById(pClickedCbx).checked == false) {
            if (CheckMTMValInHiddenVar(addVarTargetName, list) == false) {
                AddMTMValInHiddenVar(removeVarTargetName, list);
            }
        }
    }
}

function CheckMTMValInHiddenVar(targetName, list) {
    var valueHiddenCtrl = document.getElementById(targetName);
    var hasChanges = false;
    var jsonList = new Array();
    if (valueHiddenCtrl.value != null && valueHiddenCtrl.value != "") {
        jsonList = JSON.parse(valueHiddenCtrl.value).List;
    }
    
    if (jsonList.length == 0){
        return hasChanges
    }

    var newlist = new Array();
    for (var j = 0; j < list.length; j++) {
        for (var i = 0; i < jsonList.length; i++) {
            if (jsonList[i].Value != list[j].Value) {
                var newItem = new Object();
                newItem.Value = jsonList[i].Value;
                newlist[newlist.length] = newItem;
            }
        }
    }

    var newVal = new Object();
    newVal.List = newlist;
    if (valueHiddenCtrl.value != JSON.stringify(newVal)) {
        valueHiddenCtrl.value = JSON.stringify(newVal);
        hasChanges = true;
    }

    return hasChanges;
}


function AddMTMValInHiddenVar(targetName, list) {
    var valueHiddenCtrl = document.getElementById(targetName);
    
    var jsonList = new Array();
    if (valueHiddenCtrl.value != null && valueHiddenCtrl.value != "") {
        jsonList = JSON.parse(valueHiddenCtrl.value).List;
    }

    for (var i = 0; i < list.length; i++) {
        var newItem = new Object();
        newItem.Value = list[i].Value;
        jsonList[jsonList.length] = newItem;
    }

    var newVal = new Object();
    newVal.List = jsonList;
    valueHiddenCtrl.value = JSON.stringify(newVal);
}

/*************************************************************************************
*  Function    : function QPopupCreateHeader()                                       *  
*  Description : Retrieve the header of the first panel (of the contents of the      *
*                QuickPopup), and position it as the header of the QuickPopup.       *
*  Parameters  : none                                                                *
*  ISD Feature : QuickPopup With Show/Add/Edit Page Content                          *
*  Author      : Samson Wong                                                         *
**************************************************************************************/

function QPopupCreateHeader() {
    var lQSContainers = document.getElementsByClassName("QSContainer");
    if (lQSContainers.length > 0) {
        var lHeaders = lQSContainers[0].getElementsByClassName("dh");
        if (lHeaders.length > 0) {
            if (lHeaders[0].className == "dh") {
                // position header of first panel as header of QuickPopup
                lHeaders[0].className = "dh2";
            }
        }
    }
}
