SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRSTDescVal]
/************************************************************************
* CREATED:	mh 1/9/06     
* MODIFIED:	    
*
* Purpose of Stored Procedure
*
*	Return Status Code Description    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @statuscode varchar(10), @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company.', @rcode = 1
		goto vspexit
	end

	if @statuscode is null
	begin
		select @msg = 'Missing Status Code.', @rcode = 1
		goto vspexit
	end

	select @msg = h.Description from dbo.HRST h where h.HRCo = @hrco and h.StatusCode = @statuscode

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRSTDescVal] TO [public]
GO
