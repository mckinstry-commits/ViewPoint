SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspHRContactsItemDelete]
/************************************************************
* CREATED:     SDE 6/5/2006
* MODIFIED:    
*
* USAGE:
*   Deletes a HR Resource Contact
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*            
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
	@Original_HRCo bCompany,
	@Original_HRRef bHRRef,
	@Original_Seq smallint,
	@Original_Address varchar(60),
	@Original_CellPhone bPhone,
	@Original_City varchar(30),
	@Original_Contact varchar(30),
	@Original_HomePhone bPhone,
	@Original_Relationship varchar(30),
	@Original_State bState,
	@Original_UniqueAttchID uniqueidentifier,
	@Original_WorkPhone bPhone,
	@Original_Zip bZip
)
AS
	SET NOCOUNT OFF;
DELETE FROM HREC WHERE (HRCo = @Original_HRCo) AND (HRRef = @Original_HRRef) AND (Seq = @Original_Seq) AND (Address = @Original_Address OR @Original_Address IS NULL AND Address IS NULL) AND (CellPhone = @Original_CellPhone OR @Original_CellPhone IS NULL AND CellPhone IS NULL) AND (City = @Original_City OR @Original_City IS NULL AND City IS NULL) AND (Contact = @Original_Contact) AND (HomePhone = @Original_HomePhone OR @Original_HomePhone IS NULL AND HomePhone IS NULL) AND (Relationship = @Original_Relationship OR @Original_Relationship IS NULL AND Relationship IS NULL) AND (State = @Original_State OR @Original_State IS NULL AND State IS NULL) AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL) AND (WorkPhone = @Original_WorkPhone OR @Original_WorkPhone IS NULL AND WorkPhone IS NULL) AND (Zip = @Original_Zip OR @Original_Zip IS NULL AND Zip IS NULL)



GO
GRANT EXECUTE ON  [dbo].[vpspHRContactsItemDelete] TO [VCSPortal]
GO
