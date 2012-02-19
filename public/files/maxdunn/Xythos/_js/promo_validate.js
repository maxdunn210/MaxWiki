<!--

////////////////////////////////////////////////////////////
// trim
////////////////////////////////////////////////////////////
function trim(str) {
    str.replace(/^\s*/, '').replace(/\s*$/, '');
    return str;
}

////////////////////////////////////////////////////////////
// validate
////////////////////////////////////////////////////////////
function validate(ob) {
	var errorMsg = "";
    var isValid = true;
	
	// validate first name
    if(trim(ob.elements['requestor_first_name'].value) == "") {
        isValid = false;
        errorMsg += FirstName;
    }

    // validate last name
    if(trim(ob.elements['requestor_last_name'].value) == "") {
        isValid = false;
        errorMsg += LastName;
    }
	
	// validate Title
    if(trim(ob.elements['requestor_title'].value) == "") {
        isValid = false;
        errorMsg += Title;
    }
	
	 // validate Email
    if(trim(ob.elements['email'].value) == "") {
        isValid = false;
        errorMsg += Email;
    }

    // validate Company Name
    if(trim(ob.elements['company_name'].value) == "") {
        isValid = false;
        errorMsg += companyName;
    }
	
	// validate Phone
    if(trim(ob.elements['phone1'].value) == "") {
        isValid = false;
        errorMsg += Phone;
    }



    // validate Phone
    //if(trim(ob.elements['phone1'].value) == "") {
        //isValid = false;
        //errorMsg += Phone;
    //}


	
    // display error message
    if(isValid == false) {
        errorMsg = message1 + message2 + errorMsg;
        alert(errorMsg);
    }

    return isValid;
}

//-->
