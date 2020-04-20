SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE  proc [dbo].[vspEMAllocationInitList]
/****************************************************************************
 * Created By:	TRL 06/26/208  Issue 126591
 * Modified By:	
 *
 *
 *
 * USAGE:
 * Used to populate EM Allocation Init list views for Available and Included.
 *
 * INPUT PARAMETERS:
 * EM Company
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@emco bCompany = null,  @alloccode tinyint = null, @exists bYN = null, @tabletype varchar(4) = null)
as
set nocount on

declare @rcode int,@emgroup bGroup

select @rcode = 0

select @emgroup = EMGroup from HQCO with (nolock)where HQCo = @emco

IF @exists = 'Y'
BEGIN
	--EM Cost Types
	If @tabletype = 'EMAT'
	begin
		select dbo.bfMuliPartFormat(EMCT.CostType,'3R') as 'Cost Type', EMCT.Description as 'Description'
		from dbo.EMCT  with (nolock) 
		left join dbo.EMAT  with (nolock) on EMCT.EMGroup = EMAT.EMGroup and EMCT.CostType = EMAT.CostType 
		where EMAT.EMCo = @emco and EMAT.AllocCode = @alloccode and  EMAT.EMGroup = @emgroup and isnull(EMAT.CostType,'') <> ''
		goto vspexit
	end

	--EM Revenue Codes
	If @tabletype = 'EMAV'
	begin
		select EMRC.RevCode, EMRC.Description 
		from dbo.EMRC  with (nolock) 
		left join dbo.EMAV with (nolock)on EMRC.EMGroup = EMAV.EMGroup and EMRC.RevCode = EMAV.RevCode
		where EMAV.EMCo = @emco and EMAV.AllocCode = @alloccode and EMRC.EMGroup = EMAV.EMGroup and isnull(EMAV.RevCode,'') <> ''
		goto vspexit
	end

	--EM Equipment
	If @tabletype = 'EMAE'
	begin
		select EMEM.Equipment, EMEM.Description
		from dbo.EMEM  with (nolock) 
		left join dbo.EMAE with (nolock)on EMEM.EMCo = EMAE.EMCo and EMEM.Equipment = EMAE.Equipment and EMAE.AllocCode = @alloccode
		where EMEM.EMCo = @emco  and isnull(EMAE.Equipment,'') <> ''
		goto vspexit
	end

	--EM Departments
	If @tabletype = 'EMAD'
	begin
		select EMDM.Department, EMDM.Description
		from dbo.EMDM  with (nolock) 
		left join dbo.EMAD with (nolock)on EMDM.EMCo = EMAD.EMCo and EMDM.Department = EMAD.Department and EMAD.AllocCode = @alloccode
		where EMDM.EMCo = @emco  and isnull(EMAD.Department,'') <> ''
		goto vspexit
	end
	--EM Categories
	If @tabletype = 'EMAG'
	begin
		select EMCM.Category, EMCM.Description
		from dbo.EMCM  with (nolock) 
		left join dbo.EMAG with (nolock)on EMCM.EMCo = EMAG.EMCo and EMCM.Category = EMAG.Category and EMAG.AllocCode = @alloccode
		where EMAG.EMCo = @emco  and isnull(EMAG.Category,'') <> ''
		goto vspexit
	end
END

IF @exists = 'N'
BEGIN
	--EM Cost Types
	If @tabletype = 'EMAT'
	begin
		select dbo.bfMuliPartFormat(EMCT.CostType,'3R') as 'Cost Type', EMCT.Description
		from dbo.EMCT with (nolock) 
		Left join dbo.EMAT with (nolock)on EMCT.EMGroup = EMAT.EMGroup and EMCT.CostType = EMAT.CostType 
		and EMAT.EMCo = @emco and EMAT.AllocCode = @alloccode
		where  EMCT.EMGroup = @emgroup and IsNull(EMAT.CostType,'') = ''
		goto vspexit
	end

	--EM Revenue Codes
	If @tabletype = 'EMAV'
	begin
		select EMRC.RevCode, EMRC.Description 
		from dbo.EMRC  with (nolock) 
		Left Outer join dbo.EMAV with (nolock)on EMRC.EMGroup = EMAV.EMGroup and EMRC.RevCode = EMAV.RevCode
		and EMAV.EMCo = @emco and EMAV.AllocCode = @alloccode
		where EMRC.EMGroup=@emgroup and IsNull(EMAV.RevCode,'')=''
		goto vspexit
	end

	--EM Equipment	
	If @tabletype = 'EMAE'
	begin
		select EMEM.Equipment, EMEM.Description
		from dbo.EMEM with (nolock) 
		Left join dbo.EMAE with (nolock)on EMEM.EMCo = EMAE.EMCo and EMEM.Equipment = EMAE.Equipment and EMAE.AllocCode=@alloccode
		where EMEM.EMCo = @emco and IsNull(EMAE.AllocCode,'') = ''
		goto vspexit
	end

	--EM Departments
	If @tabletype = 'EMAD'
	begin
		select EMDM.Department, EMDM.Description
		from dbo.EMDM  with (nolock) 
		Left join dbo.EMAD with (nolock)on EMDM.EMCo = EMAD.EMCo and EMDM.Department = EMAD.Department	and EMAD.AllocCode=@alloccode
		where EMDM.EMCo = @emco and IsNull(EMAD.AllocCode,'') = ''
		goto vspexit
	end

	--EM Categories
	If @tabletype = 'EMAG'
	begin
		select EMCM.Category, EMCM.Description
		from dbo.EMCM  with (nolock) 
		Left join dbo.EMAG with (nolock)on EMCM.EMCo = EMAG.EMCo and EMCM.Category = EMAG.Category and EMAG.AllocCode=@alloccode
		where EMCM.EMCo = @emco and IsNull(EMAG.AllocCode,'') = ''
		goto vspexit
	end
END

vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMAllocationInitList] TO [public]
GO
