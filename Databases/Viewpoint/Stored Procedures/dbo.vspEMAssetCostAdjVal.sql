SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[vspEMAssetCostAdjVal]
   
/***********************************************************
* CREATED BY: TerryLis 01/15/08
* MODIFIED By :
*
* USAGE:
*	EM Cost Adj: Validates an Asset vs bEMDP and vs bEMEM for a specified
*	Equipment.
*
* INPUT PARAMETERS
*	@emco			EM Company to be validated against
*	@asset			Asset to be validated
*	@equipment		Equipment to be validated against in EMEM
*
* OUTPUT PARAMETERS
*	@assetdebitGLacct
*	@assetcreditGLacct
*	@deprcostcode
*	@deprcosttype
*	@msg 			Error or Description of Component
*	@comptypecode		ComponentTypeCode for Component if
*				valid
*
* RETURN VALUE
*	0 Success
*	1 Error
***********************************************************/
   
(@emco bCompany = null,
@asset varchar(20) = null,
@equipment bEquip = null,
@emgroup bGroup = null,
@assetdebitGLacct bGLAcct = null output,
@assetcreditGLacct bGLAcct = null output,
@deprcostcode bCostCode =null output,
@deprcosttype bEMCType =null output,
@msg varchar(255) output)
   
as
   
set nocount on
declare @rcode int, @department bDept

select @rcode = 0, @department=''
   
if @emco is null
begin
	select @msg = 'Missing EM Company!', @rcode = 1
   	goto vspexit
end
if IsNull(@asset,'')=''
begin
	select @msg = 'Missing Asset!', @rcode = 1
	goto vspexit
end
if IsNull(@equipment,'')=''
begin
	select @msg = 'Missing Equipment for Asset!', @rcode = 1
	goto vspexit
end
if @emgroup is null
begin
	select @msg = 'Missing EM Group!', @rcode = 1
	goto vspexit
end
/* Basic validation of Asset vs EMDP. */
select @msg= p.Description, @assetdebitGLacct = p.DeprExpAcct,@assetcreditGLacct = p.AccumDeprAcct,
@department=m.Department
from dbo.EMDP p with(nolock)
Inner Join dbo.EMEM m with(nolock)on m.EMCo=p.EMCo and m.Equipment=p.Equipment
where p.EMCo = @emco and p.Asset = @asset and p.Equipment = @equipment
if @@rowcount = 0
begin
	select @msg = 'Invalid Asset!', @rcode = 1
    goto vspexit
end
	
--Get Default EM Co Depr CostCode and Cost Type
select @deprcostcode = DeprCostCode,@deprcosttype=DeprCostType
from dbo.EMCO with(nolock)
where EMCo = @emco 

--Get Department Accum Depr GL Acct
If IsNull(@department,'') <> '' 
begin
	select @assetcreditGLacct= IsNull(DepreciationAcct,@assetcreditGLacct)
	from dbo.EMDM with(nolock)
	where EMCo = @emco and Department=@department

	select @assetcreditGLacct = IsNull(GLAcct,@assetcreditGLacct)
	from dbo.EMDO with (nolock)
   	where EMCo = @emco and Department = @department and EMGroup = @emgroup and CostCode = @deprcostcode

	select @assetcreditGLacct = IsNull(GLAcct ,@assetcreditGLacct)
	from dbo.EMDG with (nolock)
   	where EMCo = @emco and Department = @department and EMGroup = @emgroup and CostType = @deprcosttype
end
  
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMAssetCostAdjVal] TO [public]
GO
