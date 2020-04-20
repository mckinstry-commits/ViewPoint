SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHRPosCodeVal]
   /************************************************************************
   * CREATED:   mh 12/23/02    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Validate an HRPosition Code against HRPC
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@HRCo bCompany = null, @Code varchar(10), @msg varchar(60) output)
   
   as
set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @Code is null
   	begin
   	select @msg = 'Missing Code', @rcode = 1
   	goto bspexit
   	end

   select @msg = Description from HRPC where HRCo = @HRCo and PositionCode = @Code
	if @@rowcount = 0
       begin
   	select @msg = 'Not a valid HR Position Code.', @rcode = 1
       goto bspexit
       end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPosCodeVal] TO [public]
GO
