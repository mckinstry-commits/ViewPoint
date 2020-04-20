SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRBenCodeValwithEligDate]
   /************************************************************************
   * CREATED:  mh 5/21/03    
   * MODIFIED: mh 23347 - Remove UpdatePRYN   
   *
   * Purpose of Stored Procedure
   *
   *	Validate a Benefit Code and return the default eligibility date.
   *	Used in HRResourceBenefits.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@HRCo bCompany = null, @HRRef bHRRef = null, @BenCode varchar(10) = null, 
   	@eligdate bDate output,@msg varchar(60) output)
   
   as
   set nocount on
   
       declare @rcode int, @eligbasis varchar(20), @eligperiod int, @hiredate bDate, @updatepryn bYN
   
       select @rcode = 0
   
   	exec @rcode = bspHRBenCodeVal @HRCo, @BenCode, @updatepryn, @msg output
   
   	if @rcode = 0
   	begin
   		--get the elig period and days
   		select @eligbasis = lower(EligBasis), @eligperiod = EligPeriod
   		from HRBC 
   		where HRCo = @HRCo and BenefitCode = @BenCode
   
   		select @hiredate = HireDate from HRRM where HRCo = @HRCo and HRRef = @HRRef
   
   		if @eligbasis is not null and @eligperiod is not null
   		begin
   		
   			if @eligbasis = 'days'
   			begin
   				select @eligdate = dateadd(Day, @eligperiod, @hiredate)
   				goto bspexit
   			end
   
   			if @eligbasis = 'months'
   			begin
   				select @eligdate = dateadd(Month, @eligperiod, @hiredate)
   				goto bspexit
   			end
   
   			if @eligbasis = 'years'
   			begin
   				select @eligdate = dateadd(Year, @eligperiod, @hiredate)
   				goto bspexit
   			end
   
   		end
   		else
   			if @hiredate is not null
   				select @eligdate = @hiredate
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBenCodeValwithEligDate] TO [public]
GO
