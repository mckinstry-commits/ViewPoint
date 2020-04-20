SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspEMSMGStatusWarning]
/********************************************************
* CREATED BY: 	JM 4/11/2000
* MODIFIED BY: TV 02/11/04 - 23061 added isnulls
*				TRL 04/09/08 - Issue 120532
*				TRL 12/15/08 - Issue 131412 
*						Added isnulls around @stdmaintgroup
*						Changed select in looking for work order  to i.WorkOrder <> @headerworkorder, from i.WorkOrder = @headerworkorder
*				TRL 07/01/09 - Issue 134518 fixed mistype @rcode = 21 to @rcode = 1
* USAGE:
* 	Returns whether a WOItem is Status = Open on another WO (<> 'F')
*
* INPUT PARAMETERS:
* EM Company
* EMGroup
* StdMaintGroup
* HeaderWorkOrder
* Equipment
* Component
*
*
* OUTPUT PARAMETERS:
* Work Order
*Error Message, if one
*
* RETURN VALUE:
*  @roceo
*********************************************************/
   
(@emco bCompany,
@stdmaintgroup varchar(10),
@emgroup as bGroup,
/*Issue 120532*/
@headerworkorder bWO, 
@equipment as bEquip,
@component as bEquip,
@workorder varchar(10) output,
@errmsg varchar(400) output)
   
as
   
set nocount on
   
declare @rcode int,
      @statuscode varchar(10),
      @statustype char(1),
      @numrows int

select  @rcode = 0
   
/* Verify required parameters passed. */
if @emco is null
begin
	select @errmsg = 'Missing EM Company#!', @rcode = 1
    goto bspexit
end
if @stdmaintgroup is null
begin
	select @errmsg = 'Missing Std Maint Group!', @rcode = 1
    goto bspexit
end
if @emgroup is null
begin
	select @errmsg = 'Missing EMGroup!', @rcode = 1
    goto bspexit
end
if @equipment is null
begin
	select @errmsg = 'Missing Equipment!', @rcode = 1
    goto bspexit
end

If IsNull(@equipment,'') <> '' and IsNull(@component,'') = ''
begin
	select @numrows = 0
	
	/* See if Std Maint Group/StdMaint Items exists on any Work Order*/
	select @numrows = count(*)
	from dbo.EMWI i with (nolock)
	Left Join dbo.EMWS s with(nolock) on s.EMGroup=i.EMGroup and s.StatusCode=i.StatusCode
	where i.EMCo = @emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment = @equipment 
	and s.StatusType <> 'F'
	
	/* No WO's exist with open Items for this SMG. */
	if @numrows = 0 
	begin
		select @rcode = 0
		goto bspexit
	end

	/* One WO exists with open Items for this SMG. */
	if @numrows >= 1 
	begin
		If exists(select top 1 1 	from dbo.EMWI i with (nolock)
		Left Join dbo.EMWS s with(nolock) on s.EMGroup=i.EMGroup and s.StatusCode=i.StatusCode
		where i.EMCo = @emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment = @equipment 
		and i.WorkOrder = @headerworkorder 	and s.StatusType <> 'F')
		begin
			select @errmsg = 'Warning: Std Maint Group ' + IsNull(@stdmaintgroup,'') + ' has one or more other Std Maint Items '
			+ ' on the Target Work Order '+@headerworkorder + '.', @rcode = 1 /*Issue 134518*/
			goto bspexit	
		end	
	

		/*Does SMG have items on other Open Work Orders. */
		--Issue 131412 changed to i.WorkOrder <> @headerworkorder from i.WorkOrder = @headerworkorder
		select @workorder = Min(i.WorkOrder)
		from dbo.EMWI i with (nolock)
		Left Join dbo.EMWS s with(nolock) on s.EMGroup=i.EMGroup and s.StatusCode=i.StatusCode
		where i.EMCo = @emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment = @equipment 
 		and i.WorkOrder <> @headerworkorder and IsNull(s.StatusType,'') <> 'F' 
		If @@rowcount >=1 
		begin
			select @errmsg = 'Warning: Std Maint Group ' + IsNull(@stdmaintgroup,'') + ' exists on one or more open Work Orders. ' 
			+ ' First Work Order found: '+ IsNull(@workorder,'') + '.',@rcode = 1
			goto bspexit	
		end
	end	
end
  
/*120532*/
If IsNull(@component,'') <> ''
begin
	select @numrows = 0
	/* See if Std Maint Group/StdMaint Items exists on any Work Order*/
	select @numrows = count(*)
	from dbo.EMWI i with (nolock)
	Left Join dbo.EMWS s with(nolock) on s.EMGroup=i.EMGroup and s.StatusCode=i.StatusCode
	where i.EMCo = @emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment = @equipment
	and i.Component = @component and s.StatusType <> 'F'

	/* No WO's exist with open Items for this SMG. */
	if @numrows = 0 
	begin
		goto bspexit
	end
	
	if @numrows >= 1 
	begin
		/* Does SMG have Items on header workorder? */
		If exists(select top 1 1 from dbo.EMWI i with (nolock)
		Left Join dbo.EMWS s with(nolock) on s.EMGroup=i.EMGroup and s.StatusCode=i.StatusCode
		where i.EMCo = @emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment = @equipment 
		and i.Component = @component and i.WorkOrder = @headerworkorder 	and s.StatusType <> 'F')
		begin
			select @errmsg = 'Warning: Std Maint Group ' + IsNull(@stdmaintgroup,'') + ' has one or more other Std Maint Items '
			+ ' on the Target Work Order '+@headerworkorder + '.', @rcode = 1
			goto bspexit	
		end

		/* Does SMG have Items on other Work Orders*/
		select @workorder = WorkOrder
		from dbo.EMWI i with (nolock)
		Left Join dbo.EMWS s with(nolock) on s.EMGroup=i.EMGroup and s.StatusCode=i.StatusCode
		Inner Join dbo.EMSI si with(nolock)on i.EMCo = si.EMCo and i.Component = si.Equipment 
		and i.StdMaintGroup = si.StdMaintGroup and  i.StdMaintItem = si.StdMaintItem  
		where i.EMCo = @emco and i.StdMaintGroup = @stdmaintgroup and i.Equipment = @equipment 
		and i.Component=@component 	and s.StatusType <> 'F' and i.WorkOrder <> @headerworkorder
		If @@rowcount >=1 
		begin
			select @errmsg = 'Warning: Std Maint Group ' + IsNull(@stdmaintgroup,'') + ' exists on one or more open Work Orders. ' 
			+ ' First Work Order found: '+ IsNull(@workorder,'') + '.',@rcode = 1
			goto bspexit	
		end
	end
end

bspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMSMGStatusWarning] TO [public]
GO
