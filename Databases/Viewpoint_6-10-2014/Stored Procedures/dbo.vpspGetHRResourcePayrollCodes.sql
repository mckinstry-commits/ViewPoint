SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE dbo.vpspGetHRResourcePayrollCodes
/************************************************************
* CREATED:     SDE 10/12/2005
* MODIFIED:    
*
* USAGE:
*   Returns the PayrollCodes for a specific HRCo, HRRef and 
*	BenefitCode.  
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
(@HRCo bCompany, @HRRef int, @BenefitCode varchar(10))
AS
	SET NOCOUNT ON;
select c.Description, d.RateAmt as 'RateAmount', f.Description as 'Frequency'
	from HRBL d 
	inner join HRBC c on d.HRCo = c.HRCo and d.BenefitCode = c.BenefitCode
	inner join HQFC f on d.Frequency = f.Frequency
	where d.HRCo = @HRCo and d.HRRef = @HRRef and d.BenefitCode = @BenefitCode  
union
select p.Description, e.RateAmount, f.Description as 'Frequency'
	FROM bHRBE e 
	inner join PREC p on e.HRCo = p.PRCo and e.EarnCode = p.EarnCode
	inner join HQFC f on e.Frequency = f.Frequency
	where e.HRCo = @HRCo and e.HRRef = @HRRef  and e.BenefitCode = @BenefitCode  


GO
GRANT EXECUTE ON  [dbo].[vpspGetHRResourcePayrollCodes] TO [VCSPortal]
GO
