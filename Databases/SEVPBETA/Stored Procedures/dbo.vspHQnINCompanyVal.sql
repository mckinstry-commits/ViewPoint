SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQnINCompanyVal]
/******************************************
 * Created: TRL 01/21/07
 * Modified: 
 *
 * Usage: HQ Material Insert Locations
 * Purpose: Validates IN Company and Matl Group
 *
 * Inputs:
 *	@inco		Company # 
 *  @matlgroup  MatlGroup
 *
 * Ouput:
 *	@msg		Company name or error message
 * 
 * Return code:
 *	0 = success, 1 = failure
 *
 ***********************************************/

(@inco bCompany = null, @matlgroup bGroup = null, @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @inco is null
	begin
	select @msg = 'Missing IN Company!', @rcode = 1
	goto vspexit
	end

if @matlgroup is null
	begin
	select @msg = 'Missing Material Group', @rcode = 1
	goto vspexit
	end

--Validate IN Company
select @msg = Name from dbo.HQCO with (nolock) where HQCo=@inco 
if @@rowcount = 0
	begin
	select @msg = 'Not a valid IN Company!', @rcode = 1
	end
--Validate Matl Group is same IN Companys musthave same MatlGroup
select @msg = Name from dbo.HQCO with (nolock) where HQCo=@inco and MatlGroup=@matlgroup
if @@rowcount = 0
	begin
	select @msg = 'HQ Material Group is not used by the Selected IN Company!', @rcode = 1
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQnINCompanyVal] TO [public]
GO
