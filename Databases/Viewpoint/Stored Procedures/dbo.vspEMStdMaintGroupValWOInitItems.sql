SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspEMStdMaintGroupValWOInitItems]
(@emco bCompany = null, @equip bEquip = null, @component bEquip = null,@stdmaintgroup varchar(10) = null, 
@maintgroupcount int = null output, @maintitemscount int=null output,@onopenworkorders int output,
@msg varchar(255) output)
as
set nocount on
/***********************************************************
* CREATED BY: TRL 10/17/07
*
* MODIFIED By TRL 03/18/09	Issue 132697 re-coded std maint group/item counts
*
* USAGE:
* Validates EM Std Maint Group in EMWOItemInit
*
* 	No EMCo passed
*	No Equipment passed
*	No StdMaintGroup passed
*	StdMaintGroup not found in EMSH
*
* INPUT PARAMETERS
*	EMCo		EMCo to validate against 
*	Equipment	Equipment to validate against
*	StdMaintGroup  	StdMaintGroup to validate 
*
* OUTPUT PARAMETERS
*		@maintgroupcount - total std maintgroups
*		@maintitemscount - total std maint items
*   	@msg	Error message if error occurs, otherwise 
*		Description of StdMaintGroup from EMSH
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/ 
   
declare @rcode int

select @rcode = 0 , @maintgroupcount=0, @maintitemscount=0, @onopenworkorders = 0
   
if @emco is null
begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
end
   
if @equip is null
begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
end
   
if @stdmaintgroup is null
begin
   	select @msg = 'Missing Std Maint Group!', @rcode = 1
   	goto bspexit
end

If IsNull(@component,'')  = ''
	begin
		select @msg = Description from dbo.EMSH with (nolock)
		where EMCo = @emco and Equipment = @equip and StdMaintGroup = @stdmaintgroup
		if @@rowcount = 0
		begin
			select @msg = 'Std Maint Group not on file!', @rcode = 1
   			goto bspexit
		end
		/* Start Issue 132697*/
		--count Linked Std Maint Groups
		select @maintgroupcount = Count(Distinct i.StdMaintGroup)+ 1 From dbo.EMSL i	
		Where i.EMCo=@emco and i.Equipment=@equip and i.StdMaintGroup =  @stdmaintgroup	 and i.Equipment = @equip
		
		--count EMSI items
		select @maintitemscount = Count(*) from dbo.EMSI i with(nolock)
		where i.EMCo=@emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment=@equip 
		
		--count Linked EMSI items
		select @maintitemscount = Count(*)+ @maintitemscount
		from dbo.EMSL l with(nolock)
		Inner Join EMSI i with(nolock)on l.EMCo=i.EMCo and l.Equipment=i.Equipment and l.LinkedMaintGrp = i.StdMaintGroup
		where l.EMCo=@emco and l.StdMaintGroup = @stdmaintgroup and l.Equipment=@equip 

		select @onopenworkorders = Count(*) from dbo.EMSI i with(nolock)
		Inner Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Equipment=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
		Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
		where i.EMCo=@emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment=@equip 
		and IsNull(s.StatusType,'') <> 'F' and IsNull(w.WorkOrder,'') <> ''

		select @onopenworkorders = Count(*)+ @onopenworkorders from dbo.EMSI i with(nolock)
		Inner Join EMSL l with(nolock)on l.EMCo=i.EMCo and l.Equipment=i.Equipment and l.LinkedMaintGrp = i.StdMaintGroup
		Inner Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Equipment=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
		Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
		where l.EMCo=@emco and l.StdMaintGroup = @stdmaintgroup and l.Equipment=@equip 
		and IsNull(s.StatusType,'') <> 'F' and IsNull(w.WorkOrder,'') <> ''
		/* End Issue 132697*/
	end
else
	begin
		select @msg = Description from dbo.EMSH with (nolock)
		where EMCo = @emco and Equipment = @component and StdMaintGroup = @stdmaintgroup
		if @@rowcount = 0
		begin
			select @msg = 'Std Maint Group not on file!', @rcode = 1
   			goto bspexit
		end
		
		--count linked Std Maint Groups
		select @maintgroupcount = Count(Distinct i.StdMaintGroup)From dbo.EMSI i	
		Left Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Component=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
		Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
		Where i.EMCo=@emco and i.Equipment=@component and i.StdMaintGroup =  @stdmaintgroup	 and IsNull(w.Equipment,@equip) = @equip
		and  IsNull(s.StatusType,'') <> 'F' and IsNull(w.WorkOrder,'') = ''
		
		--count EMSI items
		select @maintitemscount = @maintitemscount+ IsNull(Count(*),0) from dbo.EMSI with (nolock) where EMCo = @emco and Equipment = @component and StdMaintGroup = @stdmaintgroup   
		select @maintitemscount = Count(*) from dbo.EMSI i with(nolock)
		left Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Component=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
		Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
		where i.EMCo=@emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment=@component
		--and w.Equipment = @equip and  IsNull(s.StatusType,'') <> 'F' and IsNull(w.WorkOrder,'') = ''


		select @onopenworkorders = Count(*)	from dbo.EMSI i with(nolock)
		inner Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Component=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
		Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
		where i.EMCo=@emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment=@component
		and w.Equipment = @equip and  IsNull(s.StatusType,'') <> 'F' and IsNull(w.WorkOrder,'') <> ''
	end

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMStdMaintGroupValWOInitItems] TO [public]
GO
