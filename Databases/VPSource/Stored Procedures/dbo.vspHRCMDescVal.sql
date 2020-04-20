SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRCMDescVal]
/************************************************************************
* CREATED:	mh 1/9/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Return Code Description     
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @code varchar(10), @codetype char(1), @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company.', @rcode = 1
		goto vspexit
	end

	if @code is null
	begin
		select @msg = 'Missing Code.', @rcode = 1
		goto vspexit
	end

	select @msg = h.Description from dbo.HRCM h where h.HRCo = @hrco and h.Code = @code and h.Type = @codetype


vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRCMDescVal] TO [public]
GO
