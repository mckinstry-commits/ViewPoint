SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspHREarningsCodesItemGet]
/************************************************************
* CREATED:     SDE 6/1/2006
* MODIFIED:		6/7/07	CHS
*
* USAGE:
*   Returns the HR Resource Earnings based on the HRCo, HRRef and BenefitCode
*	Joins Description from PREC
*	Joins Description from HQFC for Frequency Description
*	Joins Description from HQIC for InsCode Description
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    HRCo, HRRef, BenefitCode        
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(@HRCo bCompany, @HRRef int, @BenefitCode  varchar(10),
	@KeyID int = Null )
AS
	SET NOCOUNT ON;

select e.KeyID, e.HRCo, e.HRRef, e.BenefitCode, e.DependentSeq, e.EarnCode, 
	e.AutoEarnSeq, e.Department, d.Description as 'DepartmentDescription', e.InsCode, 
	e.GLCo, h.Name as 'GLCompanyName', e.RateAmount, e.AnnualLimit, e.Frequency, 
	e.ReadyYN, e.StdHours, e.Hours, e.PaySeq, e.UniqueAttchID, 
	p.Description, f.Description as 'FreqDescription', i.Description as 'InsCodeDescription',
	
	case e.StdHours
		when 'Y' then 'Yes'
		when 'N' then 'No'
		end as StandardHoursDescription,
		
	case e.ReadyYN
		when 'Y' then 'Yes'
		when 'N' then 'No'
		end as ReadyYNDescription
		

from HRBE e with (nolock)
	left join PREC p with (nolock) on e.HRCo = p.PRCo and e.EarnCode = p.EarnCode
	left join HQFC f with (nolock) on e.Frequency = f.Frequency
	left join HQIC i with (nolock) on e.InsCode = i.InsCode
	left join PRDP d with (nolock) on e.HRCo = d.PRCo and e.Department = d.PRDept
	left join HQCO h with (nolock) on e.GLCo = h.HQCo
	
where e.HRCo = @HRCo and e.HRRef = @HRRef and e.BenefitCode = @BenefitCode
and e.KeyID = IsNull(@KeyID, e.KeyID)






GO
GRANT EXECUTE ON  [dbo].[vpspHREarningsCodesItemGet] TO [VCSPortal]
GO
