SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRResourceBenOptionDflt]
	/******************************************************
	* CREATED BY:	mh 02/06/2008 
	* MODIFIED By:  mh 04/10/2009 - Added frequency output parameter.
	*		TJL 06/25/10 - Issue #139274, Default "Override Calculation" Option to "N-Calc Amt" when Benefit Code Rates = 0.0000
	*
	* Usage:	Validates BenefitOption entered in HR Resource Benefits 
	*			Ded/Liab or Earnings grid against HRBI (HR Benefit Codes).   
	*			If setup in HRBI use the effective date passed in to return  
	*			old or new rate.
	*
	* Input params:
	*
	*		@hrco - HR Company
	*		@benefitcode - Benefit Code
	*		@hrref - Resource
	*		@edltype - EDLType.  Proc can be used for both Earnings or DL
	*		@edlcode - EDLCode
	*		@benefitoption - Option entered by user
	*		@effectivedate - Effective date from HREB
	*
	* Output params:
	*
	*	@rate - Old or New rate in HRBI based on @effectivedate
	*	@freq - Frequency for EDL Code assigned in HRBI
	*	@msg - Error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@hrco bCompany, @benefitcode varchar(10), @hrref bHRRef, @edltype char(1),
	@edlcode bEDLCode, @benefitoption smallint, @effectivedate bDate, 
	@rate bUnitCost output, @freq bFreq output, @overridecalc char(1) output, @msg varchar(100) output)

	as 
	set nocount on
	declare @rcode tinyint
   	
	select @rcode = 0, @rate = 0, @overridecalc = 'R'

	--validate params
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

	if @hrref is null
	begin
		select @msg = 'Missing Resource to update.', @rcode = 1
		goto vspexit
	end

	if @edltype is null
	begin
		select @msg = 'Missing EDLType.', @rcode = 1
		goto vspexit
	end

	if @edlcode is null
	begin
		select @msg = 'Missing EDLCode.', @rcode = 1
		goto vspexit
	end

	if @benefitoption is null
	begin
		select @msg = 'Missing Benefit Option to update.', @rcode = 1
		goto vspexit
	end

	if @effectivedate is null
	begin
		--if effectivedate is null assume current date.
		select @effectivedate = getdate()
	end

	--Validate Benefit Option exists in HRBI and return rate.
	if exists(select 1 from dbo.HRBI (nolock) where HRCo = @hrco and BenefitCode = @benefitcode and
		BenefitOption = @benefitoption and EDLType = @edltype and EDLCode = @edlcode)
	begin

--Rate defaulted from HRBI will be determined as follows:
--	*  If @effectivedate < HRBI.EffectiveDate return OldRate
--  *  If @effectivedate >= HRBI.EffectiveDate and HRBI.UpdatedYN = 'N' return OldRate (Assume new rates are in but not updated)
--  *  If @effectivedate >= HRBI.EffectiveDate and HRBI.UpdatedYN = 'Y' return NewRate.

		select @overridecalc =  case when (i.OldRate = 0 and i.NewRate = 0) then 'N' else 'R' end,
			@rate = isnull(case when @effectivedate < i.EffectiveDate then i.OldRate 
			when not (@effectivedate < i.EffectiveDate) and i.UpdatedYN = 'N' then i.OldRate else i.NewRate end,0),
			@freq = Frequency 
		from dbo.HRBI i		
		where i.HRCo = @hrco and i.BenefitCode = @benefitcode and i.EDLType = @edltype and i.EDLCode = @edlcode and
		i.BenefitOption = @benefitoption
	end
	else
	begin
		select @msg = 'Benefit Code Option is not set up in HR Benefit Codes', @rcode = 1
	end

	vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHRResourceBenOptionDflt] TO [public]
GO
