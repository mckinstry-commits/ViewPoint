SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspHQCompanyVal]
/******************************************
 * Created:
 * Modified: JRK 03/08/06 Use view instead of table.
 * JRK 07/27/06 Change it back to use the table so it won't be affected by data security.
 *
 * Purpose: Validates HQ Company number
 *
 * Inputs:
 *	@hqco		Company # 
 *
 * Ouput:
 *	@msg		Company name or error message
 * 
 * Return code:
 *	0 = success, 1 = failure
 *
 ***********************************************/

(@hqco bCompany = 0, @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @hqco = 0
	begin
	select @msg = 'Missing HQ Company#!', @rcode = 1
	goto bspexit
	end

select @msg = Name from bHQCO with (nolock) where @hqco = HQCo
if @@rowcount = 0
	begin
	select @msg = 'Not a valid HQ Company!', @rcode = 1
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQCompanyVal] TO [public]
GO
