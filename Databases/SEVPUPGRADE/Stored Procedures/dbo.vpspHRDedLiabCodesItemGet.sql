SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspHRDedLiabCodesItemGet]
 /************************************************************
 * CREATED:     SDE 6/1/2006
 * MODIFIED:    chs 9/12/06
 * MODIFIED:		6/7/07	CHS
 *
 * USAGE:
 *   Returns the HR Resource Deduction / Liabilities based on the HRCo, HRRef and BenefitCode
 *	Joins Description from PRDL
 *	Joins Description from HQFC for Frequency Description
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
 
select 
 l.KeyID, l.HRCo, l.HRRef, l.BenefitCode, l.DependentSeq, l.DLCode, 
 l.DLType, l.EmplBasedYN, l.Frequency, l.ProcessSeq,
  
 	case l.OverrideCalc 
 		when 'N' then 'No' 
 		when 'R' then 'Rate'
 		when 'A' then 'Fixed Amount'
 		else l.OverrideCalc 
 		end as 'OverrideCalc',
 		
 	l.RateAmt, l.GLCo, l.OverrideGLAcct, l.OverrideLimit, 
	l.VendorGroup, l.Vendor, l.APTransDesc, 
 	l.ReadyYN, l.UniqueAttchID, p.Description, 
	p.RateAmt1, h.Description as 'FreqDescription',

		case l.DLType
			when 'D' then 'Deduction'
			when 'L' then 'Liability'
			end as 'TypeDescription',
			
		case l.EmplBasedYN
			when 'Y' then 'Yes'
			when 'N' then 'No'
			end as 'EmployeeBased',
			
		case l.ReadyYN
			when 'Y' then 'Yes'
			when 'N' then 'No'
			end as 'ReadyDescription'
 
 from HRBL l with (nolock)
 
 left join PRDL p with (nolock) on l.HRCo = p.PRCo and l.DLCode = p.DLCode
 left join HQFC h with (nolock) on l.Frequency = h.Frequency
 
 where l.HRCo = @HRCo and l.HRRef = @HRRef and l.BenefitCode = @BenefitCode
	and l.KeyID = IsNull(@KeyID, l.KeyID)
 
 
 



GO
GRANT EXECUTE ON  [dbo].[vpspHRDedLiabCodesItemGet] TO [VCSPortal]
GO
