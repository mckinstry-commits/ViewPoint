var lastFocusedControlId;

/*
* Handles page loaded event, finds first control on the page to set focus on and calles focus control on this control.
* This handler assigned to handle Sys.WebForms.PageRequestManager.getInstance().add_pageLoaded event on MasterPage
*/
function pageLoadedHandler(sender, args) {
// If you do not want focus set to the first element, comment out the next line.
   setTimeout("setFocus()",1000);
}

function setFocus(ctrl) {
    //check if it is the popup opened on the iframe in InfiniePagination control 
    if (IsShowOnPopup()) {
        if (window.parent.frameElement != null) {
            iframeName = window.parent.frameElement.id;
            if (iframeName.indexOf("Infiniteframe") >= 0) {
                return;
            }
        }
    }
    

    if (Fev_FocusOnFirstFocusableFormElement_FromSetFocus == null || typeof (Fev_FocusOnFirstFocusableFormElement_FromSetFocus) == "undefined") {
        return;
    }
    if (ctrl == null || typeof (ctrl) == "undefined" || ctrl == "") {
        lastFocusedControlId = Fev_FocusOnFirstFocusableFormElement_FromSetFocus();
    }
    else {
        lastFocusedControlId = ctrl;
    }
    if (lastFocusedControlId != null && typeof(lastFocusedControlId) !== "undefined" && lastFocusedControlId != "") {
        var newFocused = $get(lastFocusedControlId);
       if (newFocused) {
            focusControl(newFocused);
        }
    }
    //remove handler to ensure execution only on initial page load
    Sys.WebForms.PageRequestManager.getInstance().remove_pageLoaded(pageLoadedHandler1);
}


/*
* Sets the focus to the target control.
*/
function focusControl(targetControl) {
    if (typeof (targetControl) == "string") {
        targetControl = document.getElementById(targetControl);
    }
    if (Sys.Browser.agent === Sys.Browser.InternetExplorer) {
        var focusTarget = targetControl;
        targetControl.focus();

        if (focusTarget && (typeof(focusTarget.contentEditable) !== "undefined")) {
               oldContentEditableSetting = focusTarget.contentEditable;
               focusTarget.contentEditable = false;
            }
           else {
               focusTarget = null;
            }  
            if (focusTarget) {
            focusTarget.contentEditable = oldContentEditableSetting;
        }  
    }
    else {
        targetControl.focus();
    }
}

