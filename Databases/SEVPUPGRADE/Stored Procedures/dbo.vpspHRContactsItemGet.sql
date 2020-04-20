SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspHRContactsItemGet]
/************************************************************
* CREATED:     SDE 6/5/2006
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the HR Resource Contacts based on the HRCo and HRRef
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    HRCo, HRRef        
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@HRCo bCompany, @HRRef bHRRef,
	@KeyID int = Null)
AS
	SET NOCOUNT ON;

SELECT KeyID, HRCo, HRRef, Seq, Contact, Relationship, HomePhone, WorkPhone, Address, City, State, Zip, Notes, UniqueAttchID, CellPhone 

FROM HREC with (nolock)

where HRCo = @HRCo and HRRef = @HRRef 
and KeyID = IsNull(@KeyID, KeyID)






GO
GRANT EXECUTE ON  [dbo].[vpspHRContactsItemGet] TO [VCSPortal]
GO
