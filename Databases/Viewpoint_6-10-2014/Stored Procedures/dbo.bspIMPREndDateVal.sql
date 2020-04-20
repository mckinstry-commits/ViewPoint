SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMPREndDateVal]
   /************************************************************************
   * CREATED:  MH 5/30/02    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *  Validate PREndDate entered into grid of IMPRGroup.    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @prco is null
   	begin
   		select @msg = 'Missing PR Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @prgroup is null
   	begin
   		select @msg = 'Missing PR Group.', @rcode = 1
   		goto bspexit
   	end
   
   	if @prenddate is null
   	begin
   		select @msg = 'Missing PR End Date.', @rcode = 1
   		goto bspexit
   	end
   
   	if not exists(select PREndDate
   			from PRPC 
   			where PRCo = @prco and PRGroup = @prgroup and Status = 0 and 
   			PREndDate = @prenddate)
   	begin
   		select @msg = 'Invalid PR Pay Period Ending Date.', @rcode = 1
   		goto bspexit
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMPREndDateVal] TO [public]
GO
