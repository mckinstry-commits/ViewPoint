SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspEMWarrantiesPartCodeVal]
/***********************************************************
* CREATED BY:		CHS	07/10/2008
* MODIFIED By:		TRL 01/21/2008 Issue 130859 add (nolocks) 
*
* USAGE:
* 	Uses EM Parts Code to returns EM Part Description and 
*	HQ Material code and description.
*
* INPUT PARAMETERS:
*		@matlgroup bGroup
*		@equipment bEquip
*		@emco bCompany
*		@partcode bMatl
*
* OUTPUT PARAMETERS:
*		@description bDesc
*		@hqmaterial bMatl
*		@hqmatldesc bDesc
*	
*****************************************************/

(@matlgroup bGroup = null, @equipment bEquip = null, @emco bCompany = null, 
	@partcode bMatl = null, @description bDesc = null output,
	@hqmaterial bMatl = null output, @hqmatldesc bDesc = null output)

as
set nocount on

declare @rcode int

set @rcode = 0


	select 
		@description = isnull(e.Description, m.Description),
		@hqmaterial = e.HQMatl, 
		@hqmatldesc = m.Description
	from dbo.EMEP e with (nolock)
		left join dbo.HQMT m with (nolock) on 
			m.MatlGroup = @matlgroup and 
			m.Material = e.HQMatl
	where e.EMCo = @emco and e.Equipment = @equipment and e.PartNo = @partcode

	if @@rowcount = 0
	begin
		select 
			@description = m.Description,
			@hqmaterial = @partcode, 
			@hqmatldesc = m.Description
		from dbo.HQMT m with (nolock)
		where m.MatlGroup = @matlgroup and m.Material = @partcode
	end


return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWarrantiesPartCodeVal] TO [public]
GO
