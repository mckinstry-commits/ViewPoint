SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRPRCoVal]
/************************************************************************
* CREATED:  mh 10/1/2007    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@prco bCompany, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if exists(select 1 from PRCO where PRCo = @prco)
	begin
		select Name from HQCO where HQCo = @prco
	end
	else
	begin
		select @msg = 'Invalid PR Company ', @rcode = 1
	end

vspexit:

      return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRPRCoVal] TO [public]
GO
