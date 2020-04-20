SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRPRCoGet]
   /************************************************************************
   * CREATED:	mh 8/6/03    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *	Get the PR Company set up in HRCO    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @prco bCompany output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @hrco is null
   	begin
   		select @msg = 'Missing HR Company', @rcode = 1
   		goto bspexit
   	end
   
   	select @prco = PRCo from HRCO where HRCo = @hrco
   
   	if @prco is null
   		select @prco = -1
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRPRCoGet] TO [public]
GO
