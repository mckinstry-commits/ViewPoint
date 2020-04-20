SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRPCPosCodeDescVal]
/************************************************************************
* CREATED:	mh 1/6/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Return Position Code Description    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @positioncode varchar(10), @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int
    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company.', @rcode = 1
		goto vspexit
	end

	if @positioncode is null	
	begin
		select @msg = 'Missing Position Code.', @rcode = 1
		goto vspexit
	end

	select @msg = h.JobTitle from dbo.HRPC h where h.HRCo = @hrco and h.PositionCode = @positioncode

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRPCPosCodeDescVal] TO [public]
GO
