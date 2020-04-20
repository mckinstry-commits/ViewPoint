SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE                                     proc [dbo].[vspEMWOInitMatchingSMGGridFill]
/****************************************************************************
* CREATED BY: 	TRL 05/08 EMWO Init update
* MODIFIED BY:  TRL 06/10/08 issue
*				TRL 08/20/08 issue 129510 added AllSMG smg item initialization
*				TRL 09/22/08 Issue 126911 Init if no last date for SMG Item types H,G,M
*				TRL 09/22/08 Issue 129340 Changes Month to Days for Fixed data calc
*				TRL 11/12/08 Issue 131050 Add IsNull around JCCo for cursor  btcEquipToCopy
*				TRL 01/21/08 Issue 130063 Add code to included SMGs when beg/end smg have values
*				TRL 02/11/09 Issue 131029 Change the Last Done Date column is filled for display info
*				TRL 02/11/09 Issue 131450 Removed after getting SMG Item info that prevented the Item from checked
*								to see if it was due for maintenance
*				TRL 02/25/08 Issue 131745 If interval days from SMG is null or zero SMG will only be selected 
*				when hours, miles or gallons meet slection criteria
*				TRL 04/09/09 Issue 132439 Added Itesm Selected to output
*				  TRL 12/23/09 Issue 136713 added replaced meter to due calcuation
*				TRL 02/05/10 Issue 138584  update Description Col to 60
*				TRL 03/22/10 Issue 138227 Fix SMI  due calc when Equipment has replaced meter
*				JVH 11/8/10 Issue 141618 Removed unused variable @last_wo_date that was being set by a select statement that was causing a ANSI_WARNING message
*				LDG 05/13/11 Issue 143898 Changed logic to assume that if a smi doesnt have a last donedate then the readings are for the current meter. Removed is null wrapper for @lastdonedate
*				JVH 6/1/11 Issue 143322 Simplified the hour and odometer logic by capturing the replaced meter reading at the time of updating the last done information and used it in the comparison.
*				GF 01/31/2013 TFS-38171 test date add function with variance before using as a small date time
*				GF 04/26/2013 TFS-48552 EMSH/EMSI expanded descripitons
*
*
* USAGE:
* 	Returns recordset describing StdMaintGroups/Items due per various
*	criteria.
*
* INPUT PARAMETERS:
*	EM Company
*	WODate - for new Work Orders
*   JC Company/Job - optional criteria
*	Location - optional criteria
*	Category - optional criteria
*	Department - optional criteria
*	Shop - optional criteria
*	Equipment - optional criteria
*  StdMaintGroup - optional criteria
*	Days in Advance
*	Variances in Advance
*
* OUTPUT PARAMETERS:
*	Recordset containing records in #DisplaySMGInfo
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*****************************************************************************/
(@emco bCompany = null,
@wodate bDate = null,
@jcco bCompany = null,
@job bJob = null,
@location bLoc=null,
@category bCat=null,
@department bDept=null,
@shop varchar(20)=null,
@equipment bEquip=null,
@stdmaintgroup varchar(10)=null,
@maxstdmaintgroup varchar(10)=null,
@daysinadvance int = null, 
@variancesinadvance int = null)
     
as
     
set nocount on

declare @rcode integer,@curryr varchar(4),
/*Company  variables*/
@shopgroup bGroup,@emgroup bGroup,@smgall bYN,
/*Equipment/Component Std MaintGroup*/
@opencursorgroup int,@equipcopy bEquip,	 @compofequip varchar(10), @smgcopy varchar(10),
/*Equipment/Component variables*/
@equipdesc bItemDesc/*135894*/, @fuelused numeric(12,3), @equiptype char(1),@equipshop varchar(20),
@hourreading numeric(10,2),@replacedhourreading numeric(10,2), @odoreading numeric(10,2), @replacedodoreading numeric(10,2),
/*Std Maint Group variables*/
----TFS-48552
@smgdescription bItemDesc, @intervaldays smallint,@fixeddatemonth varchar(2),@fixeddateday varchar(2),@basis char(1),
@interval int,@variance int, /*133289*/@createWOdaysprior int/*133289*/,
/*Std Maint item variables*/
@opencursoritem int,@iEquipment bEquip,@iStdMaintGroup varchar(10),@iStdMaintItem smallint,
@lastdonedate smalldatetime,@lasthourmeter numeric(10,2), @lastreplacedhourmeter numeric(10,2), @lastodometer numeric(10,2), @lastreplacedodometer numeric(10,2), @lastgallons numeric(12,3),
/*Calculation and Display Variables*/
@fixeddate smalldatetime,@fixeddate1 smalldatetime,@fixeddate2 smalldatetime,
@childoflinks varchar(60),@parentoflinks varchar(60),
@totalitems int,
@replacedhourdate smalldatetime,@replacedododate smalldatetime
----TFS-38171
,@DateDone DATETIME, @IntervalDate DATETIME, @WorkOrderDate DATETIME



--Create table variable for final list of Equipment 
----TFS-48552
create table #DisplaySMGInfo(Equipment varchar(10) null, StdMaintGroup varchar(10) null, SMGDesc varchar(60) null, 
ParentOfLinks varchar(60),LinkedTo varchar(60), Selected char(1) null, 
Failed char(1) null, Results varchar(255),EquipDesc varchar(60) null,EquipType char(1) null, 
EquipShop varchar(20), Component varchar(10) null, Basis char(1) null,
itemLastDoneDate smalldatetime null,LastDoneDate smalldatetime null,TotalItems int)
/* Issue 130063 */
Create table #SelectedSMGs (EMCo tinyint null,Equipment varchar(10) null, 
		CompOfEquip varchar(10) null, StdMaintGroup varchar(10) null)
/* Issue 130063 */

--Issue 25843
--select @rcode = 0,
select @rcode = 0, @curryr = convert(varchar(4),datepart(yy,@wodate)),@opencursorgroup=0,@opencursoritem=0

--Get ShopGroup,EMGroup from bHQCO for @emco 
select  @shopgroup = HQCO.ShopGroup, @emgroup = HQCO.EMGroup , @smgall = AllSMG
from dbo.EMCO with(nolock)
Inner Join dbo.HQCO with(nolock)on HQCO.HQCo=EMCO.EMCo
where EMCO.EMCo = @emco

select @stdmaintgroup = isnull(@stdmaintgroup,'')   
select @maxstdmaintgroup = isnull(@maxstdmaintgroup,'zzzzzzzzzz')
     
Insert Into #SelectedSMGs(EMCo,Equipment,CompOfEquip,StdMaintGroup)
select distinct s.EMCo,s.Equipment,m.CompOfEquip,s.StdMaintGroup
from dbo.EMSH s with(nolock) 
Inner Join dbo.EMEM m with(nolock) on m.EMCo = s.EMCo and m.Equipment=s.Equipment
left Join dbo.EMEM ce with(nolock) on ce.EMCo = m.EMCo and ce.Equipment=m.CompOfEquip
where s.EMCo = @emco and m.Status <> 'I' and  s.StdMaintGroup >= @stdmaintgroup and s.StdMaintGroup <= @maxstdmaintgroup  and
IsNull(m.CompOfEquip,m.Equipment) = IsNull(@equipment,IsNull(m.CompOfEquip,m.Equipment))and
/*Brief description: First it test if the parameter is null. If not, it then look to see if the Equipment
is a compnent type. It must decide if it needs to match the info for the Component ot the Master Equipment.*/
IsNull(IsNull(ce.JCCo,m.JCCo),'')=IsNull(IsNull(@jcco,IsNull(ce.JCCo,m.JCCo)),'')/*131050*/ and 
IsNull(ce.Job,IsNull(m.Job,''))=IsNull(@job,IsNull(ce.Job,IsNull(m.Job,''))) and
IsNull(ce.Location,Isnull(m.Location,''))=IsNull(@location,IsNull(ce.Location,IsNull(m.Location,''))) and 
IsNull(ce.Category,IsNull(m.Category,''))=IsNull(@category,IsNull(ce.Category,IsNull(m.Category,''))) and
IsNull(ce.Department,IsNull(m.Department,''))=IsNull(@department,IsNull(ce.Department,IsNull(m.Department,''))) and 
IsNull(ce.Shop,IsNull(m.Shop,''))=IsNull(@shop ,IsNull(ce.Shop,IsNull(m.Shop,'')))  

/* Issue 130063 */
If IsNull(@stdmaintgroup,'') <> '' or @maxstdmaintgroup <> 'zzzzzzzzzz' 
begin
	Insert Into #SelectedSMGs (EMCo,Equipment,CompOfEquip,StdMaintGroup)
	select distinct s.EMCo,s.Equipment,s.CompOfEquip,l.LinkedMaintGrp
	from #SelectedSMGs s with(nolock) 
	Inner Join dbo.EMEM m with(nolock) on m.EMCo = s.EMCo and m.Equipment=s.Equipment
	Inner Join dbo.EMSL l with(nolock) on l.EMCo=s.EMCo and l.Equipment=s.Equipment and l.StdMaintGroup=s.StdMaintGroup
end
/* Issue 130063 */

--Cursor to run through the needed SMGs
declare  btcEquipToCopy cursor local fast_forward for
select Distinct Equipment,CompOfEquip,StdMaintGroup from #SelectedSMGs

open btcEquipToCopy
select @opencursorgroup=1

FetchNextGroup:
fetch next from btcEquipToCopy into @equipcopy, @compofequip, @smgcopy
if @@fetch_status<> 0 
begin
	goto EndNextStdMaintGroup
end
	--get Equipment/Component info needed for selection comparisons. 
    select @equipdesc = Description, @hourreading = isnull(HourReading,0), @replacedhourreading = isnull(ReplacedHourReading,0),
    @odoreading = isnull(OdoReading,0),@replacedodoreading = isnull(ReplacedOdoReading,0),
    @fuelused = isnull(FuelUsed,0), @equiptype = EMEM.Type, /*@compofequip = CompOfEquip,*/ @equipshop = Shop,
    @replacedhourdate = ReplacedHourDate ,@replacedododate = ReplacedOdoDate
    from dbo.EMEM with(nolock)
    where EMCo = @emco and Equipment = @equipcopy
    
     select @totalitems = 0
     
	--get Std Maint Group info needed for selection comparisons for Equipment or Component. 
    select @smgdescription= Description, @intervaldays = isnull(IntervalDays,0), 
	@fixeddatemonth = convert(varchar(12),FixedDateMonth),@fixeddateday = convert(varchar(12),FixedDateDay),
	@basis = Basis, @interval = isnull(Interval,0),@variance = isnull(Variance,0),
	/*133289*/@createWOdaysprior = isnull(CreateWOdaysprior,@daysinadvance)
	from dbo.EMSH with(nolock)
    where EMCo = @emco and Equipment = @equipcopy and StdMaintGroup = @smgcopy
     
     select @totalitems = count(*) 	from dbo.EMSI with(nolock)
    where EMCo = @emco and Equipment = @equipcopy and StdMaintGroup = @smgcopy

	--Declare and open cursor, run through SMGItemsToInitialize
	declare cItemsToInit cursor local fast_forward for
	select i.Equipment,i.StdMaintGroup,i.StdMaintItem
	from dbo.EMSI i with(nolock)  
	where i.EMCo = @emco  and  i.Equipment = @equipcopy and i.StdMaintGroup = @smgcopy 
			
	--open cursor
	open cItemsToInit
	select @opencursoritem = 1

	goto NextStdMaintItem
	NextStdMaintItem:
	fetch next from cItemsToInit into @iEquipment,@iStdMaintGroup,@iStdMaintItem
	if (@@fetch_status <> 0)
	begin
		goto EndNextStdMaintItem
	end

	--Issue 127255 fix
	--Only SMG Items Not on an Open WorkOrder can be select to be initialized.
	If IsNull(@compofequip,'') = ''
		--Check For Equipment Only, Check to see if SMG/SMG Item is currently on a open work order.
		--Skip to Next SMG Item if on an open work order
		begin
			if exists (select top 1 1 from dbo.EMSI g with(nolock)
			inner join dbo.EMWI i with(nolock)on g.EMCo = i.EMCo and g.Equipment = i.Equipment and g.StdMaintGroup = i.StdMaintGroup and g.StdMaintItem = i.StdMaintItem
   			inner join dbo.EMWS s with(nolock)on i.EMGroup = s.EMGroup and i.StatusCode = s.StatusCode  
			where i.EMCo = @emco and i.Equipment = @iEquipment and isnull(i.Component,'') = ''
			and i.StdMaintGroup = @iStdMaintGroup and i.StdMaintItem = @iStdMaintItem and s.StatusType <> 'F')
			begin
   				goto NextStdMaintItem
	   		end
		end
	else
		--Check For Component/ Compof Equipment Only, Check to see if SMG/SMG Item is currently on a open work order.
		--Skip to Next SMG Item if on an open work order
		begin
			if exists (select top 1 1 from dbo.EMSI g with(nolock)
			inner join dbo.EMWI i with(nolock)on g.EMCo = i.EMCo and g.Equipment = i.Component and g.StdMaintGroup = i.StdMaintGroup and g.StdMaintItem = i.StdMaintItem
   			inner join dbo.EMWS s with(nolock)on i.EMGroup = s.EMGroup and i.StatusCode = s.StatusCode  
			where i.EMCo = @emco and i.Equipment = @compofequip and i.Component = @equipcopy and g.Equipment=@equipcopy
			and i.StdMaintGroup = @iStdMaintGroup and i.StdMaintItem = @iStdMaintItem and s.StatusType <> 'F')
			begin
   				goto NextStdMaintItem
			end
	     end

		--get info needed for selection comparisons. 
        select @lastdonedate = LastDoneDate,																		 
		@lasthourmeter = isnull(LastHourMeter,0), @lastreplacedhourmeter = ISNULL(LastReplacedHourMeter ,0), @lastodometer = isnull(LastOdometer,0), @lastreplacedodometer = ISNULL(LastReplacedOdometer, 0), @lastgallons = isnull(LastGallons,0)
        from dbo.EMSI with(nolock)
        where EMCo = @emco and Equipment = @equipcopy and StdMaintGroup = @smgcopy and StdMaintItem = @iStdMaintItem
		
		--Check to see if the equipment should be done base on the interval of days.
		----TFS-38171 test the date first to see if within small date time range
		SET @DateDone = ISNULL(@lastdonedate, '01/01/1950')
		SET @WorkOrderDate = CAST(@wodate AS DATETIME)
		IF @basis IN ('H','M','G') AND ISNULL(@intervaldays,0) <> 0
			BEGIN
			SELECT @IntervalDate = DATEADD(DAY, @intervaldays - ISNULL(@daysinadvance,0), @DateDone)
			---- validate date range
			IF @IntervalDate BETWEEN '19000101 00:00:00.000' AND '20790606 23:59:29.997'
						AND @WorkOrderDate >= @IntervalDate
						BEGIN
						GOTO docopy
						END
			END
		--if @basis IN ('H','M','G') AND IsNull(@intervaldays,0) <> 0 AND @wodate >= dateadd(day,@intervaldays-isnull(@daysinadvance,0),IsNull(@lastdonedate,'01/01/1950'))
		--begin
		--	goto docopy
		--end

		/* Selection comparisons and Examine by Basis from StdMaintGroup. */
		--Hours
		if @basis = 'H'
		begin
			if @hourreading + @replacedhourreading >= @lasthourmeter + @lastreplacedhourmeter + @interval - (@variance * @variancesinadvance) 
			begin
				goto docopy
			end
		end
		--Miles
		if @basis = 'M'
		begin
			if @odoreading + @replacedodoreading >= @lastodometer + @lastreplacedodometer + @interval - (@variance * @variancesinadvance) 
			begin
				goto docopy
			end
       	end
		--Gallons
		if @basis = 'G'
		begin
			if @fuelused >= @lastgallons + @interval - (@variance * @variancesinadvance)
			begin
				goto docopy
			end
       	end
		/* Issue 131745 end */

		--Fixed Date
		--129611 Item has never been done, initialize
		if @basis = 'F'
		begin
			-- The fixed date represnts the earliest an item is due. The later the date the more likely
			-- something is due.
		
			SELECT @createWOdaysprior = ISNULL(@createWOdaysprior,1),
				-- The fixed date should take into account the days prior with the work order date
				@fixeddate = @fixeddatemonth+'/'+@fixeddateday +'/'+ CAST(DATEPART(yy, DATEADD(dd, @createWOdaysprior, @wodate)) AS VARCHAR)

			-- Any fixed date in the future should have a year subtracted
			-- from it because everything is due in the future
			-- We take into account how many days in advance they want to see when things are due
			IF DATEADD(dd, @createWOdaysprior, @wodate) < @fixeddate
			BEGIN
				--Ensure that the due date is before the Work Order date since we are only looking at 
				--items that could be due up to the Work Order date - the days prior
				SET @fixeddate = DATEADD(yy, -1, @fixeddate)
			END
			
			-- Add 45 days in case the work order was done early
			IF DATEADD(dd, 45, ISNULL(@lastdonedate,'01/01/1950')) < @fixeddate
			BEGIN
				GOTO docopy
			END
		end
		--If we don't reach a do copy by this point, skip to next SMG Item
		goto NextStdMaintItem
		docopy:
			--Read any linked SMG's as children of or parents of this SMG and list in columns in #DisplaySMGInfo 
     	select @parentoflinks = '', @childoflinks = ''
     
     	select @parentoflinks = h.StdMaintGroup
     	from dbo.EMSH h with(nolock)
		Inner Join dbo.EMSL L with(nolock)on h.EMCo=L.EMCo and h.Equipment=L.Equipment and h.StdMaintGroup=L.StdMaintGroup
     	where L.EMCo=@emco and L.Equipment = @equipcopy and L.StdMaintGroup = @smgcopy
     		
     	--    Second: LinkedTo 
     	select @childoflinks = L.StdMaintGroup, @parentoflinks = IsNull(@parentoflinks,L.StdMaintGroup)
		from dbo.EMSL L with(nolock)
		Left Join dbo.EMSH h with(nolock)on h.EMCo=L.EMCo and h.Equipment=L.Equipment and h.StdMaintGroup=L.StdMaintGroup
		where L.EMCo = @emco and L.Equipment = @equipcopy and L.LinkedMaintGrp = @smgcopy
		
		--ParentLink required for sorting out, need for non linked Std Maint Groups
		If Isnull(@parentoflinks,'') = ''
		begin
			select @parentoflinks = @smgcopy
		end
	
		begin
		-- Copy record to #DisplaySMGInfo. 
     		insert #DisplaySMGInfo (Equipment, StdMaintGroup, SMGDesc, ParentOfLinks, LinkedTo, Selected, Failed,
       		Results, EquipDesc, EquipType, EquipShop, Component, Basis, itemLastDoneDate,TotalItems)

			select Equip = case @equiptype when 'E' then @equipcopy else @compofequip end ,
			@smgcopy, @smgdescription, @parentoflinks, @childoflinks,'Y', 'N', 
			null, @equipdesc, @equiptype, @equipshop, 
			Comp = case @equiptype when 'E' then '' else @equipcopy end,
			@basis, ISNULL(@lastdonedate,''),@totalitems

			/*131029 remvoved; goto EndNextStdMaintItem */
     	end
		--Cycle through Item until first Item do
		goto NextStdMaintItem
		
		EndNextStdMaintItem:
		If @opencursoritem = 1
		begin
			close cItemsToInit
			deallocate cItemsToInit
			select @opencursoritem = 0
		End
		
		goto FetchNextGroup

EndNextStdMaintGroup:
If @opencursorgroup = 1
begin
	close btcEquipToCopy
	deallocate btcEquipToCopy
    select @opencursorgroup = 0
end;

/*131029*/
With SMGLastDoneDate (Equipment,Component,StdMaintGroup,displaydate) as
(Select Equipment,Component,StdMaintGroup,displaydate = Min(itemLastDoneDate)
From #DisplaySMGInfo Where IsNull(itemLastDoneDate,'') <> ''
 Group by Equipment,Component,StdMaintGroup)

Update #DisplaySMGInfo 
set LastDoneDate = b.displaydate
From #DisplaySMGInfo as a
Inner Join SMGLastDoneDate as b on b.Equipment=a.Equipment and b.Component=a.Component and b.StdMaintGroup= a.StdMaintGroup;
/*131029*/

-- Return recordset to VB. 
--121437
--132439
select Equipment,Component, StdMaintGroup, SMGDesc, LinkedTo, Selected, Failed,
Results, EquipDesc, EquipType, EquipShop,  Basis, LastDoneDate,ItemsDue=count(*),
ItemsNotDue = case when TotalItems >= count(*) then TotalItems-count(*) else 0 end 
from #DisplaySMGInfo 
Group by  Equipment,Component, StdMaintGroup, SMGDesc, LinkedTo, Selected, Failed,
Results, EquipDesc, EquipType, EquipShop, Basis, LastDoneDate,TotalItems




vspexit:
If @opencursoritem = 1
begin
	close cItemsToInit
	deallocate cItemsToInit
End
If @opencursorgroup = 1
begin
	close btcEquipToCopy
	deallocate btcEquipToCopy
end
return @rcode





GO
GRANT EXECUTE ON  [dbo].[vspEMWOInitMatchingSMGGridFill] TO [public]
GO
