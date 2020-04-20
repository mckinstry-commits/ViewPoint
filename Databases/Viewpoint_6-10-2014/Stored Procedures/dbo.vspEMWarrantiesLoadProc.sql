SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspEMWarrantiesLoadProc]
/********************************************************
* CREATED BY: 	TRL 12/3/2008 Issue 130859
* MODIFIED BY:
**
* USAGE:
* 	Retrieves the Material Group from HQCO and Material Valid and 
*	Default Warranty Start Date option from from EMCO.
*
* INPUT PARAMETERS:
*	HQ Company number
*
* OUTPUT PARAMETERS:
*	Material Group from HQCO
*   Material Valid Flag from EMCO
*   Default Warranty Start Date Option
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@emco bCompany = 0, @MatlGroup tinyint = null output, @matlvalid varchar(1) = 'Y' output,
@defaultwarrantystartdate varchar(1) output, @msg varchar(255) output)
as 
set nocount on

declare @rcode int

select @rcode = 0

if @emco is null
begin
	select @msg = 'Missing EM Company', @rcode = 1
	goto vspexit
end

---- validate EM company
select @matlvalid=MatlValid,@defaultwarrantystartdate = IsNull(DefaultWarrantyStartDate,'I')
from dbo.EMCO with (nolock) where EMCo = @emco
if @@rowcount = 0
begin
	select @msg = 'EM Company: ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
	goto vspexit
end

---- get material groupd
select @MatlGroup = MatlGroup 
from dbo.HQCO with (nolock) where HQCo = @emco
if @@rowcount  = 0
begin
	select @msg = 'HQ company does not exist.', @rcode=1
	goto vspexit
end

if @MatlGroup is Null 
begin
	select @msg = 'Material group not setup for company ' + isnull(convert(varchar(3),@emco),''), @rcode=1
	goto vspexit
end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWarrantiesLoadProc] TO [public]
GO
