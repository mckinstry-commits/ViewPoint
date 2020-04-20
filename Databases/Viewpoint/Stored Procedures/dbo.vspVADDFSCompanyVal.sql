SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspVADDFSCompanyVal]
/******************************************
 * Created: MWJ 11/8/06
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

(@hqco varchar(3) = '0', @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @hqco = '0'
	begin
	select @msg = 'Missing HQ Company#!', @rcode = 0
	goto bspexit
	end

if @hqco = '-1'
	begin
	select @msg = 'All companies!', @rcode = 0
	goto bspexit
	end

select @msg = Name from HQCO with (nolock) where @hqco = HQCo
if @@rowcount = 0
	begin
	select @msg = 'Not a valid HQ Company!', @rcode = 1
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVADDFSCompanyVal] TO [public]
GO
