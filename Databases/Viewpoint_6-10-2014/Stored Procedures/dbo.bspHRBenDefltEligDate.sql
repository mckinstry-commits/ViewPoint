SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRBenDefltEligDate]
   /************************************************************************
   * CREATED: MH 10/12/01    
   * MODIFIED:	mh 23347 - Remove UpdatePRUN    
   *
   * Purpose of Stored Procedure
   *
   *	Get default elig date for a benefit.    
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
   
       declare @rcode int, @eligbasis varchar(20), @eligperiod int, @hiredate bDate, @UpdatePRYN bYN
   
       select @rcode = 0
   
   	exec @rcode = bspHRBenCodeVal @HRCo, @BenCode, @UpdatePRYN output, @msg output
   
   	if @rcode = 0
   	begin
   		--get the elig period and days
   		select @eligbasis = lower(EligBasis), @eligperiod = EligPeriod
   		from HRBC 
   		where HRCo = @HRCo and BenefitCode = @BenCode
   
   		if @eligbasis is not null and @eligperiod is not null
   		begin
   		
   			select @hiredate = HireDate from HRRM where HRCo = @HRCo and HRRef = @HRRef
   			
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
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBenDefltEligDate] TO [public]
GO
