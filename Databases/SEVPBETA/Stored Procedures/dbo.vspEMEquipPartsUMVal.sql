SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspEMEquipPartsUMVal]
/***************************************************************************
* Created By: TRL 12/17/2008 Issue 127133 
* Modified: 
*
* Validates UM for EM Equipment Parts 
*
* Pass: MatlGroup, Material, UM
*
*
* Success returns:	0
*
* Error returns: 1 and error message
*
****************************************************************************/
(@matlgroup bGroup = null, @um bUM = null, @material bMatl = null, @errmsg varchar(255) output)
 
as

set nocount on

declare @rcode int

select @rcode = 0

if @matlgroup is null
begin
	select @errmsg = 'Missing Material Group', @rcode = 1
	goto vspexit
end
   
   
if IsNull(@um,'')=''
begin
   	select @errmsg = 'Missing Unit of Measure', @rcode = 1
   	goto vspexit
end

IF IsNull(@material,'') = ''
	BEGIN
		--Validate HQ UM
		select @errmsg = Description from dbo.HQUM with(nolock) where UM = @um
		if @@rowcount = 0
   		begin
   			select @errmsg = 'Invalid Unit of Measure', @rcode = 1
			goto vspexit
   		end
    END
ELSE
	BEGIN
		--Validate HQ Materials
		If not exists (select Material from dbo.HQMT with(nolock) 
					where MatlGroup=@matlgroup and Material=@material)
		begin	
			select @errmsg = 'Invalid HQ Material', @rcode = 1
			goto vspexit
		end
		/*First Validate each UM to HQ Materials record
		Second Validate UM to HQMU/HQ Material Addl UMs*/
		--StdUM
		select @errmsg=u.Description from dbo.HQMT t with(nolock)
		Inner Join dbo.HQUM u with(nolock)on u.UM=t.StdUM
		where t.MatlGroup=@matlgroup and t.Material=@material and u.UM=@um
		If @@rowcount <> 0 
		begin	
			goto vspexit
		end
		--PurchaseUM
		select @errmsg=u.Description from dbo.HQMT t with(nolock)
		Inner Join dbo.HQUM u with(nolock)on u.UM=t.PurchaseUM
		where t.MatlGroup=@matlgroup and t.Material=@material and u.UM=@um
		If @@rowcount <> 0 
		begin	
			goto vspexit
		end
		--SalesUM
		select @errmsg=u.Description from dbo.HQMT t with(nolock)
		Inner Join dbo.HQUM u with(nolock)on u.UM=t.SalesUM
		where t.MatlGroup=@matlgroup and t.Material=@material and u.UM=@um
		If @@rowcount <> 0 
		begin	
			goto vspexit
		end
		--MetricUM
		select @errmsg=u.Description from dbo.HQMT t with(nolock)
		Inner Join dbo.HQUM u with(nolock)on u.UM=t.MetricUM
		where t.MatlGroup=@matlgroup and t.Material=@material and u.UM=@um
		If @@rowcount <> 0 
		begin	
			goto vspexit
		end
		--HQMU HQ Materials Addl UM
		If not exists (select m.UM from dbo.HQUM m with(nolock) 
			 Inner Join dbo.HQMU u with(nolock)on u.UM=m.UM 
			where u.MatlGroup=@matlgroup and u.Material=@material and u.UM=@um)
		begin	
			select @errmsg = 'Invalid Unit of Measure for HQ Material', @rcode = 1
			goto vspexit
		end
	END

vspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipPartsUMVal] TO [public]
GO
