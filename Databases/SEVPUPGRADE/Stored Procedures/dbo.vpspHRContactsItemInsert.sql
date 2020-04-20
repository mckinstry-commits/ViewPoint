SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROCEDURE [dbo].[vpspHRContactsItemInsert]
/************************************************************
* CREATED:		SDE 6/5/2006
* MODIFIED:		1/3/2008	CHS 
*				9/15/2011 AMR - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Inserts a new HR Resource Contact
*	
*
* CALLED FROM:
*	ViewpointCS Portal (for HR Contact List and Details)
*
************************************************************/
(
	@HRCo bCompany,
	@HRRef bHRRef,
	@Seq smallint,
	@Contact varchar(30),
	@Relationship varchar(30),
	@HomePhone bPhone,
	@WorkPhone bPhone,
	@Address varchar(60),
	@City varchar(30),
	@State bState,
	@Zip bZip,
	@Notes VARCHAR(MAX),
	@UniqueAttchID uniqueidentifier,
	@CellPhone bPhone
)
AS

	SET NOCOUNT ON;



set @Seq = (Select IsNull((Max(Seq)+1),1) from HREC with (nolock) 
						where HRCo = @HRCo and HRRef = @HRRef)



INSERT INTO HREC(HRCo, HRRef, Seq, Contact, Relationship, HomePhone, WorkPhone, Address, City, 
	State, Zip, Notes, UniqueAttchID, CellPhone) 


VALUES (@HRCo, @HRRef, @Seq, @Contact, @Relationship, @HomePhone, @WorkPhone, @Address, @City,
	@State, @Zip, @Notes, @UniqueAttchID, @CellPhone);

DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspHRContactsItemGet @HRCo, @HRRef, @KeyID




GO
GRANT EXECUTE ON  [dbo].[vpspHRContactsItemInsert] TO [VCSPortal]
GO
