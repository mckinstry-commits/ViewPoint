SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRAutoLeaveLoad]
/************************************************************************
* CREATED:	mh 12/4/06    
* MODIFIED: EN 7/24/07  added prco validation and error msg
*
* Purpose of Stored Procedure
*
*    Load procedure for PR Auto Leave
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@prco bCompany, @prglco bCompany output, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int, @source bSource, @hqrcode int

    select @rcode = 0, @hqrcode = 0, @source = 'PR Leave'

	select @prglco=GLCo from dbo.PRCO with (nolock) where PRCo=@prco
	if @@ROWCOUNT = 0
		begin
		select @msg = 'Company# ' + convert(varchar,@prco) + ' not setup in PR', @rcode = 1
  		goto vspexit
  		end

	/* get the latest open batch for this company and source */

	if exists(select 1 from bHQBC where Co = @prco and Source = @source and InUseBy is null and Status = 0)
	begin
		select @msg = 'Open or unprocessed Leave batches exist.  Cannot continue.', @rcode = 1
	end


vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRAutoLeaveLoad] TO [public]
GO
