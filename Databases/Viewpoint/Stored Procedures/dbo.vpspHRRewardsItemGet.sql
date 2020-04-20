SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspHRRewardsItemGet]
/************************************************************
* CREATED:     SDE 6/1/2006
* MODIFIED:		6/7/07	CHS 
*
* USAGE:
*   Returns the HR Resource Rewards based on the HRCo and HRRef 
*	Joins Description from HRCM
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

select HRRD.KeyID, HRRD.HRCo, HRRD.HRRef, HRRD.Seq, HRRD.Date, HRRD.Code, HRRD.Description, HRRD.RewardAmt, HRRD.Reason, HRRD.HistSeq, HRRD.Notes, 
	HRRD.UniqueAttchID, HRCM.Description as 'CodeDescription'
 
from HRRD with (nolock)

left join HRCM with (nolock) on HRRD.HRCo = HRCM.HRCo and HRRD.Code = HRCM.Code

where HRRD.HRCo = @HRCo and HRRD.HRRef = @HRRef
and HRRD.KeyID = IsNull(@KeyID, HRRD.KeyID)






GO
GRANT EXECUTE ON  [dbo].[vpspHRRewardsItemGet] TO [VCSPortal]
GO
