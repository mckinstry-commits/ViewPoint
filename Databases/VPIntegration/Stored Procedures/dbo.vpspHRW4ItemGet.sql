SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspHRW4ItemGet]
/************************************************************
* CREATED:     SDE 5/30/2006
* MODIFIED:		6/7/07	CHS 
*
* USAGE:
*   Returns the HR Resource W4 based on the HRCo and HRRef
*	Joins Description from PRDL
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
(@HRCo bCompany, @HRRef int,
	@KeyID int = Null)
AS
	SET NOCOUNT ON;

select HRWI.KeyID, HRWI.HRCo, HRWI.HRRef, HRWI.DednCode, HRWI.FileStatus, HRWI.RegExemp, HRWI.AddionalExemp, HRWI.OverrideMiscAmtYN, 
	HRWI.MiscAmt1, HRWI.MiscFactor, HRWI.AddonType, HRWI.AddonRateAmt, HRWI.UniqueAttchID, PRDL.Description 

from HRWI with (nolock) inner join PRDL with (nolock) 

on PRDL.PRCo = HRWI.HRCo and PRDL.DLCode = HRWI.DednCode

where HRWI.HRCo = @HRCo and HRWI.HRRef = @HRRef and PRDL.DLType = 'D' 
and PRDL.Method = 'R' 
and HRWI.KeyID = IsNull(@KeyID, HRWI.KeyID)






GO
GRANT EXECUTE ON  [dbo].[vpspHRW4ItemGet] TO [VCSPortal]
GO
