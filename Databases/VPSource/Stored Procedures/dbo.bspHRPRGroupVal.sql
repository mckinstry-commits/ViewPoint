SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRPRGroupVal]
   /************************************************************************
   * CREATED:  mh 7/9/03    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Validate PR Group for HR.   
   *    
   *           
   * Notes about Stored Procedure
   *
   *	If PRCo is not passed in, get the PRCo form HRCO.
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @prco bCompany, @group bGroup = null, @msg varchar(60) output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @hrco is null
   	begin
   		select @msg = 'Missing HRCo', @rcode = 1
   		goto bspexit
   	end
   
     	if not exists(select 1 from HRCO where HRCo = @hrco)
   	begin
   	    select @msg = 'Invalid HR Company', @rcode = 1
   		goto bspexit
   	end
   
   	if @prco is null
   		select @prco = PRCo from HRCO where HRCo = @hrco
   
   	if @prco is null
   	begin
   		select @msg = 'Missing PR Company', @rcode = 1
   		goto bspexit
   	end
   
   	exec @rcode = bspPRGroupVal @prco, @group, @msg output
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPRGroupVal] TO [public]
GO
