SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMRevenueRateGridFill] 
/****************************************************************************
* CREATED BY: 	TRL 03/06/09 Issue 130856 
* MODIFIED BY:  
*
* USAGE: EM Revenue Rate Update.  
* 	Procedure fills secondary grids on form
*
* INPUT PARAMETERS:
*	EM Company,EMGroup,Beg/End Categoris, Beg/End RevCodes
*	RevBdownCode,Rate(Rate to Change)
*	UpdateOption (E-Equipment,C-Category)
*	RevBrkdownCodeRate
*
* OUTPUT PARAMETERS:
*  @errmsg
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*****************************************************************************/
(@emco bCompany = null,@emgroup bGroup = null,@begcategory bCat = null,@endcategory bCat = null,
@begrevcode bRevCode= null,@endrevcode bRevCode=null,@revbrkdowncode varchar(10) = null,
@updateoption varchar(1) = null,@revbrkdownrate decimal(12,2) = null,
@errmsg varchar(255) output)

as 

set nocount on

declare @rcode int

Select @rcode = 0

--Start validating required paramters
If @emco is null
begin
	select @errmsg = 'Missing EM Company',@rcode = 1
	goto vspexit
end 
If @emgroup is null
begin
	select @errmsg = 'Missing EM Group',@rcode = 1
	goto vspexit
end 
If IsNull(@revbrkdowncode,'')= ''
begin
	select @errmsg = 'Missing Revenue Breakdown Code',@rcode = 1
	goto vspexit 
end

If IsNull(@updateoption,'') = ''
begin
	select @errmsg = 'Missing Update Option',@rcode = 1
	goto vspexit
end

--Set default beg/end parameter when there null
--Category
If IsNull(@begcategory,'')= ''
begin
	select @begcategory = ''
end
If IsNull(@endcategory,'')= ''
begin
	select @endcategory = 'zzzzzzzzzz'
end
--RevCode
If IsNull(@begrevcode,'')= ''
begin
	select @begrevcode = ''
end
If IsNull(@endrevcode,'')= ''
begin
	select @endrevcode = 'zzzzzzzzzz'
end

If @updateoption = 'C'
begin
	create table #EMCatRevCodeRevBrkdownCount
	(EMCo tinyint, EMGroup tinyint, Category varchar(10),RevCode varchar(10),RCRate decimal(16,2),RevBrkdownCodeCount int)

	Insert into #EMCatRevCodeRevBrkdownCount
	(EMCo,EMGroup,Category,RevCode,RCRate,RevBrkdownCodeCount)
	Select g.EMCo,g.EMGroup,g.Category,g.RevCode,h.Rate,RevBrkdownCodeCount = count(Distinct RevBdownCode)
	from EMBG g
	Inner Join dbo.EMRR h with(nolock)on h.EMCo=g.EMCo and h.EMGroup=g.EMGroup and h.Category=g.Category and h.RevCode = g.RevCode
	Where g.EMCo = @emco and g.EMGroup = @emgroup 
	and g.Category >= @begcategory and g.Category <= @endcategory 
	and g.RevCode >= @begrevcode and g.RevCode <= @endrevcode
	Group by g.EMCo,g.EMGroup,g.Category,g.RevCode,h.Rate

	Select Distinct [Update]='N',[Failed]='N',b.Category,[CategoryDesc]=a.CatDesc, b.RevCode, [RevCodeDesc]= a.RevCodeDesc,
	[Rate]=b.RCRate, [RevBrkdownCodeRate]=g.Rate, b.RevBrkdownCodeCount,[Updated]='N'
	From #EMCatRevCodeRevBrkdownCount b 
	Inner Join dbo.EMBG g on g.EMCo=b.EMCo and g.EMGroup=b.EMGroup and g.Category=b.Category and g.RevCode = b.RevCode
	Left Join dbo.EMRevBdownCategEquip a on a.EMCo=b.EMCo and a.EMGroup=b.EMGroup and a.Category=b.Category and a.RevCode = b.RevCode
	Where b.EMCo = @emco and b.EMGroup = @emgroup 
	and b.Category >= @begcategory and b.Category <= @endcategory 
	and b.RevCode >= @begrevcode and b.RevCode <= @endrevcode
	and g.RevBdownCode= @revbrkdowncode
	and g.Rate = IsNull(@revbrkdownrate,g.Rate)
end

If @updateoption = 'E'
begin
	create table #EMEquipRevCodeRevBrkdownCount
	(EMCo tinyint, EMGroup tinyint, Equipment varchar(10), Category varchar(10),RevCode varchar(10),RCRate decimal(16,2),RevBrkdownCodeCount int)

	Insert into #EMEquipRevCodeRevBrkdownCount
	(EMCo,EMGroup,Equipment,Category,RevCode,RCRate,RevBrkdownCodeCount)
	Select Distinct b.EMCo,b.EMGroup,b.Equipment,e.Category,b.RevCode,h.Rate,count(distinct RevBdownCode)
	from EMBE b with(nolock)
	Inner Join dbo.EMEM e with(nolock)on e.EMCo=b.EMCo and e.Equipment = b.Equipment
	Inner Join dbo.EMRR r with(nolock)on r.EMCo=e.EMCo and r.Category = e.Category
	Inner Join dbo.EMRH h with(nolock)on h.EMCo=b.EMCo and h.EMGroup=b.EMGroup and h.Equipment=b.Equipment and h.RevCode = b.RevCode
	Where b.EMCo = @emco and b.EMGroup = @emgroup 
	and e.Category >= @begcategory and e.Category <= @endcategory 
	and r.Category >= @begcategory and r.Category <= @endcategory 
	and b.RevCode >= @begrevcode and b.RevCode <= @endrevcode
	and h.ORideRate='Y'
	Group by b.EMCo,b.EMGroup,b.Equipment,e.Category,b.RevCode,b.RevBdownCode,h.Rate

	Select Distinct [Update]='N',[Failed]='N',a.Equipment,[EquipmentDesc]=c.EquipDesc,
	a.Category, a.RevCode, [RevCodeDesc]= c.RevCodeDesc,
	[Rate]=a.RCRate, [RevBrkdownCodeRate]=b.Rate, a.RevBrkdownCodeCount,[Updated]='N'
	From #EMEquipRevCodeRevBrkdownCount a
	Inner Join dbo.EMBE b on b.EMCo=a.EMCo and b.EMGroup=a.EMGroup and b.Equipment=a.Equipment and b.RevCode = a.RevCode
	Inner Join EMRevBdownCategEquip c on c.EMCo=a.EMCo and c.EMGroup=a.EMGroup and c.Equipment=a.Equipment and c.Category=a.Category and c.RevCode = a.RevCode
	Where a.EMCo = @emco and a.EMGroup = @emgroup 
	and a.Category >= @begcategory and a.Category <= @endcategory 
	and a.RevCode >= @begrevcode and a.RevCode <= @endrevcode
	and b.RevBdownCode= @revbrkdowncode
	and b.Rate = IsNull(@revbrkdownrate,b.Rate)
end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRevenueRateGridFill] TO [public]
GO
