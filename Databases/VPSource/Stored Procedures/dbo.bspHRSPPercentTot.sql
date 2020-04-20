SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspHRSPPercentTot]
   /***********************************************************
    * CREATED BY: ae 6/8/99 
    * MODIFIED By : mh 2/1/2005 - Issue 26992 added @PercentTot output parameter
    *
    * USAGE:
    * This procedure (bspHRSPPercentTot) returns the total percent of increase (or decrease) for a given Resource 
    * and effective date.
    *
    * INPUT PARAMETERS
    *   @HRCo - HR Company	
    *   @HRRef - HR Reference Number
        @EffectiveDate - Effective Date of Salary Change
    *  
    * OUTPUT PARAMETERS
    *	 @PercentTot - Total Percent Change
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
   	(@HRCo bCompany = null, @HRRef int, @EffectiveDate bDate, @PercentTot bPct = null output, @msg varchar(60) = null output )
   as
   
   set nocount on
   
   	declare @rcode int
   
   	select @rcode = 0
   
   	if @HRCo is null
   	begin
   		select @msg = 'Missing HR Company', @rcode = 1
   		goto bspexit
   	end
   
   	if @HRRef is null
   	begin
   		select @msg = 'Missing HR Reference Number', @rcode = 1
   		goto bspexit
   	end
   
   	if @EffectiveDate is null
   	begin
   		select @msg = 'Missing Effective Date',@rcode = 1 
   		goto bspexit
   	end
   
   	
   	select @PercentTot =  isnull(sum(PctIncrease),0 * 100)
   	from dbo.HRSP with (nolock)
   	where HRCo = @HRCo and HRRef = @HRRef and EffectiveDate = @EffectiveDate
   
   				
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRSPPercentTot] TO [public]
GO
