SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspHRAssignedAssetsItemGet]
/************************************************************
* CREATED:     SDE 5/31/2006
* MODIFIED:		6/7/07	CHS  
*
* USAGE:
*   Returns the HR Resource Assigned Assets based on the HRCo and HRRef
*	Joins Description from HRCA
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

SELECT HRTA.KeyID, HRTA.HRCo, HRTA.HRRef, HRTA.DateOut, HRTA.Asset, HRTA.DateIn, HRTA.MemoOut, HRTA.MemoIn, HRCA.AssetDesc  

FROM HRTA with (nolock) left join HRCA on HRTA.HRCo = HRCA.HRCo 

where HRTA.HRCo = @HRCo and HRTA.HRRef = @HRRef and HRTA.Asset = HRCA.Asset 
and HRTA.DateIn is Null
and HRTA.KeyID = IsNull(@KeyID, HRTA.KeyID)






GO
GRANT EXECUTE ON  [dbo].[vpspHRAssignedAssetsItemGet] TO [VCSPortal]
GO
