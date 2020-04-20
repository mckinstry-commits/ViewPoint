SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[bspEMEquipValForWOItemInit]
   
/***********************************************************
* CREATED BY: JM 6-20-02 - Adapted from bspEMEquipVal
* MODIFIED By  JM 09/19/02 - Added '@type = 'C' and ' to test of comp vs compofequip
*				TV 02/11/04 - 23061 added isnulls	
*				TRL 04/02/08 - Issues 126132  and 120532
*					re-wrote stored procedure to fit form modifications for initializing components
*				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*				TRL 03/18/2008 - 132697 rewrote std maint group/item counts
*
* USAGE:
*	Validates EMEM.Equipment
*	If a component, verifies that it is componentof CompOfEquip passed in
*	Returns Equip Type and ComponentTypeCode
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
*	@compofequip	Component's parent equip if @equip is a Component
*
* OUTPUT PARAMETERS
*	@type			Equip Type from bEMEM
*	@componenttypecode 	ComponentTypeCode from bEMEM
*	@msg 			error or Description
*
* RETURN VALUE
*	0 success
*	1 error
***********************************************************/
(@emco bCompany = null,
@equip bEquip = null,

@stdmaintgroups int output,
@stdmaintitems int output,
@onopenworkorders int output,
@msg varchar(255) output)
   
as
   
set nocount on
declare @rcode int, @status char(1), @type char(1), @numrows int

select @rcode = 0, @stdmaintgroups =0, @stdmaintitems =0, @onopenworkorders = 0

if @emco is null
begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
end
   
if IsNull(@equip,'')=''
begin
   	select @msg = 'Missing Equipment!', @rcode = 1
   	goto bspexit
end
 

--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
If @rcode = 1
begin
	  goto bspexit
end

/*Validate WO Header Equipment*/  
select  @msg=Description, @status = Status, @type = Type
from dbo.EMEM with(nolock)
where EMCo = @emco and Equipment = @equip
select @numrows = @@rowcount
if @numrows = 0
begin
   	select @msg = 'Equipment is invalid!', @rcode = 1
   	goto bspexit
end
/* Reject if Status inactive. */
if @status = 'I'
begin
	select @msg = 'Equipment Status is Inactive!', @rcode = 1
   	goto bspexit
end

/*Issue 132697*/
select  @stdmaintgroups = Count(Distinct i.StdMaintGroup)From dbo.EMSI i
Where i.EMCo=@emco and i.Equipment=@equip 
	
select @stdmaintitems = Count(*) from dbo.EMSI i with(nolock)
where i.EMCo=@emco and i.Equipment=@equip 

select @onopenworkorders = Count(*) from dbo.EMSI i with(nolock)
inner Join EMWI w with(nolock)on w.EMCo=i.EMCo and w.Equipment=i.Equipment and w.StdMaintGroup=i.StdMaintGroup and w.StdMaintItem=i.StdMaintItem
Left Join EMWS s with(nolock)on s.EMGroup=w.EMGroup and s.StatusCode=w.StatusCode
where i.EMCo=@emco and i.Equipment=@equip and IsNull(s.StatusType,'') <> 'F' and IsNull(w.WorkOrder,'') <> ''

bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValForWOItemInit] TO [public]
GO
