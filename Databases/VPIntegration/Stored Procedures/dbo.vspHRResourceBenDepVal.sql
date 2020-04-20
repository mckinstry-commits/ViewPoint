SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRResourceBenDepVal]
	/******************************************************
	* CREATED BY:	mh 2/13/2008 
	* MODIFIED By: 
	*
	* Usage:
	*			Validates Dependent Seq.  Also checks
	*			related grid tables HRBE and HRBL for
	*			BenefitOptions that are not specified.
	*
	* Input params:
	*	
	*			@hrco - Company
	*			@hrref - Resource
	*			@seq - Dependent Seq
	*			@benefitcode - Benefit Code
	*			@benopts - flag to determine if BenefitOption
	*				has been set in HRBL or HRBE
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
	(@hrco bCompany, @hrref varchar(15), @benefitcode varchar(10), @seq smallint, @beneopts smallint output, @bendlopts smallint output, @msg varchar(100) output)

	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0, @beneopts = 0, @bendlopts = 0

	if @hrco is null
	begin
		select @msg = 'Missing HRCo', @rcode = 1
		goto vspexit
	end

	if @hrref is null
	begin
		select @msg = 'Missing HRRef', @rcode = 1
		goto vspexit
	end

	if @seq is null
	begin
		select @msg = 'Missing Dependent Seq', @rcode = 1
		goto vspexit
	end

	if @seq = 0 
	begin
		select @msg = 'Same as Resource Number'
	end
	else
	begin
		if not exists(select 1 from dbo.HRDP (nolock) where HRCo = @hrco and HRRef = @hrref and Seq = @seq)
		begin
			select @msg = 'Dependent not set up in HR Resource Dependents.', @rcode = 1
			goto vspexit
		end
		else	
		begin
			select @msg = [Name] from dbo.HRDP (nolock) where HRCo = @hrco and HRRef = @hrref and Seq = @seq
		end
	end

	if exists(Select 1 from dbo.HRBE (nolock) where HRCo = @hrco and HRRef = @hrref and BenefitCode = @benefitcode
	and DependentSeq = 0)
	begin
		if not exists (Select 1 from dbo.HRBE (nolock) where HRCo = @hrco and HRRef = @hrref and BenefitCode = @benefitcode
		and DependentSeq = 0 and BenefitOption is null)
		begin
			select @beneopts = 0
		end
		else
		begin
			select @beneopts = 1
		end
	end

	if exists(select 1 from dbo.HRBL (nolock) where HRCo = @hrco and HRRef = @hrref and BenefitCode = @benefitcode
	and DependentSeq = 0)
	begin
		if not exists(select 1 from dbo.HRBL (nolock) where HRCo = @hrco and HRRef = @hrref and BenefitCode = @benefitcode
		and DependentSeq = 0 and BenefitOption is null)
		begin
			select @bendlopts = 0
		end
		else
		begin
			select @bendlopts = 1
		end
	end
	 
	vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRResourceBenDepVal] TO [public]
GO
