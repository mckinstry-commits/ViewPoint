SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                   proc [dbo].[vspEMWODisplay]
/****************************************************************************
* CREATED BY: 	TRL 09/09/09
* MODIFIED BY: 	
*	
* USAGE:  	Returns recordset describing Work Orders per various optional	criteria.
*
* INPUT PARAMETERS:
*	EM Company
*   JC Company/Job - optional criteria (must be passed together)
*	Location - optional criteria
*	Category - optional criteria
*	Department - optional criteria
*	Shop - optional criteria
*	Equipment - optional criteria
*	Mechanic - optional criteria
* Added 01/03/01 tv
*	begdate - optional criteria
*	enddate - optional criteria
* OUTPUT PARAMETERS:
*	Recordset containing records in #DisplayInfo
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*****************************************************************************/
(@emco bCompany = null,  @passedequipment bEquip = null,  @jcco bCompany = null, @job varchar(10) = null, @location varchar (10) = null, 
@category varchar(10) = null,@department varchar(10) = null, @equipshop varchar(20)= null,@wosearchoption char(1) = null,@datesearch varchar(12) = null, 
@begindate bDate = null,@enddate bDate = null, @hdrshop varchar(20)=null, @hdrprco bCompany = null, @hdrmechanic bEmployee = null, 
@itemprco bCompany = null, @itemmechanic bEmployee = null, @woitemstatus char(1) = null, @errmsg varchar(255) output)

as

set nocount on

declare @rcode int

select  @rcode = 0

select i.WorkOrder,WODesc=h.Description, WOShop=h.Shop,WOPRCo=h.PRCo, WOMechanic=h.Mechanic,
 WODateCreated=h.DateCreated, WODateDue=h.DateDue, WODateSched=h.DateSched,
 i.Equipment,EquipDesc=e.Description,EquipShop=e.Shop,
i.WOItem,WOItemDesc=i.Description,i.SerialNo,	i.InHseSubFlag,
i.StatusCode,i.DateCreated, i.DateDue, i.DateSched,i.DateCompl,
i.PRCo, i.Mechanic, i.Component,CompDesc=m.Description, i.StdMaintGroup, i.StdMaintItem
from dbo.EMWI i with(nolock) 
Inner Join dbo.EMWH h with(nolock) on h.EMCo = i.EMCo and h.WorkOrder = i.WorkOrder and h.Equipment=i.Equipment
Inner Join dbo.EMEM e with(nolock) on e.EMCo = i.EMCo and e.Equipment = i.Equipment
Left Join dbo.EMEM m with(nolock) on m.EMCo = i.EMCo and m.Equipment = i.Component 
Left join dbo.EMWS s with(nolock) on s.EMGroup = i.EMGroup and s.StatusCode = i.StatusCode
where i.EMCo=@emco  and i.Equipment=isnull(@passedequipment,i.Equipment)  
--EM Equipment Master parameters
and isnull(e.JCCo,'')=isnull(@jcco,isnull(e.JCCo,'')) and IsNull(e.Job,'')=isnull(@job,IsNull(e.Job,''))and IsNull(e.Location,'')=isnull(@location,IsNull(e.Location,'') )
and IsNull(e.Category,'')=isnull(@category,IsNull(e.Category,'')) and IsNull(e.Department,'')=isnull(@department,isnull(e.Department,'') )
and e.Status <>'I'  and isnull(e.Shop,'')=isnull(@equipshop,isnull(e.Shop,''))
--Work Order Header Parameters
and isnull(h.Shop,'')=isnull(@hdrshop,isnull(h.Shop,'')) 
and isnull(h.PRCo,'')=case when @wosearchoption in ('H','B') then isnull(@hdrprco,isnull(h.PRCo,'')) else isnull(h.PRCo,'') end 
 and isnull(h.Mechanic,'')=case when @wosearchoption in ('H','B') then isnull(@itemmechanic,isnull(h.Mechanic,''))  else isnull(h.Mechanic,'') end 
and isnull(h.DateCreated,@begindate) >= case when @wosearchoption in ('H','B') and @datesearch = 'C' then @begindate else isnull(h.DateCreated,@begindate) end 
and isnull(h.DateCreated,@enddate) <= case when  @wosearchoption in ('H','B') and @datesearch = 'C' then @enddate else isnull(h.DateCreated,@enddate) end 
and isnull(h.DateSched,@begindate) >= case when @wosearchoption in ('H','B') and @datesearch = 'S' then @begindate else isnull(h.DateSched,@begindate) end 
and isnull(h.DateSched,@enddate) <= case when  @wosearchoption in ('H','B') and @datesearch = 'S' then @enddate else isnull(h.DateSched,@enddate) end 
and isnull(h.DateDue,@begindate) >= case when  @wosearchoption in ('H','B') and @datesearch = 'D' then @begindate else isnull(h.DateDue,@begindate) end 
and isnull(h.DateDue,@enddate) <= case when  @wosearchoption in ('H','B') and @datesearch = 'D' then @enddate else isnull(h.DateDue,@enddate) end 
--WO Item Parameters
and isnull(i.PRCo,'')=case when @wosearchoption in ('I','B') then isnull(@hdrprco,isnull(i.PRCo,'')) else isnull(i.PRCo,'') end 
and isnull(i.Mechanic,'')=case when @wosearchoption in ('I','B') then isnull(@itemmechanic,isnull(i.Mechanic,''))  else isnull(i.Mechanic,'') end 
and isnull(i.DateCreated,@begindate) >= case when @wosearchoption in ('I','B') and @datesearch = 'C' then @begindate else isnull(i.DateCreated,@begindate) end 
and isnull(i.DateCreated,@enddate) <= case when  @wosearchoption in ('I','B') and @datesearch = 'C' then @enddate else isnull(i.DateCreated,@enddate) end 
and isnull(i.DateSched,@begindate) >= case when @wosearchoption in ('I','B') and @datesearch = 'S' then @begindate else isnull(i.DateSched,@begindate) end 
and isnull(i.DateSched,@enddate) <= case when  @wosearchoption in ('I','B') and @datesearch = 'S' then @enddate else isnull(i.DateSched,@enddate) end 
and isnull(i.DateDue,@begindate) >= case when  @wosearchoption in ('I','B') and @datesearch = 'D' then @begindate else isnull(i.DateDue,@begindate) end 
and isnull(i.DateDue,@enddate) <= case when  @wosearchoption in ('I','B') and @datesearch = 'D' then @enddate else isnull(i.DateDue,@enddate) end 

and s.StatusType <> case when @woitemstatus='L' then 'z' else 'F' end

order by i.WorkOrder,i.WOItem 

if @@rowcount = 0
begin
		select @errmsg = 'No Work Orders found matching criteria.', @rcode = 1
		goto vspexit
end

vspexit:
	 return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspEMWODisplay] TO [public]
GO
