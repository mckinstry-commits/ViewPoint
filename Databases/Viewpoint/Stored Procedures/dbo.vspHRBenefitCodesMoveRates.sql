SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRBenefitCodesMoveRates]
	/******************************************************
	* CREATED BY:	mh 2/6/2008 
	* MODIFIED By: 
	*
	* Usage:	Used by HR Benefit Codes to move New Rates
	*			to Old Rates.  Will move both Earnings and 
	*			Deduction/Liability rates from new to old.
	*	
	*
	* Input params:
	*				@hrco - Company
	*				@benefitcode - Benefit Code
	*
	* Output params:
	*	@msg		Error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@hrco bCompany, @benefitcode varchar(10), @msg varchar(100) output)
	as 
	set nocount on

	declare @rcode tinyint
   	
	select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company.', @rcode = 1
		goto vspexit
	end

	if @benefitcode is null
	begin
		select @msg = 'Missing Benefit Code.', @rcode = 1
		goto vspexit
	end

	update dbo.HRBI set OldRate = NewRate, UpdatedYN = 'N' where HRCo = @hrco and BenefitCode = @benefitcode
	 
	vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRBenefitCodesMoveRates] TO [public]
GO
