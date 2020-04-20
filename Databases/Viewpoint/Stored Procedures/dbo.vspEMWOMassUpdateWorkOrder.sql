SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMWOMassUpdateWorkOrder]
/****************************************************************************
* CREATED BY: 	TRL 02/03/09 Issue 129069 New form EM Work Order Mass Update
* MODIFIED BY:  JVH 06/20/11 TK-05982 Output current hour + miles so we can use them for updating
*
* USAGE: EM Work Order Mass Update, Returns data for Work Order Header Grid
*
* INPUT PARAMETERS:
* @emco bCompany = EMWH.EMCo
* @begWO bWO = EMWH.WorkOrder
* @endWO bWO = EMWH.WorkOrder
* @jcco bCompany = EMEM.JCCo
* @job  = EMEM.Job 
* @location  = EMEM.Location
* @category  = EMEM.Category
* @department  = EMEM.Department 
* @assignedshop  = EMWH.Shop 
* @prco  = EMWH.PRCo 
* @mechanic bEmployee = EMWH.Mechanic
* @datesearchoption 'C'-EMWH.DateCreated,'D'-EMWH.DateDue,'S'-EMWH.DateSched
* @begdate 
* @enddate 
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*****************************************************************************/
(@emco bCompany = null, 
@begwo bWO = null,
@endwo bWO = null,
@jcco bCompany = null, 
@job varchar(10) = null, 
@location varchar (10) = null,
@category varchar(10) = null,
@department varchar(10) = null, 
@assignedshop varchar(20) = null, 
@prco bCompany = null, 
@mechanic bEmployee = null,
@datesearchoption varchar(1) = null,
@begdate bDate = null,
@enddate bDate = null,  
@errmsg varchar(255) output)
    
 as
 
set nocount on

declare @rcode int

select @rcode = 0

If @emco is null
begin
	select @errmsg = 'Missing EM Company',@rcode =1 
	goto vspexit
end

If IsNull(@begwo,'') = ''
begin
	select @begwo = ''
end
If IsNull(@endwo,'') = ''
begin
	select @endwo = 'zzzzzzzzzz'
end    
 

--Create # table to hold all Work Order data.
create table #SelectedWorkOrders
(UpdateYN varchar(1), FailedYN varchar(1),
WorkOrder varchar(10) null,Description varchar(120) null,
Equipment varchar(10) null,EquipmentDesc varchar(120) null,
Hours decimal (12,2) null, CurrentHours decimal (12,2) null, TtlHours decimal (12,2),TtlHrsAsOfDate smalldatetime,
Odometer decimal(12,2) null, CurrentOdo decimal (12,2) null, TotalOdo decimal(12,2),TtlOdoAsOfDate smalldatetime,
Shop varchar(20)null,ShopDesc varchar(120) null,PRCo int null, Mechanic int null,Name varchar(200) null,
Created smalldatetime null,Scheduled smalldatetime null,Due smalldatetime null,WONotes varchar(max) null)

Insert Into #SelectedWorkOrders( UpdateYN, FailedYN, WorkOrder, Description, Equipment,EquipmentDesc, 
Hours,CurrentHours,TtlHours,TtlHrsAsOfDate,Odometer,CurrentOdo,TotalOdo,TtlOdoAsOfDate,
Shop, ShopDesc,PRCo, Mechanic, Name,Created,Scheduled,Due,WONotes)

Select Distinct  'N','N',h.WorkOrder,h.Description,h.Equipment,e.Description,
null,IsNull(e.HourReading,0),(IsNull(e.HourReading,0)+IsNull(e.ReplacedHourReading,0)),e.HourDate,
null,IsNull(e.OdoReading,0),(IsNull(e.OdoReading,0)+IsNull(e.ReplacedOdoReading,0)),e.OdoDate,
h.Shop,s.Description,h.PRCo,h.Mechanic,IsNull(m.FirstName,'') + ' ' + IsNull(m.LastName,''), h.DateCreated,h.DateSched,h.DateDue,h.Notes
from dbo.EMWH h with(nolock) 
Inner join dbo.EMEM e with(nolock)on e.EMCo = h.EMCo and e.Equipment = h.Equipment
Inner join dbo.EMWI i with(nolock)on e.EMCo = i.EMCo and i.WorkOrder = h.WorkOrder and i.Equipment = h.Equipment
Left Join dbo.EMSX s with(nolock)on s.ShopGroup=h.ShopGroup and  s.Shop=h.Shop
Left Join dbo.PREH m with(nolock)on m.PRCo= h.PRCo and m.Employee = h.Mechanic
Left Join dbo.EMWS w with(nolock)on w.EMGroup=i.EMGroup and w.StatusCode=i.StatusCode
where h.EMCo=@emco and e.EMCo=@emco and e.Status <>'I' and h.Complete = 'N' and
h.WorkOrder >= @begwo and h.WorkOrder <= @endwo 
and IsNull(h.Shop,'') = Isnull(@assignedshop,IsNull(h.Shop,''))and 
IsNull(h.PRCo,'') = IsNull(@prco,IsNull(h.PRCo,'')) and IsNull(h.Mechanic,'')=IsNull(@mechanic,IsNull(h.Mechanic,''))and
IsNull(e.JCCo,'') = IsNull(@jcco,IsNull(e.JCCo,'')) and IsNull(e.Job,'') = IsNull(@job,IsNull(e.Job,''))  and
IsNull(e.Location,'')= IsNull(@location,IsNull(e.Location,'')) and
Isnull(e.Category,'') = IsNull(@category,IsNull(e.Category,'')) and IsNull(e.Department,'')=IsNull(@department,Isnull(e.Department,'')) and
IsNull(h.DateCreated,'1/1/1950') >= case when @datesearchoption= 'C' then @begdate else IsNull(h.DateCreated,'1/1/1950') end and 
IsNull(h.DateCreated,'12/1/2060') <= case when @datesearchoption= 'C' then @enddate else Isnull(h.DateCreated,'12/1/2060') end and 
IsNull(h.DateSched,'1/1/1950') >= case when @datesearchoption= 'S' then @begdate else IsNull(h.DateSched,'1/1/1950') end  and 
IsNull(h.DateSched,'12/1/2060') <= case when @datesearchoption= 'S' then @enddate else IsNull(h.DateSched,'12/1/2060') end and 
IsNull(h.DateDue,'1/1/1950') >= case when @datesearchoption= 'D' then @begdate else IsNull(h.DateDue,'1/1/1950') end and
IsNull(h.DateDue,'12/1/2060') <= case when @datesearchoption= 'D' then @enddate else IsNull(h.DateDue,'12/1/2060') end 
and w.StatusType <> 'F'

if @@rowcount = 0
begin
	select @errmsg = 'No Work Orders found', @rcode=1
	goto vspexit
end

select * from #SelectedWorkOrders Order by WorkOrder
     
vspexit:
    
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspEMWOMassUpdateWorkOrder] TO [public]
GO
