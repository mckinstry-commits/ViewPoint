SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspHRSkillsItemGet]
/************************************************************
* CREATED:     SDE 5/31/2006
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the HR Resource Skills based on the HRCo and HRRef
*	Gets the Description from HRCM
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

select HRRS.KeyID, HRRS.HRCo, HRRS.HRRef, HRRS.Code, HRCM.Description, HRRS.CertDate, HRRS.ExpireDate, 
	HRRS.SkillTester, HRRS.HistSeq, HRRS.Notes, HRRS.UniqueAttchID, HRRS.Type 

FROM HRRS with (nolock) left join HRCM with (nolock) on HRRS.HRCo = HRCM.HRCo and HRRS.Code = HRCM.Code 

where HRRS.HRCo = @HRCo and HRRS.HRRef = @HRRef and HRCM.Type ='S'
and HRRS.KeyID = IsNull(@KeyID, HRRS.KeyID)






GO
GRANT EXECUTE ON  [dbo].[vpspHRSkillsItemGet] TO [VCSPortal]
GO
