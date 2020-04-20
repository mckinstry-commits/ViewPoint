SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspHRDependentsItemGet]
/************************************************************
* CREATED:		6/6/2006	SDE
* MODIFIED:		6/7/07		CHS
* MODIFIED:		6/12/07		CHS
*
* USAGE:
*   Returns the HR Resource Dependents based on the HRCo and HRRef
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    HRCo, HRRef        
*   
************************************************************/
(@HRCo bCompany, @HRRef int,
	@KeyID int = Null)
AS
	SET NOCOUNT ON;

SELECT 
d.KeyID, d.HRCo, d.HRRef,

cast(d.Seq as varchar(5)) as 'Seq', 

d.Name, d.Relationship, d.BirthDate, d.SSN, d.Sex, 
d.HistSeq, d.Address, d.City, d.State, d.Zip, d.Phone, 
d.WorkPhone, d.Notes, d.UniqueAttchID

FROM HRDP d with (nolock)

where HRCo = @HRCo and HRRef = @HRRef
and KeyID = IsNull(@KeyID, KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspHRDependentsItemGet] TO [VCSPortal]
GO
