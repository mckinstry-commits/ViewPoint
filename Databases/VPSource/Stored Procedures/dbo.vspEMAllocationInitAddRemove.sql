SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************************************/
CREATE proc [dbo].[vspEMAllocationInitAddRemove]
/****************************************************************************
 * Created By:	TRL 06/18/2008  Issue 126591
 * Modified By:	
 *
 *
 * USAGE: Used by form EM Allocation Init
 * Used to Add Cost Type or Remove all Cost Types for a given Allocation code.
 *
 * INPUT PARAMETERS:
 * EM Company, Allocation Code, DeleteYN, Table type vpcolumn
 * 
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@emco bCompany = null,  @alloccode tinyint = null, @deleteyn bYN = null, @tabletype varchar(4)=null,@vpcolumn varchar(10) = null)
as
set nocount on

declare @rcode int,@emgroup bGroup

select @rcode = 0

select @emgroup = EMGroup
from HQCO with (nolock)
where HQCo = @emco

If @deleteyn = 'Y'
BEGIN
	--EM Cost Types
	If @tabletype = 'EMAT'
	begin
		delete EMAT 
		where EMCo = @emco and  AllocCode = @alloccode and  EMGroup = @emgroup;
	end

	--EM Revenue Codes
	If @tabletype = 'EMAV'
	begin
		delete EMAV 
		where EMCo = @emco and  AllocCode = @alloccode and  EMGroup = @emgroup;
	end

	--EM Equipment
	If @tabletype = 'EMAE'
	begin
		delete EMAE
		where EMCo = @emco and  AllocCode = @alloccode
	end

	--EM Departments
	If @tabletype = 'EMAD'
	begin
		delete EMAD
		where EMCo = @emco and AllocCode =  @alloccode
	end

	--EM Categories	
	If @tabletype = 'EMAG'
	begin
		delete EMAG 
		where EMCo = @emco and AllocCode =  @alloccode
	end
END
If @deleteyn = 'N'
BEGIN
--EM Cost Types
	If @tabletype = 'EMAT'
	begin
		If not exists (select top 1 1 from dbo.EMAT with(nolock)
					Where EMCo=@emco and AllocCode=@alloccode and CostType=IsNull(convert(tinyint,@vpcolumn),0) and EMGroup = @emgroup)
		begin
			Insert Into dbo.EMAT (EMCo,AllocCode,CostType,EMGroup)
			Select @emco,@alloccode,convert(tinyint,@vpcolumn),@emgroup
		end
	end

	--EM Revenue Codes
	If @tabletype = 'EMAV'
	begin
		If not exists (select top 1 1 from dbo.EMAV with(nolock)
					Where EMCo=@emco and AllocCode=@alloccode and RevCode=@vpcolumn and EMGroup = @emgroup)
		begin
			Insert Into dbo.EMAV (EMCo,AllocCode,RevCode,EMGroup)
			Select @emco,@alloccode,@vpcolumn,@emgroup
		end
	end

	--EM Equipment
	If @tabletype = 'EMAE'
	begin
		If not exists (select top 1 1 from dbo.EMAE with(nolock) Where EMCo=@emco and AllocCode=@alloccode and Equipment=@vpcolumn)
		begin
			Insert Into dbo.EMAE (EMCo,AllocCode,Equipment)
			Select @emco,@alloccode,@vpcolumn
		end
	end

	--EM Departments
	If @tabletype = 'EMAD'
	begin
		If not exists (select top 1 1 from dbo.EMAD with(nolock) Where EMCo=@emco and AllocCode=@alloccode and Department=@vpcolumn)
		begin
			Insert Into dbo.EMAD (EMCo,AllocCode,Department)
			Select @emco,@alloccode,@vpcolumn
		end
	end

	--EM Categories	
	If @tabletype = 'EMAG'
	begin
		If not exists (select top 1 1 from dbo.EMAG with(nolock) Where EMCo=@emco and AllocCode=@alloccode and Category=@vpcolumn)
		begin
			Insert Into dbo.EMAG (EMCo,AllocCode,Category)
			Select @emco,@alloccode,@vpcolumn
		end
	end
END

vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMAllocationInitAddRemove] TO [public]
GO
