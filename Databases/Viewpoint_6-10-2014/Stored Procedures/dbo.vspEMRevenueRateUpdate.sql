SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMRevenueRateUpdate] 
/****************************************************************************
* CREATED BY: 	TRL 02/12/09 Issue 130856 
* MODIFIED BY:  
*
* USAGE: EM Revenue Rate Update.  
* 	Procedure updates EM Category and Revenue Rates
*
* INPUT PARAMETERS:
*	EM Company,EMGroup,Beg/End Categoris, Beg/End RevCodes
*	RevBdownCode,Rate(Rate to Change)
*	RevRateTypeOption (B-both,E-Equipment only,C-Category only)
*	ChangeByOption (P +- percentage, A+-Amount, O-Override Amount)
*   ChangeAmount(New rate)
*
* OUTPUT PARAMETERS:
*  @errmsg
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*****************************************************************************/
(@emco bCompany = null,@emgroup bGroup = null,@updaterectype varchar(1) = null,
@category bCat = null,@equipment bEquip = null,@revcode bRevCode= null,@revbrkdowncode varchar(10) = null,
@ratetochange bDollar = null,@updateratebyoption varchar(1) = null,@updateamount decimal(12,4) = null,
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

If IsNull(@updaterectype,'') = ''
begin
	select @errmsg = 'Missing Update Record Type Option',@rcode = 1
	goto vspexit
end
If @updaterectype not in ('E','C')
begin
	select @errmsg = 'Invalid Update Record Type Option',@rcode = 1
	goto vspexit
end

If IsNull(@category,'')= ''
begin
	select @errmsg = 'Missing Category',@rcode = 1
	goto vspexit
end

If @updaterectype = 'E'
begin
	If IsNull(@equipment,'')= ''
	begin
		select @errmsg = 'Missing Equipment Code',@rcode = 1
		goto vspexit
	end
end

--RevCode
If IsNull(@revcode,'')= ''
begin
	select @errmsg = 'Missing Revenue Code',@rcode = 1
	goto vspexit 
end

If IsNull(@revbrkdowncode,'')= ''
begin
	select @errmsg = 'Missing Revenue Breakdown Code',@rcode = 1
	goto vspexit 
end

If IsNull(@updateratebyoption,'') = ''
begin
	select @errmsg = 'Missing Update Rate by Option',@rcode = 1
	goto vspexit
end

If @updateratebyoption not in ('P','A','N')
begin
	select @errmsg = 'Invalid Update Rate by Option',@rcode = 1
	goto vspexit
end

If @updateamount is null
begin
	select @errmsg = 'Update amount has no value',@rcode = 1
	goto vspexit
end 
--End validating required parameters

--Category Rate change
IF @updaterectype ='C'
BEGIN
	--Check to see if there are records to update
	--Equipment Revenure Rates can't exist if no Category is set there are no records to update
	If not exists (select top 1 1 From dbo.EMBG with(nolock)
		Where EMCo=@emco and EMGroup=@emgroup and Category=@category and RevCode=@revcode 
		and RevBdownCode=@revbrkdowncode and Rate=IsNull(@ratetochange,Rate))
	begin
		select @errmsg = 'No Category Revenue Rates to update',@rcode = 1
		goto vspexit
	end
	--1st Change EMBG Revenue Breakdown Rates by Category  
	--2nd Change EMRR Revenue Rates by Category
	--Override by Amount
	If @updateratebyoption = 'N'
	Begin
		Update dbo.EMBG
		Set Rate = @updateamount
		Where EMCo=@emco and EMGroup=@emgroup and Category=@category and RevCode=@revcode 
		and RevBdownCode=@revbrkdowncode and Rate=IsNull(@ratetochange,Rate)
	End
  
	--Add/Sub from  Amount
	If @updateratebyoption = 'A'
	Begin
		Update dbo.EMBG
		Set Rate = Rate + @updateamount
		Where EMCo=@emco and EMGroup=@emgroup and Category=@category and RevCode=@revcode 
		and RevBdownCode=@revbrkdowncode and Rate=IsNull(@ratetochange,Rate)
	End	

	--Add/Sub from  Percent of rate
	If @updateratebyoption = 'P'
	Begin
		Update dbo.EMBG
		Set Rate = Rate + (Rate * @updateamount)
		Where EMCo=@emco and EMGroup=@emgroup and Category=@category and RevCode=@revcode 
		and RevBdownCode=@revbrkdowncode and Rate=Isnull(@ratetochange,Rate)
	End	
	;
	With ChangeCatRevCode(EMCo,EMGroup,Category,RevCode,NewRate)as
	(Select EMCo,EMGroup, Category,RevCode,NewRate=Sum(Rate) From dbo.EMBG with(nolock)
	Where EMCo=@emco and EMGroup=@emgroup and Category=@category and RevCode=@revcode 
	Group by EMCo,EMGroup,Category,RevCode)

	Update dbo.EMRR
	Set Rate = NewRate
	From ChangeCatRevCode c
	Inner Join dbo.EMRR r with(nolock)on r.EMCo=c.EMCo and r.EMGroup=c.EMGroup 
	and r.Category=c.Category and r.RevCode=c.RevCode
	Where r.EMCo=@emco and r.EMGroup=@emgroup and r.Category=@category and r.RevCode=@revcode ;
END

--Equipment Rate change
IF @updaterectype ='E'
BEGIN
	--Check to see if there are records to update
	If not exists (select top 1 1 From dbo.EMBE e with(nolock)
		Inner Join dbo.EMEM m with(nolock)on m.EMCo = e.EMCo and m.Equipment=e.Equipment
		Where e.EMCo=@emco and e.EMGroup=@emgroup and m.Category=@category and e.RevCode=@revcode 
		and e.RevBdownCode=@revbrkdowncode and e.Rate=IsNull(@ratetochange,e.Rate) and IsNull(m.Category,'')<>'')
	begin
		select @errmsg = 'No Equipment Revenue Rates to update',@rcode = 1
		goto vspexit
	end
	--1st EMRH Revenue Rates by Equipment
	--2nd EMBE Revenue Breakdown Rates by Equipment
	--Override by Amount
	If @updateratebyoption = 'N'
	Begin
		Update dbo.EMBE
		Set Rate = @updateamount
		From dbo.EMBE e with(nolock)
		Inner Join dbo.EMEM m with(nolock)on m.EMCo = e.EMCo and m.Equipment=e.Equipment and m.EMGroup=e.EMGroup
		Where e.EMCo=@emco and e.EMGroup=@emgroup and e.Equipment=@equipment and m.Category=@category and e.RevCode=@revcode 
		and e.RevBdownCode=@revbrkdowncode and e.Rate=IsNull(@ratetochange,e.Rate)
	End

	--Add/Sub from  Amount
	If @updateratebyoption = 'A'
	Begin
		Update dbo.EMBE
		Set Rate = Rate+@updateamount
		From dbo.EMBE e with(nolock)
		Inner Join dbo.EMEM m with(nolock)on m.EMCo = e.EMCo and m.Equipment=e.Equipment and m.EMGroup=e.EMGroup
		Where e.EMCo=@emco and e.EMGroup=@emgroup and e.Equipment=@equipment and m.Category=@category and e.RevCode=@revcode 
		and e.RevBdownCode=@revbrkdowncode and e.Rate=IsNull(@ratetochange,e.Rate)
	end

	--Add/Sub from  Percent
	If @updateratebyoption = 'P'
	Begin
		Update dbo.EMBE
		Set Rate = Rate+ (Rate * @updateamount)
		From dbo.EMBE e with(nolock)
		Inner Join dbo.EMEM m with(nolock)on m.EMCo = e.EMCo and m.Equipment=e.Equipment and m.EMGroup=e.EMGroup
		Where e.EMCo=@emco and e.EMGroup=@emgroup and e.Equipment=@equipment  and m.Category=@category and e.RevCode=@revcode 
		and e.RevBdownCode=@revbrkdowncode and e.Rate=IsNull(@ratetochange,e.Rate)
	end
	;
	With ChangeEquipRevCode(EMCo,EMGroup,Equipment,RevCode,NewRate)as
	(Select e.EMCo,e.EMGroup,e.Equipment,e.RevCode,NewRate=Sum(e.Rate) From dbo.EMBE e with(nolock)
	--Inner Join dbo.EMEM m  with(nolock)on m.EMCo = e.EMCo and m.Equipment=e.Equipment and m.EMGroup=e.EMGroup
	Where e.EMCo=@emco and e.EMGroup=@emgroup and e.Equipment =@equipment --and m.Category=@category 
	and e.RevCode= @revcode
	Group by e.EMCo,e.EMGroup,e.Equipment,e.RevCode)

	Update dbo.EMRH
	Set Rate = NewRate
	From ChangeEquipRevCode e
	Inner Join EMRH h with(nolock)on e.EMCo=h.EMCo and e.EMGroup=h.EMGroup and e.Equipment = h.Equipment and e.RevCode= h.RevCode
	Where e.EMCo=@emco and e.EMGroup=@emgroup and e.Equipment = @equipment 	and e.RevCode= @revcode;

END

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRevenueRateUpdate] TO [public]
GO
