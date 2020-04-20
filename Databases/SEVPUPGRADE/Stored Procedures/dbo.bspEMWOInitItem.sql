SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE          procedure [dbo].[bspEMWOInitItem]
/*******************************************************************
* CREATED: 12/4/98 JM
* LAST MODIFIED: 7/2/99 JM - Added MatlGroup to 'insert #PartsToCopy'
*	            statement to reflect table change, approx line 190.
*               9/27/99 JM - Corrected where clause in insert statement to
*               #PartsToCopy to pull parts for Component or Equipment as
*               applicable for WOItem, determined by @componenttypecode.
*               Ref Issue 4930.
*               JM 2/14/00 Added insertion of bEMWH.INCo to EMWP via #PartsToCopy.
*               Ref Issue 6259.
*              JM 3/29/00 - Moved selection of WODefaultRepType to this procedure
*              so primary default can be from bEMSI with secondary from bEMCO.
*              Ref Issue 6618.
*              TV 04/14/03 added @@rowcount to EMWI insert Issue 20724
*              TV 06/27/03 21618 Removed debug code. Not needed and may have been causing problems
*              TV 06/27/03 21618 Pass INCo and InvLoc to EMWP
*			TV 02/11/04 - 23061 added isnulls 
*			TRL 02/07/08 - 127340 added isnull for @componettype, @equiptype and added auto sequencing for 
*			for EMWP.Seq
*			TRL 03/20/08 - 27172 add PRCo parameter for input for EMWI PRCo
*			TRL 01/18/10 - 135894 updated procedure for creating EMWP Records
*			GP	04/23/10 - 138980 changed temp table description to varchar(60)
*
* USAGE: Called by bspEMWOInit to initalize a WOItem and associated
*	parts for a new WO.
*
* INPUT PARAMS:
*	@emco			      EM Company
*	@workorder		      Work Order
*	@equipment		      Equipment
*	@componenttypecode	  Component Type Code
*	@component		      Component
*	@emgroup		      EM Group
*	@stdmaintgroup		  Std Maint Group
*	@stdmaintitem		  Std Maint Item
*	@repaircode		      Repair Code
*	@defmechanic		  Default Mechanic
*   @datecreated          Default Date Created
*	@defdatedue		      Default Date Due
*	@defdatesched		  Default Date Scheduled
*	@wobeginpartstatus	  Beginning Parts Status
*	@wobeginstat		  Beginning WO Status
*
* OUTPUT PARAMS:
*	@rcode			Return code; 0 = success, 1 = failure
*	@errmsg			Error message if failure
********************************************************************/

(@emco bCompany = null,
@workorder bWO = null,
@equipment bEquip = null, /* Parent Equipment if a Component. */
@componenttypecode varchar(10) = null,
@component bEquip = null,
@emgroup bGroup = null,
@stdmaintgroup varchar(10) = null,
@stdmaintitem bItem,
@repaircode varchar(10) = null,
@defprco bCompany = null,/*27172*/
@defmechanic bEmployee = null,
@defdatecreated bDate = null,
@defdatedue bDate = null,
@defdatesched bDate = null,
@wobeginpartstatus varchar(10),
@wobeginstat varchar(10),
@equiptype char(1),
@inco bCompany = null,
@invloc bLoc = null,
@errmsg varchar(255) output)

as

set nocount on
    
--declare locals
declare @rcode int,@numrows smallint,@newwoitem smallint,@wodefaultreptype varchar(10),
@componenterrmsg varchar(255),@matltocopy bMatl, @linkedhqmatl bMatl,
/*@inco bCompany,@invloc bLoc,*/@inmatlgroup bGroup,  @hqmatlgroup bGroup, @ValidMaterialRequiredYN bYN 
 

select @rcode = 0, @componenterrmsg = ''

If IsNull(@component,'')='' 
	begin
		select  @componenterrmsg = ', Component:  ' + @component
	end    
else
	begin
		select  @componenterrmsg = ''
	end
--verify parameters passed
if @emco is null
begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
    goto bspexit
end

if IsNull(@workorder,'')=''
begin
	select @errmsg = 'Missing Work Order!', @rcode = 1
	goto bspexit
end
if IsNull(@equipment,'')=''
begin
	select @errmsg = 'Missing Equipment!', @rcode = 1
    goto bspexit
end

if @emgroup is null
begin
	select @errmsg = 'Missing EM Group!', @rcode = 1
    goto bspexit
end
if @wobeginpartstatus is null
begin
	select @errmsg = 'Missing WO Begin Part Status!', @rcode = 1
    goto bspexit
end
if @wobeginstat is null
begin
	select @errmsg = 'Missing WO Begin Status!', @rcode = 1
	goto bspexit
end
if IsNull(@equiptype,'')=''
begin
	select @errmsg = 'Missing Equipment Type!', @rcode = 1
    goto bspexit
end
    
--Create a # table for Parts to be copied from bEMSP to bEMWP.
--Use select into so we can retrieve the Notes column and any
--User Memo columns. Note that this table is a copy of the
--table that will eventually receive the records, EMWP, and
--some columns must be set as nullable to receive records
--without key values.
CREATE TABLE #PartsToCopy
      (EMCo tinyint NULL,
      WorkOrder varchar(10) NULL,
      WOItem smallint NULL,
      MatlGroup tinyint NULL,
      Material varchar(20) NULL,
      Equipment varchar(10) NULL,
      EMGroup tinyint NULL,
      PartsStatusCode varchar(10) NULL,
      InvLoc varchar(10) NULL,
      Description varchar(60) NULL,
      UM varchar(3) NULL,
      QtyNeeded float NULL,
      PSFlag char(1) NULL,
      Required char(1) NULL,
      INCo tinyint NULL,
	  Seq int null)
    
--Get INCo for @emco\@workorder.
--select @inco = INCo, @invloc = InvLoc from dbo.EMWH with(nolock) where EMCo = @emco and WorkOrder = @workorder 

--Get INCo's' Matl Group when INCo and Inv Loc have values
if @inco is not null and isnull(@invloc,'') <> ''
begin 
	select @inmatlgroup = MatlGroup from dbo.HQCO where HQCo=@inco
end 

--Get EMCo's HQ Matl Goup
select @hqmatlgroup = MatlGroup, @ValidMaterialRequiredYN = MatlValid 
from dbo.HQCO with(nolock)
inner join dbo.EMCO with(nolock) on EMCo=HQCo 
where HQCo=@emco
	
--Get default WORepairType from either bEMSI or bEMCO.
select @wodefaultreptype = isnull(s.RepairType,c.WODefaultRepType)
from dbo.EMSI s with(nolock)
inner join dbo.EMCO c on s.EMCo=c.EMCo 
where s.EMCo = @emco and s.StdMaintGroup = @stdmaintgroup and s.StdMaintItem = @stdmaintitem
and s.Equipment = case when @equiptype = 'E' then @equipment else @component end
    
--Get starting WOItem as 1 plus max WOItem in EMWI for EMCo and WorkOrder passed in 
select @newwoitem = isnull(max(WOItem),0) + 1 from dbo.EMWI with(nolock) where EMCo=@emco and WorkOrder = @workorder
    
--Insert StdMaintItem into bEMWI. Not Nullable in bEMWI: EMCo,
--WordOrder, WOItem, Equipment, EMGroup, CostCode, InHseSubFlag,
--StatusCode, DateCreated
insert dbo.EMWI (EMCo, WorkOrder, WOItem, Equipment, ComponentTypeCode,
 	Component, EMGroup, CostCode, StdMaintGroup, StdMaintItem,
   	Description, InHseSubFlag, StatusCode, RepairType, RepairCode,
   	/*27172*/PRCo, Mechanic, EstHrs, QuoteAmt, Priority, PartCode, SerialNo,
   	DateCreated, DateDue, DateSched, DateCompl, CurrentHourMeter,
   	TotalHourMeter, CurrentOdometer, TotalOdometer, FuelUse, Notes)
select @emco, @workorder, @newwoitem, @equipment, 
	CompTypeCode= case when IsNull(@component,'')=''then null else @componenttypecode end,
   	Comp = case when IsNull(@component,'')='' then null else @component end,
	@emgroup, CostCode, @stdmaintgroup, @stdmaintitem,
   	Description, IsNull(InOutFlag,'I'), @wobeginstat, @wodefaultreptype,@repaircode, 
	/*27172*/@defprco, @defmechanic, EstHrs, EstCost, 'N', null, null,
   	@defdatecreated, @defdatedue, @defdatesched, null, null, 
	null, null,null, null, Notes
from dbo.EMSI where EMCo = @emco and StdMaintGroup = @stdmaintgroup and StdMaintItem = @stdmaintitem
    and Equipment = case when IsNull(@component,'') = '' then @equipment else @component end
	if @@error <> 0 
begin 
	select @errmsg = 'Error Inserting WO Items for Equipment: '+ @equipment + @componenterrmsg  , @rcode = 1
	goto bspexit
end

if  (select top 1 1 from dbo.EMSP with(nolock) 
	where EMCo = @emco and StdMaintGroup = @stdmaintgroup and StdMaintItem = @stdmaintitem
    and Equipment = case when @equiptype='E' then @equipment else @component end ) >=1
begin
	--Insert Parts for StdMaintItem into #PartsToCopy without key values so
	--they can be easily updated with actual keys passed in. */
	insert #PartsToCopy (EMCo,EMGroup,WorkOrder,WOItem, Equipment,
	INCo,InvLoc,MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required, PartsStatusCode,
	Seq)
	select EMCo,@emgroup,@workorder,@newwoitem,case when IsNull(@componenttypecode,'')='' then @equipment else @component end,
	@inco, @invloc,MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required, @wobeginpartstatus,
	--Issue 127340
	row_number() over(partition by EMCo,StdMaintGroup,StdMaintItem order by EMCo,StdMaintGroup,StdMaintItem)as Seq
	from dbo.EMSP with(nolock) 
	where EMCo = @emco and StdMaintGroup = @stdmaintgroup and StdMaintItem = @stdmaintitem
	--Issue 127340
    and Equipment = case when @equiptype='E' then @equipment else @component end 
        
       --GP
       declare @i int
       set @i = 1
       while @i <= (select max(Seq) from #PartsToCopy)
       begin
        
	--Add final recordset to bEMWP. Not nullable in bEMWP: EMCo, WorkOrder,
    --WOItem, MtlGroup, Material, Equipment, EMGroup, PartsStatusCode, UM,
    --QtyNeeded, PSFlag, Required. Need to use a loop since there can be
    --more than one record returned by a subquery. */
   -- select @matltocopy = min(Material) from #PartsToCopy
  select @matltocopy = Material from #PartsToCopy where Seq=@i  --GP

		--Reset variable 
		select @linkedhqmatl=null
		
		--Check to see Matl to copy is a Equipment  Part Code's (@matltocopy) linked to a HQ Matl
	
		select @linkedhqmatl = HQMatl from dbo.EMEP with(nolock)
		where EMCo=@emco and Equipment = case when @equiptype='E' then @equipment else @component end 
		and PartNo=@matltocopy
		--Check, Does Part Code linkedhqmatl/@matltocopy exist in override INCo Location Materials
		If @inco is not null and isnull(@invloc,'') <>''	
			and exists (select top 1 1 from dbo.INMT with(nolock) where INCo=@inco and Loc = @invloc and  MatlGroup = @inmatlgroup and Material =  isnull(@linkedhqmatl,@matltocopy) ) 
				begin 
					---UM validation issues will occure in EM Work Order Edit Item Parts or other EM Batch Forms (design team decision)
					insert dbo.EMWP (EMCo,EMGroup,WorkOrder,WOItem,Equipment,
					INCo,InvLoc,MatlGroup,Material,Description,UM,QtyNeeded,PSFlag,Required,PartsStatusCode,Seq) 
					select EMCo,EMGroup,WorkOrder,WOItem,Equipment,
					 @inco,@invloc,@inmatlgroup,isnull(@linkedhqmatl,@matltocopy), Description,UM,QtyNeeded,PSFlag,Required,PartsStatusCode,Seq
					from #PartsToCopy 
					where Material = @matltocopy
				end 	
       else	
			begin
				--All Std Maint Item Part Codes/HQ Materials (@matltocopy) get initialized to WO that aren't don't exist in Override IN Co Location Materials'
				insert dbo.EMWP (EMCo,EMGroup,WorkOrder,WOItem,Equipment,
				 INCo,InvLoc,MatlGroup,Material,  Description,UM,QtyNeeded,PSFlag,Required,PartsStatusCode,Seq) 
				select EMCo,EMGroup,WorkOrder,WOItem,Equipment,
				null,null,@hqmatlgroup,@matltocopy, Description,UM,QtyNeeded,PSFlag,Required,PartsStatusCode,Seq 
				from #PartsToCopy 
				where Material = @matltocopy
			end
        set @i = @i + 1 --GP
     end
     if @@error <> 0 
     begin
	  --Select @errmsg = 'Error inserting Parts.', @rcode = 1
	  Select @errmsg = 'Issues encountered inserting Parts. Review in EM Work Order Edit', @rcode = 2
             end
end
--delete temp table, this stored procedure is call multiple time during WO Init
delete #PartsToCopy
 
bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMWOInitItem] TO [public]
GO
