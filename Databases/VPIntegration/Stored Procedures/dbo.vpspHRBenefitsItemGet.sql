SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspHRBenefitsItemGet]
/************************************************************
* CREATED:     SDE 5/30/2006
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the HR Resource Benefits based on the HRCo and HRRef
*	Joins HRBC for Benefit Description
*	Joins HRDP for Dependent Name
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

select HREB.KeyID, HREB.HRCo, HREB.HRRef, HREB.BenefitCode, HREB.DependentSeq, HREB.EligDate, HREB.ReminderDate, HREB.ActiveYN, HREB.EffectDate, HREB.EndDate, 
	HREB.ReinstateYN, HREB.ReinstateDate, HREB.SmokerYN, HREB.ID, HREB.EmployerCost, HREB.HistSeq, --HREB.UpdatePRYN, 
HREB.UpdatedYN, HREB.Notes,
	HREB.CafePlanYN, HREB.CafePlanAmt, HREB.BatchId, HREB.InUseBatchId, HREB.InUseMth, HREB.Ben1, HREB.Rel1, HREB.Ben2, HREB.Rel2, HREB.UniqueAttchID,
	HRBC.Description, HRDP.Name

from HREB with (nolock) 
left join HRBC with (nolock) on HREB.HRCo = HRBC.HRCo and HREB.BenefitCode = HRBC.BenefitCode
left join HRDP with (nolock) on HREB.HRCo = HRDP.HRCo and HREB.HRRef = HRDP.HRRef and HREB.DependentSeq = HRDP.Seq

where HREB.HRCo = @HRCo and HREB.HRRef = @HRRef  
and HREB.KeyID = IsNull(@KeyID, HREB.KeyID)






GO
GRANT EXECUTE ON  [dbo].[vpspHRBenefitsItemGet] TO [VCSPortal]
GO
