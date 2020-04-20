SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMEquipmentHQMatlVal]
/*************************************
* Created by: TRL 01/16/08 
* Modified by:
*
* Usage: Validates Fule Part Code in EM Equipment
* Pass:
*	EMCo
*	Equipment
*	MatlGroup
*	Material
*	
* Success returns:
*	0 and Description from HQMT or EMEP (Equipment Parts)
*
* Error returns:
*	1 and error message
**************************************/
 (@emco bCompany, @equipment bEquip, @matlgroup bGroup ,@material bMatl ,@hqmaterial bMatl output, @msg varchar(255) output)
as

set nocount on
declare @rcode int

select @rcode = 0

--Does Material Require Valid Matl
if @emco is null
begin
   	select @msg = 'Missing EM Company', @rcode = 1
   	goto vspexit
end

if IsNull(@equipment,'') = ''
begin
   	select @msg = 'Missing Equipment', @rcode = 1
   	goto vspexit
end

if @matlgroup is null
begin
   	select @msg = 'Missing Material Group', @rcode = 1
   	goto vspexit
end
   
if IsNull(@material,'') =''
begin
   	select @msg = 'Missing Material', @rcode = 1
   	goto vspexit
end
   
--Check for Material Code in EM Equipment Parts
If exists (select top 1 1 from dbo.EMEP with(nolock) Where EMCo=@emco and Equipment=@equipment  and PartNo=@material)
	begin
		select @hqmaterial = HQMatl, @msg = Description 
		From dbo.EMEP 
		Where EMCo=@emco and Equipment=@equipment and MatlGroup=@matlgroup and PartNo = @material
	
		--Check if HQ Matl exists
		select * from dbo.HQMT with(nolock)
		where MatlGroup = @matlgroup and Material = @hqmaterial
		if @@rowcount = 0
		begin
			select @msg = ' Invalid Material Code!  Must use a valid HQ Material.', @rcode = 1
			goto vspexit
		end
	end
else
	begin
		--Check for HQ Material in HQMT
		--Error Out if EM Company Parameters requires Valid Matl
		select @msg = Description, @hqmaterial=Material
		from dbo.HQMT with(nolock) 
		where MatlGroup = @matlgroup and Material = @material
		if @@rowcount = 0
		begin
			select @msg = ' Invalid Material Code!  Must use a valid HQ Material.', @rcode = 1
		end
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipmentHQMatlVal] TO [public]
GO
