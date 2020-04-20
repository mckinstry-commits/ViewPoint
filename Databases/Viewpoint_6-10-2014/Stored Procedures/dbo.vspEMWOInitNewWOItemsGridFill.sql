SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE      proc [dbo].[vspEMWOInitNewWOItemsGridFill]
/*******************************************************************
* CREATED: 04/07/98 TRL  added stored procedre
* LAST MODIFIED:  04/18/07 Issue 121437, added StdMaint Group, 
*					Std Maint Item and Std Maint Item Desc to output
*					TRL 02/05/10 Issue 138584  update Description Col to 60
*					GF 04/26/2013 TFS-48552 EMSH/EMSI expanded descriptions
*
*				
* USAGE: Called by EMWOInit form to report the new Work Orders Items
*		created in a series for a set of Equipment.
*
* INPUT PARAMS:
*	@emco		Controlling EM Company
*   @autoinitsession
* OUTPUT PARAMS:
*	@rcode		Return code; 0 = success, 1 = failure
*	@errmsg		Error message; # copied if success,
*			error message if failure
********************************************************************/
(@emco bCompany = null, @autoinitsessionid varchar(30) = null,@errmsg varchar(255) output)
    
as
    
set nocount on
    
declare @rcode integer

select @rcode = 0
    
/* Verify required parameters passed. */
if @emco is null
begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
    goto vspexit
end
if @autoinitsessionid is null
begin
	select @errmsg = 'Missing AutoInitSessionID!', @rcode = 1
    goto vspexit
end
    
/* Create # table to hold list of WorkOrder Items to
be returned to the VB application for display to user. */
create table #DisplayInfo
(WorkOrder varchar(10) null,
WOItem smallint null,
Description varchar(60) null /*135894*/,
Equipment varchar(10) null,
Component varchar(10) null,
EquipType char(1) null,
Shop varchar(20) null,
PRCo int null,/*27172*/
Mechanic int null,
CostCode varchar(10) null,
InHseSubFlag char(1) null,
StdMaintGroup varchar(10) null,
StdMaintGroupDesc varchar (60) null,
StdMaintItem int null,
----TFS-48552
StdMaintItemDesc varchar(60) null)
    
    
--Insert Equipment Records   
insert into  #DisplayInfo (WorkOrder,WOItem,Description,Equipment,Component,EquipType,
Shop, PRCo,Mechanic ,CostCode, InHseSubFlag,
StdMaintGroup,StdMaintGroupDesc,StdMaintItem,StdMaintItemDesc)
select a.WorkOrder, a.WOItem, a.Description, a.Equipment, null,em.Type,
b.Shop,a.PRCo/*27172*/,a.Mechanic, a.CostCode, a.InHseSubFlag,
sh.StdMaintGroup,sh.Description,si.StdMaintItem,si.Description
from dbo.EMWI a with(nolock)
inner join dbo.EMWH b with(nolock) on a.EMCo=b.EMCo and a.WorkOrder=b.WorkOrder
Inner Join dbo.EMSH sh with(nolock) on sh.EMCo=a.EMCo and sh.Equipment = a.Equipment and sh.StdMaintGroup=a.StdMaintGroup and sh.Equipment = a.Equipment
Inner Join dbo.EMSI si with(nolock) on si.EMCo=a.EMCo and si.Equipment = a.Equipment and si.StdMaintGroup=a.StdMaintGroup and si.StdMaintItem=a.StdMaintItem
Inner Join dbo.EMEM em with(nolock) on em.EMCo=a.EMCo and em.Equipment=a.Equipment
where a.EMCo = @emco and b.AutoInitSessionID = @autoinitsessionid and em.Type = 'E' 
and IsNull(a.Component,'') = ''

--Insert Attached Components
insert into  #DisplayInfo (WorkOrder,WOItem,Description,Equipment,Component,EquipType,
Shop, PRCo,Mechanic ,CostCode, InHseSubFlag,
StdMaintGroup,StdMaintGroupDesc,StdMaintItem,StdMaintItemDesc)
select a.WorkOrder, a.WOItem, a.Description, a.Equipment, a.Component,em.Type,
b.Shop,a.PRCo/*27172*/,a.Mechanic, a.CostCode, a.InHseSubFlag,
sh.StdMaintGroup,sh.Description,si.StdMaintItem,si.Description
from dbo.EMWI a with(nolock)
inner join dbo.EMWH b with(nolock) on a.EMCo=b.EMCo and a.WorkOrder=b.WorkOrder and a.Equipment = b.Equipment
Inner Join dbo.EMSH sh with(nolock) on sh.EMCo=a.EMCo and sh.Equipment = a.Component and sh.StdMaintGroup=a.StdMaintGroup 
Inner Join dbo.EMSI si with(nolock) on si.EMCo=a.EMCo and si.Equipment = a.Component and si.StdMaintGroup=a.StdMaintGroup and si.StdMaintItem=a.StdMaintItem
Inner Join dbo.EMEM em with(nolock) on em.EMCo=a.EMCo and em.Equipment=a.Component
where a.EMCo = @emco and b.AutoInitSessionID = @autoinitsessionid and em.Type = 'C' 
and IsNull(a.Component,'') <> ''

/* Return recordset to VB */
select WorkOrder,WOItem,Description,Equipment,Component,EquipType,
Shop, PRCo,Mechanic ,CostCode, InHseSubFlag,
/*121437*/
StdMaintGroup,StdMaintGroupDesc,StdMaintItem,StdMaintItemDesc 
from #DisplayInfo
Order by WorkOrder,WOItem,Description,Equipment,Component,StdMaintGroup,StdMaintItem

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWOInitNewWOItemsGridFill] TO [public]
GO
