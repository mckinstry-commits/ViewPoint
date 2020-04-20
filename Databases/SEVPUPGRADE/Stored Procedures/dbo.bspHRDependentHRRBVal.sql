SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRDependentHRRBVal]
   /************************************************************************
   * CREATED:	MH    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Validate HRDependent Sequence in addition to providing 
   *	a default eligibility date for the benefit.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   	(@hrco bCompany = null, @hrref varchar(15), @benefitcode varchar(10), @seq varchar(15), 
   	@refout int output, @defaultelig bDate output, @msg varchar(75) output)
   
   as
   	set nocount on
   
   	declare @rcode int, @eligbasis varchar(20), @eligperiod int, 
   	@hiredate bDate
   
      	select @rcode = 0
   
   
   if @hrco is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @hrref is null
   	begin
   	select @msg = 'Missing HR Resource Number', @rcode = 1
   	goto bspexit
   	end
   
   if @seq is null
   	begin
   	select @msg = 'Missing HR Depedent Sequence Number', @rcode = 1
   	goto bspexit
   	end
   
   	exec @rcode = bspHRDependentVal @hrco, @hrref, @seq, @refout output, @msg output
   
   	if @rcode <> 0
   		goto bspexit
   	else
   		begin
   			select @eligbasis = EligBasis, @eligperiod = EligPeriod 
   			from HRBC 
   			where HRCo = @hrco and BenefitCode = @benefitcode			
   
   			select @hiredate = HireDate 
   			from HRRM 
   			where HRCo = @hrco and HRRef = @hrref
   
   			if upper(@eligbasis) = 'YEARS'
   				select @defaultelig = DateAdd(year, @eligperiod, @hiredate)
   
   			if upper(@eligbasis) = 'MONTHS'
   				select @defaultelig = DateAdd(month, @eligperiod, @hiredate)
   
   			if upper(@eligbasis) = 'DAYS'
   				select @defaultelig = DateAdd(day, @eligperiod, @hiredate)
   
   		end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRDependentHRRBVal] TO [public]
GO
