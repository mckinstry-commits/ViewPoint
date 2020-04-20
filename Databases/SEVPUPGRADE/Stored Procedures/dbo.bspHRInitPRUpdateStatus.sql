SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRInitPRUpdateStatus]
   /************************************************************************
   * CREATED:	mh 10/2/2004    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    Update the ready Status code in HRHP.
   *    
   *           
   * Notes about Stored Procedure
   * 
   *	Created per issue 25519
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany = null, @prco bCompany = null, @hrref bHRRef = null, @employee bEmployee = null,
   	@direction char(1) = null, @status char(1) = null, @msg varchar(80) = '*' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @hrco is null
   	begin
   		select @msg = 'Missing HR Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @prco is null
   	begin
   		select @msg = 'Missing PR Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @direction is null
   	begin
   		select @msg = 'Missing HR/PR update direction.', @rcode = 1
   		goto bspexit
   	end
   
   	if @status is null
   	begin
   		select @msg = 'Missing update status.  Must be ''Y'' or ''N''', @rcode = 1
   		goto bspexit
   	end
   
   	if @direction = 'P'
   		Update dbo.bHRHP 
   		set Status = @status 
   		where HRCo = @hrco and PRCo = @prco and Employee = @employee
   
   	if @direction = 'H'
   		Update dbo.bHRHP 
   		set Status = @status 
   		where HRCo = @hrco and PRCo = @prco and HRRef = @hrref
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRInitPRUpdateStatus] TO [public]
GO
