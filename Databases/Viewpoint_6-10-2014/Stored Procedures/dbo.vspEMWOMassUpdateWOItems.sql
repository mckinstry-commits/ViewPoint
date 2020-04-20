SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMWOMassUpdateWOItems]
/****************************************************************************
* CREATED BY: 	TRL 02/03/09 Issue 129069 New form EM Work Order Mass Update
* MODIFIED BY:  JVH 6/20/11 TK-05982 Output current component hour + miles so we can use them for updating
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
	
If IsNull(@begdate,'') = ''
begin
	select @begdate = '01/01/1950'
end
If IsNull(@enddate,'') = ''
begin
	select @enddate = '12/31/2050'
end    

--Create # table to hold all Work Order data.
create table #SelectedWOItems
(UpdateYN varchar(1), FailedYN varchar(1),UpdateResults varchar(255),
WorkOrder varchar(10) null,WOItem int, Description varchar(120) null,
Equipment varchar(10) null,Component varchar(10) null,StdMaintGroup varchar(10),StdMaintItem int,
PRCo int null, Mechanic int null,Name varchar(200) null,StatusCode varchar(10),StatusType varchar(10),
CompleteDate smalldatetime null ,RepairType varchar(10),Hours decimal (12,2) null,TotalHours decimal(12,2) null,
Odometer decimal(12,2) null,TotalOdo decimal(12,2),
cCurrentHours decimal,cTtlHours decimal,cTtlHrsAsOfDate smalldatetime,cCurrentOdo decimal,cTotalOdo decimal,cTtlOdoAsOfDate smalldatetime,
WOItemNotes varchar(max)null)

Insert Into #SelectedWOItems(UpdateYN,FailedYN,UpdateResults,WorkOrder,WOItem ,Description,
Equipment,Component,StdMaintGroup,StdMaintItem,PRCo,Mechanic,Name,StatusCode,StatusType,
CompleteDate,RepairType,Hours,TotalHours,Odometer,TotalOdo,cCurrentHours,cTtlHours,cTtlHrsAsOfDate,cCurrentOdo,cTotalOdo,cTtlOdoAsOfDate,WOItemNotes)
Select 'N','N',null,i.WorkOrder,i.WOItem,i.Description,i.Equipment,i.Component,i.StdMaintGroup,i.StdMaintItem,
i.PRCo,i.Mechanic,case when i.Mechanic is null then '' else IsNull(m.LastName,'') + ', ' + IsNull(m.FirstName,'')+ ' '+IsNull(MidName,'')end,
 i.StatusCode,s.StatusType,i.DateCompl,i.RepairType,
i.CurrentHourMeter,i.TotalHourMeter,i.CurrentOdometer,i.TotalOdometer,
IsNull(c.HourReading,0),(IsNull(c.HourReading,0)+IsNull(c.ReplacedHourReading,0)),c.HourDate,
IsNull(c.OdoReading,0),(IsNull(c.OdoReading,0)+IsNull(c.ReplacedOdoReading,0)),c.OdoDate,i.Notes
from dbo.EMWI i with(nolock) 
Inner join dbo.EMWH h with(nolock)on h.EMCo = i.EMCo and h.WorkOrder = i.WorkOrder and h.Equipment = i.Equipment
Inner join dbo.EMEM e with(nolock)on e.EMCo = i.EMCo and e.Equipment = i.Equipment
Left Join dbo.EMWS s with(nolock)on s.EMGroup=i.EMGroup and s.StatusCode=i.StatusCode
Left join dbo.EMEM c with(nolock)on c.EMCo = i.EMCo and c.Equipment = i.Component
Left Join dbo.PREH m with(nolock)on m.PRCo= i.PRCo and m.Employee = i.Mechanic
where i.EMCo=@emco and e.EMCo=@emco and e.Status <>'I' and h.Complete = 'N' and
i.WorkOrder >= @begwo and i.WorkOrder <= @endwo and IsNull(h.Shop,'') = Isnull(@assignedshop,IsNull(h.Shop,''))and 
IsNull(h.PRCo,'') = IsNull(@prco,IsNull(h.PRCo,'')) and IsNull(h.Mechanic,'')=IsNull(@mechanic,IsNull(h.Mechanic,'')) and
IsNull(e.JCCo,'') = IsNull(@jcco,IsNull(e.JCCo,'')) and IsNull(e.Job,'') = IsNull(@job,IsNull(e.Job,'')) and
IsNull(e.Location,'')= IsNull(@location,IsNull(e.Location,'')) and
Isnull(e.Category,'') = IsNull(@category,IsNull(e.Category,'')) and IsNull(e.Department,'')=IsNull(@department,Isnull(e.Department,'')) and
IsNull(h.DateCreated,'1/1/1950') >= case when @datesearchoption= 'C' then @begdate else IsNull(h.DateCreated,'1/1/1950') end and 
IsNull(h.DateCreated,'12/1/2060') <= case when @datesearchoption= 'C' then @enddate else Isnull(h.DateCreated,'12/1/2060') end and 
IsNull(h.DateSched,'1/1/1950') >= case when @datesearchoption= 'S' then @begdate else IsNull(h.DateSched,'1/1/1950') end and 
IsNull(h.DateSched,'12/1/2060') <= case when @datesearchoption= 'S' then @enddate else IsNull(h.DateSched,'12/1/2060') end and 
IsNull(h.DateDue,'1/1/1950' ) >= case when @datesearchoption= 'D' then @begdate else IsNull(h.DateDue,'1/1/1950') end and
IsNull(h.DateDue,'12/1/2060') <= case when @datesearchoption= 'D' then @enddate else IsNull(h.DateDue,'12/1/2060') end and
s.StatusType <> 'F'
       
if @@rowcount = 0
begin
	select @errmsg = 'No Work Orders found', @rcode=1
	goto vspexit
end

select * from #SelectedWOItems Order by WorkOrder
     
vspexit:
    
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspEMWOMassUpdateWOItems] TO [public]
GO
