SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRResourceBenOptCheck]
	/******************************************************
	* CREATED BY:  MH  
	* MODIFIED By: MH 07/23/08 - 129085
	*
	* Usage:
	*	
	*
	* Input params:
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@hrco bCompany, @hrref bHRRef, @benefitcode varchar(10), @optnotselcnt int output, @msg varchar(100) output)

	as 
	set nocount on
	declare @rcode int, @dloptnotselcnt int, @eoptnotselcnt int, @dlcodesnotinhrbi int, @ecodesnotinhrbi int
   	
	select @rcode = 0, @optnotselcnt = 0, @dloptnotselcnt = 0, @eoptnotselcnt = 0,
	@dlcodesnotinhrbi = 0, @ecodesnotinhrbi = 0

	select @eoptnotselcnt = count(1) 
	from HRBE (nolock) where HRCo = @hrco and HRRef = @hrref and BenefitCode = @benefitcode and 
	DependentSeq = 0 and BenefitOption is null

	select @dloptnotselcnt = count(1) 
	from HRBL (nolock) where HRCo = @hrco and HRRef = @hrref and BenefitCode = @benefitcode and 
	DependentSeq = 0 and BenefitOption is null

--	select count(1) 'DLCodes not in HRBI'
--	from HRBL l (nolock) 
--	right join HRBI i on l.HRCo = i.HRCo and l.BenefitCode = i.BenefitCode and l.DLCode = i.EDLCode and
--	l.DLType = i.EDLType and l.DLCode = i.EDLCode
--	where l.HRCo = @hrco and l.HRRef = @hrref and l.BenefitCode = @benefitcode and 
--	l.DependentSeq = 0 and l.BenefitOption is null

	select @dlcodesnotinhrbi = count(1)
	from HRBL l (nolock) 
	where l.HRCo = @hrco and l.HRRef = @hrref and l.BenefitCode = @benefitcode and 
	l.DependentSeq = 0 and l.BenefitOption is null and l.DLCode not in 
	(select EDLCode from HRBI where HRCo = @hrco and BenefitCode = @benefitcode and 
	EDLType <> 'E')

	select @ecodesnotinhrbi = count(1)
	from HRBE l (nolock) 
	where l.HRCo = @hrco and l.HRRef = @hrref and l.BenefitCode = @benefitcode and 
	l.DependentSeq = 0 and l.BenefitOption is null and l.EarnCode not in 
	(select EDLCode from HRBI where HRCo = @hrco and BenefitCode = @benefitcode and 
	EDLType = 'E')

	select @optnotselcnt = @eoptnotselcnt + @dloptnotselcnt - @ecodesnotinhrbi - @dlcodesnotinhrbi
	 
	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRResourceBenOptCheck] TO [public]
GO
