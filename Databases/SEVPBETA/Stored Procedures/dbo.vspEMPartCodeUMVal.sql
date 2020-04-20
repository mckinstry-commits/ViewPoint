SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspEMPartCodeUMVal]
/***************************************************************************
* Created By: TRL 12/24/2008 Issue 127133 
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
(@emco bCompany, @equipment bEquip, @matlgroup bGroup, 
@um bUM, @partcode varchar(20) = null, @errmsg varchar(255) output)
 
as

set nocount on

declare @rcode int, @hqmatl bMatl

select @rcode = 0,@hqmatl =''

if @emco is null
begin
	select @errmsg = 'Missing EM Company', @rcode = 1
	goto vspexit
end

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

if IsNull(@partcode,'')=''
begin
   	select @errmsg = 'Missing PartCode', @rcode = 1
   	goto vspexit
end

--Is Part linked to HQMaterial Y
Select @hqmatl= IsNull(HQMatl,'') From dbo.EMEP with(nolock)
where EMCo=@emco and Equipment=@equipment and PartNo=@partcode and MatlGroup=@matlgroup
IF @hqmatl = ''
	BEGIN
		goto HQUMVal
	END
ELSE
	BEGIN
		select @partcode=@hqmatl
		goto HQMatlUMVal
	END

IF exists (select Material from dbo.HQMT with(nolock) where MatlGroup=@matlgroup and Material=@partcode)
	BEGIN
		goto HQMatlUMVal
	END
ELSE
	BEGIN
		goto HQUMVal
	END

HQMatlUMVal:
	/*First Validate each UM to HQ Materials record
	Second Validate UM to HQMU/HQ Material Addl UMs*/
	--StdUM
	select @errmsg=u.Description from dbo.HQMT t with(nolock)
	Inner Join dbo.HQUM u with(nolock)on u.UM=t.StdUM
	where t.MatlGroup=@matlgroup and t.Material=@partcode and t.StdUM=@um
	If @@rowcount >= 1
	begin	
		goto vspexit
	end
	--PurchaseUM
	select @errmsg=u.Description from dbo.HQMT t with(nolock)
	Inner Join dbo.HQUM u with(nolock)on u.UM=t.PurchaseUM
	where t.MatlGroup=@matlgroup and t.Material=@partcode and t.PurchaseUM=@um
	If @@rowcount >= 1
	begin	
		goto vspexit
	end
	--SalesUM
	select @errmsg=u.Description from dbo.HQMT t with(nolock)
	Inner Join dbo.HQUM u with(nolock)on u.UM=t.SalesUM
	where t.MatlGroup=@matlgroup and t.Material=@partcode and t.SalesUM=@um
	If @@rowcount >= 1
	begin	
		goto vspexit
	end
	--MetricUM
	select @errmsg=u.Description from dbo.HQMT t with(nolock)
	Inner Join dbo.HQUM u with(nolock)on u.UM=t.MetricUM
	where t.MatlGroup=@matlgroup and t.Material=@partcode and t.MetricUM=@um
	If @@rowcount >= 1
	begin	
		goto vspexit
	end
	--HQMU HQ Materials Addl UM
	select m.UM from dbo.HQUM m with(nolock) 
	Inner Join dbo.HQMU u with(nolock)on u.UM=m.UM 
	where u.MatlGroup=@matlgroup and u.Material=@partcode and m.UM=@um
	If @@rowcount = 0 
	begin	
		select @errmsg = 'Invalid Unit of Measure for HQ Material', @rcode = 1
		goto vspexit
	end
	goto vspexit

HQUMVal:
	--Validate HQ UM
	select @errmsg = Description from dbo.HQUM with(nolock) where UM = @um
	if @@rowcount = 0
   	begin
   		select @errmsg = 'Invalid Unit of Measure', @rcode = 1
		goto vspexit
   	end

vspexit:

return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspEMPartCodeUMVal] TO [public]
GO
