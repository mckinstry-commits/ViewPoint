//
// .NET Validator Control functions
//


function Fev_TextBoxMaxLengthValidatorEvaluateIsValid(objSource, objArguments) {
	var ctv = Fev_GetControlToValidate(objSource);
	var value = objArguments.Value;
	if (value == '') objArguments.IsValid = true;
	else if (ctv && ctv.MaxLength)
		objArguments.IsValid = !((ctv.MaxLength > 0) && (ctv.MaxLength < value.length));
	else objArguments.IsValid = true;
}


//
// Utility functions
//


function Fev_GetControlToValidate(validator) {
    if (validator && validator.controltovalidate)
		return Fev_GetControlToValidateById(validator.controltovalidate); 
	return null;
}

function Fev_GetControlToValidateById(id) {
    var control;
    control = document.all[id];
    if (typeof(control.value) == "string") {
        return control;
    }
    if (typeof(control.tagName) == "undefined" && typeof(control.length) == "number") {
        var j;
        for (j=0; j < control.length; j++) {
            var inner = control[j];
            if (typeof(inner.value) == "string" && (inner.type != "radio" || inner.status == true)) {
                return inner;
            }
        }
    }
    else {
        return Fev_GetControlToValidateRecursive(control);
    }
    return "";
}

function Fev_GetControlToValidateRecursive(control)
{
    if (typeof(control.value) == "string" && (control.type != "radio" || control.status == true)) {
        return control;
    }
    var i;
    for (i = 0; i < control.children.length; i++) {
        var child = Fev_GetControlToValidateRecursive(control.children[i]);
        if (child != null) return child;
    }
    return null;
}

