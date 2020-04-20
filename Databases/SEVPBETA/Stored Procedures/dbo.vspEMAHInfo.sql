SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspEMAHInfo]
/*************************************
* CREATED BY: TV Oct5th 2006
* MODIFIED By: DANSO 05/02/08 - Issue 127768 - Better 'Applies to: ' Descriptions 
*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
*
* USAGE:
* used by EM Allocation Processing to get information about the Allocation
* before it is run.
* Pass in :
*	EMCo, AllocationCode
*
* Returns

*	Returns a result set of the information from a specific EMAH Record
*
* Error returns no rows
*******************************/
(@emco bCompany, @alloccode smallint, @EquipmentOpt char(250) Output, @CategoryOpt char(250) Output, @DepartmentOpt char(250) Output, @AllocBasis char(1) Output,
@MthDateFlag char(1) output, @AmtRateFlag char(1) output, @AllocAmtRate varchar(30) output, @AllocAmtCol varchar(30) output, 
@AllocRateCol varchar(30) output, @CostTypes varchar(100) output,@CostCodes varchar(55) output, 
@RevCode varchar(255) output, @AllocInfo varchar(1000) output, 
@errmsg varchar(255) output)

as
set nocount on
--#142350 - removing @AllocCode
declare @rcode int,
		@AllocCostTypes varchar(60),
    	@BasisString varchar(60),
		@LastPosted smalldatetime, 
		@LastMonth smalldatetime,
		@LastBeginDate smalldatetime, 
		@LastEndDate smalldatetime,
		@emgroup bGroup,
		@Equipment varchar(250),
		@Category varchar(250),
		@Depts varchar(250),
		@PostToCostCode varchar(250),
	    @PostToCostType varchar(5),
		@EMCostType bEMCType, 
		@EMRevCode bRevCode, 
		@EMEquipment bEquip,
		@EMDepartments bDept,
		@EMCategories bCat

if @emco is null
begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto bspexit
end

if @alloccode is null
begin
	select @errmsg = 'Missing Allocation Code!', @rcode = 1
	goto bspexit
end

/* Get EMGroup*/
select @emgroup = EMGroup from dbo.HQCO with (nolock) where HQCo = @emco

select @errmsg = Description, 
	@EquipmentOpt = SelectEquip,
	@CategoryOpt = SelectCatgy,
	@DepartmentOpt = SelectDept,
	@AllocBasis = AllocBasis,
	@MthDateFlag = MthDateFlag,
	@AmtRateFlag = AmtRateFlag,
	@AllocAmtRate = case when AmtRateFlag='A' Then IsNull(AllocAmount,0) else IsNull(AllocRate,0) END,
	@AllocAmtCol = EquipAmtCol,
	@AllocRateCol = EquipRateCol,
	@PostToCostCode = CostCode,
	@PostToCostType = convert(varchar(3),isnull(CostType,'') ),
	@LastPosted = LastPosted,
	@LastMonth = LastMonth,
	@LastBeginDate = LastBeginDate,
	@LastEndDate = LastEndDate
from dbo.EMAH with (nolock)
where EMCo = @emco and AllocCode = @alloccode
if @@rowcount = 0
begin
	select @errmsg = 'Allocation Code not on file!', @rcode = 1
	goto bspexit
end

if @AllocBasis not in ('C','H','R','V')
begin
	select @errmsg = ' Invalid Allocation Basis for Allocation Code.', @rcode = 1
	goto bspexit
end

select @CostTypes = ''
If @AllocBasis = 'C'
begin
	select top 1 1 From dbo.EMAT with(nolock) Where EMCo=@emco and AllocCode=@alloccode and EMGroup=@emgroup
	If @@rowcount =0
	begin
		select @CostTypes= '"No Assigned Cost Types!"'
		goto RevCodeSelection
	end
	--Assigned CostTypes
	select @EMCostType = Min(t.CostType)
	from dbo.EMAH h with(nolock)
	Left Join dbo.EMAT t with(nolock)on h.EMCo=t.EMCo and h.AllocCode=t.AllocCode and h.EMGroup=t.EMGroup
	where t.EMCo=@emco and t.AllocCode=@alloccode and t.EMGroup=@emgroup
	while @EMCostType is not null
	begin
		if isnull(@CostTypes,'') <> ''
		begin
			select @CostTypes = @CostTypes + ', '
		end
	
		select @CostTypes = @CostTypes + convert(varchar(3),CostType)
		From dbo.EMAT with(nolock) 
		Where  EMCo=@emco and AllocCode=@alloccode and EMGroup=@emgroup and CostType=@EMCostType

		select @EMCostType = Min(t.CostType)
		from dbo.EMAH h with(nolock)
		Left Join dbo.EMAT t with(nolock)on h.EMCo=t.EMCo and h.AllocCode=t.AllocCode and h.EMGroup=t.EMGroup
		where t.EMCo=@emco and t.AllocCode=@alloccode and t.EMGroup=@emgroup and t.CostType > @EMCostType
	end
	RevCodeSelection:
end

select @RevCode = ''
If (@AllocBasis = 'R') OR (@AllocBasis = 'H')
begin
	If not exists (select 1  From dbo.EMAV with(nolock) Where EMCo=@emco and AllocCode=@alloccode and EMGroup=@emgroup)
	begin
		select @RevCode= '"No Assigned Revenue Codes!"'
		goto EquipmentSelection
	end
	--Assigned Revenue Codes
	select @EMRevCode = min(v.RevCode) 
	from dbo.EMAH h with(nolock)
	Left Join dbo.EMAV v with(nolock)on h.EMCo=v.EMCo and h.AllocCode=v.AllocCode and h.EMGroup=v.EMGroup
	where h.EMCo=@emco and h.AllocCode=@alloccode and h.EMGroup=@emgroup
	while IsNull(@EMRevCode,'') <> ''
	Begin
		if isnull(@RevCode,'') <> ''
		begin
			select @RevCode = @RevCode + ', '
		end

		select @RevCode = @RevCode + RevCode 
		From dbo.EMAV with(nolock) 
		Where  EMCo=@emco and AllocCode=@alloccode and EMGroup=@emgroup and RevCode=@EMRevCode

		select @EMRevCode = min(v.RevCode) 
		from dbo.EMAH h with(nolock)
		Left Join dbo.EMAV v with(nolock)on h.EMCo=v.EMCo and h.AllocCode=v.AllocCode and h.EMGroup=v.EMGroup
		where h.EMCo=@emco and h.AllocCode=@alloccode and h.EMGroup=@emgroup
		and v.RevCode > @EMRevCode
	end
	EquipmentSelection:
End

/*------------ Equipments Option ---------------------*/
if ISnull(@EquipmentOpt,'')not in ('P','A','E')
begin
	select @errmsg = ' Invalid Equipment selection for Allocation Code.', @rcode = 1
	goto bspexit
end

select @Equipment=''
if @EquipmentOpt = 'E'
begin
	If not exists(select 1 From dbo.EMAE with(nolock) Where EMCo=@emco and AllocCode=@alloccode)
	begin
		select @Equipment= '"No Assigned Equipment!"'
		goto DepartmentSelection
	end
	--Assigned Equipment
	select @EMEquipment = min(e.Equipment) 
	from dbo.EMAH h with(nolock)
	Left Join dbo.EMAE e with(nolock)on h.EMCo=e.EMCo and h.AllocCode=e.AllocCode 
	where h.EMCo=@emco and h.AllocCode=@alloccode 
	while IsNull(@EMEquipment,'') <> ''
	Begin
		if isnull(@Equipment,'') <> ''
		begin
			select @Equipment = @Equipment + ', '
		end

		select @Equipment = @Equipment + Equipment 
		From dbo.EMAE with(nolock) 
		Where  EMCo=@emco and AllocCode=@alloccode and Equipment=@EMEquipment

		select @EMEquipment = min(e.Equipment) 
		from dbo.EMAH h with(nolock)
		Left Join dbo.EMAE e with(nolock)on h.EMCo=e.EMCo and h.AllocCode=e.AllocCode 
		where h.EMCo=@emco and h.AllocCode=@alloccode 
		and e.Equipment > @EMEquipment
	end

	-- ISSUE 127768 --
	SET @Equipment = 'Equipment: ' + @Equipment

	DepartmentSelection:
End
--Prompt for Equipment
if @EquipmentOpt = 'P'
begin
	select @Equipment = 'Equipment entered below.'
end
--All Equipment
if @EquipmentOpt = 'A'
begin
	select @Equipment = 'all Equipment'
end


/*------------ Departments Option ---------------------*/
if @DepartmentOpt not in ('P','D','A')
begin
	select @errmsg = ' Invalid Department selection for Allocation Code.', @rcode = 1
	goto bspexit
end

select @Depts=''
if @DepartmentOpt = 'D'
begin
	select top 1 1 From dbo.EMAD with(nolock) Where EMCo=@emco and AllocCode=@alloccode
	If @@rowcount =0
	begin
		select @Depts= '"No Assigned Departments!"'
		goto CategorySelection
	end
	--Assigned Departments
	select @EMDepartments = min(d.Department) 
	from dbo.EMAH h with(nolock)
	Left Join dbo.EMAD d with(nolock)on h.EMCo=d.EMCo and h.AllocCode=d.AllocCode 
	where h.EMCo=@emco and h.AllocCode=@alloccode 
	while IsNull(@EMDepartments,'') <> ''
	Begin
		if isnull(@Depts,'') <> ''
		begin
			select @Depts = @Depts + ', '
		end

		select @Depts = @Depts + Department
		From dbo.EMAD with(nolock) 
		Where  EMCo=@emco and AllocCode=@alloccode and Department=@EMDepartments

		select @EMDepartments = min(d.Department) 
		from dbo.EMAH h with(nolock)
		Left Join dbo.EMAD d with(nolock)on h.EMCo=d.EMCo and h.AllocCode=d.AllocCode 
		where h.EMCo=@emco and h.AllocCode=@alloccode 
		and d.Department > @EMDepartments
	end

	-- ISSUE 127768 --
	SET @Depts = 'Departments: ' + @Depts

	CategorySelection:
End
--Prompt for Departments
if @DepartmentOpt = 'P'
begin
	select @Depts = 'Department entered below.'
end
-- All Departments
if @DepartmentOpt = 'A'
begin
	select @Depts = 'all Departments'
end

/*------------ Category Option ---------------------*/
if @CategoryOpt not in ('P','C','A')
begin
	select @errmsg = ' Invalid Category selection for Allocation Code.', @rcode = 1
	goto bspexit
end
select @Category=''
If @CategoryOpt = 'C' 
begin
	select top 1  1 From dbo.EMAG with(nolock) Where EMCo=@emco and AllocCode=@alloccode
	If @@rowcount =0
	begin
		select @Category= '"No Assigned Categories!"'
		goto FormLabelMssg
	end
	--Assigned Categories
	select @EMCategories = min(g.Category) 
	from dbo.EMAH h with(nolock)
	Left Join dbo.EMAG g with(nolock)on h.EMCo=g.EMCo and h.AllocCode=g.AllocCode 
	where h.EMCo=@emco and h.AllocCode=@alloccode 
	while IsNull(@EMCategories,'') <> ''
	Begin
		if isnull(@Category,'') <> ''
		begin
			select @Category = @Category + ', '
		end

		select @Category = @Category + Category
		From dbo.EMAG with(nolock) 
		Where  EMCo=@emco and AllocCode=@alloccode and Category=@EMCategories

		select @EMCategories = min(g.Category) 
		from dbo.EMAH h with(nolock)
		Left Join dbo.EMAG g with(nolock)on h.EMCo=g.EMCo and h.AllocCode=g.AllocCode 
		where h.EMCo=@emco and h.AllocCode=@alloccode 
		and g.Category > @EMCategories
	end

	-- ISSUE 127768 --
	SET @Category = 'Categories: ' + @Category

	FormLabelMssg:
End
--Prompt for Category
if @CategoryOpt = 'P'
begin
	select @Category = 'Category entered below.'
end
--All Categories
if @CategoryOpt = 'A'
begin
	select @Category = 'all Categories'
end


-----------------------------------

select @AllocInfo = 'Applies to ' + @Equipment + char(13) + char(10) +  
					'Applies to ' + @Depts + char(13) + char(10) +  
					'Applies to ' + @Category + char(13) + char(10)

select @AllocInfo = @AllocInfo + 
	case @AllocBasis
		When 'C' then 'Based on Cost for Cost Types: ' + isnull(@CostTypes,'')
		when 'H' then 'Based on Hours for Revenue Codes: ' + isnull(@RevCode,'')
		when 'R' then 'Based on Revenue for Revenue Codes: ' + isnull(@RevCode,'')
		when 'V' then 'Based on Equipment Basis Column:  '
		end

select @AllocInfo = @AllocInfo + char(13) + char(10) + 'Allocates a '

If @AmtRateFlag = 'A' 
	begin
		select @AllocInfo = @AllocInfo + 'flat amount '
	end
else
	begin
		select @AllocInfo = @AllocInfo + 'rate '
	end

If IsNull(@AllocAmtRate,'') = ''
	begin
		select @AllocInfo = @AllocInfo + 'from the Equipment Column: ' + isnull(@AllocAmtCol,'')
	end
else
	begin
		If @AmtRateFlag = 'A'
		begin
			select @AllocInfo = @AllocInfo + 'from the allocation amount. '
		end
	else
		begin
			select @AllocInfo = @AllocInfo + 'from the allocation rate. '
		end
	end

If isnull(@PostToCostCode,'') = ''
	begin
		If isnull(@PostToCostType,'') = ''
			begin
				select @AllocInfo = @AllocInfo + char(13) + char(10) + 'Post result to Cost Codes and CostTypes included in Basis'
			end
		else
			begin
				select @AllocInfo = @AllocInfo + char(13) + char(10) + 'Post result to Cost Codes and Cost type:  ' + isnull(@PostToCostType,'') 
			end
	end
else
	begin
		If isnull(@PostToCostType,'') = ''
			begin
				select @AllocInfo = @AllocInfo + char(13) + char(10) + 'Post result to Cost Code: ' + isnull(@PostToCostCode,'') + ' and CostTypes included in Basis'
			end
		else
			begin
				select @AllocInfo = @AllocInfo + char(13) + char(10) + 'Post result to Cost Code: ' + isnull(@PostToCostCode,'') + ' and Cost type: ' + isnull(@PostToCostType,'')
			end
	end

If isnull(@LastPosted,'') = '' 
	begin
		select @AllocInfo = @AllocInfo + char(13) + char(10) + char(13) + char(10) + '"No processing has occurred for this allocation."'
	end
Else
	begin
		select @AllocInfo = @AllocInfo + char(13) + char(10) + char(13) + char(10) + 'Last run on ' + convert(varchar(10),@LastPosted,101) + char(13) + char(10)
		if isnull(@LastBeginDate,'')<>'' and isnull(@LastEndDate,'') <> '' 
		begin
			select @AllocInfo = @AllocInfo + ' For the dates ' + convert(varchar(10),@LastBeginDate,101) + ' - ' + convert(varchar(10),@LastEndDate,101) + char(13) + char(10)
		end
		if isnull(@LastMonth,'')<> ''
		begin
			select @AllocInfo = @AllocInfo + ' For the month ' + substring(convert(varchar(10),@LastMonth,1),1,3) + substring(convert(varchar(10),@LastMonth,1),7,2)
		end
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMAHInfo] TO [public]
GO
