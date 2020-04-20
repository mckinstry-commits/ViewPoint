SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHRHPClear]
/************************************************************************
* CREATED:    mh 11/7/05
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Clear out HRHP.  HRHP is a holding table for Employees/Resources
*	to be interfaced to PR/HR    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @clearall bYN, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @clearall = 'Y' 
		delete dbo.HRHP where HRCo = @hrco and Status = 1
	else	
		delete dbo.HRHP where HRCo = @hrco 

bspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRHPClear] TO [public]
GO
