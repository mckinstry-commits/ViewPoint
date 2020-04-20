SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspHQCompanyVal]
/******************************************
* Created:
* Modified: JRK 03/08/06 Use view instead of table.
*			GG 08/16/07 - hanlde -1 for 'all company' security entries
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

(@hqco smallint = null, @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @hqco is null
	begin
	select @msg = 'Missing HQ Company#!', @rcode = 1
	goto bspexit
	end

-- -1 used for 'all company' security entries
if @hqco = -1
	begin
	select @msg = 'All Companies'
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
GRANT EXECUTE ON  [dbo].[vspHQCompanyVal] TO [public]
GO
