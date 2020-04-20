SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMImportEquipCurrentLocation]
     
/***********************************************************
* CREATED BY:    TRL 10/27/2009  Issue 133294
* MODIFIED By :  
*	
* USAGE:  Gets current equipment location from EMLH (location history) when importing locations
*
*	If equipment needs to be active send flag @checkactive = 'Y' and the status must be 'A'.
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
* 	@checkactive 	send in a 'Y' or 'N'
*
* OUTPUT PARAMETERS
*	ret val		EMEM column
*	-------		-----------
*	@jcco		default job cost company from emem
*	@job		default job from emem
*	@location	default location from emem
*	@errmsg		Description or Error msg if error
 **********************************************************/
(@emco bCompany, @equip bEquip, @jcco bCompany = null output, @job bJob = null output, @location bLoc = null output,@errmsg varchar(255) output)

as

set nocount on

declare @rcode int, @status char(1), @type char(1), @cnt int, @errorbatch bBatchID,
@emlh_date bDate, @emlh_mth bMonth, @emlh_trans bTrans, @emlh_time smalldatetime,
@month bMonth

select @rcode = 0

if @emco is null
begin
	select @errmsg = 'Missing EM Company.', @rcode = 1
	goto vspexit
end

if isnull(@equip,'') =''
begin
	select @errmsg = 'Missing Equipment.', @rcode = 1
	goto vspexit
end

/* validate equipment and retrieve emem flags */
select @type = Type, @status = Status, @errmsg = Description from dbo.EMEM with(nolock)
where EMCo = @emco and Equipment = @equip
if @@rowcount = 0
begin
	select @errmsg = 'Equipment invalid: ' + isnull(@equip,'') , @rcode = 1
	goto vspexit
end

-- if status is I inactive or data is dirty then don't allow
if @status <>'A' and @status <>'D' 
begin
	select @errmsg = 'Equipment must be active.', @rcode = 1
	goto vspexit
end

--Components can't be transfered by themselves'
if @type = 'C'
begin
	select @errmsg = 'Components will automatically transfer with their primary equipment.  This component cannot be transferred, by itself, to another location.', @rcode = 1
	goto vspexit
end

/* the equipment imported cannot exist in a batch */
if exists (select top 1 1 from dbo.EMLB with(nolock) where Co = @emco and Equipment = @equip )
begin
	select  @month = Min(Mth) from dbo.EMLB with(nolock)where Co = @emco and Equipment = @equip  
	select  @errorbatch = min(BatchId) from dbo.EMLB with(nolock)where Co = @emco and Equipment = @equip  and Mth=@month
    	if @errorbatch is not null
	begin 
		-- If equipment is existing batch, the message displays ID, no Month
		select @errmsg = 'Equipment already exists in batch ' + convert(varchar(2),datepart(mm,@month))+ '/' + 
		convert(varchar(4),datepart(yy,@month)) + ' ID: ' + isnull(convert(varchar(8),@errorbatch),''), @rcode = 1
		goto vspexit
	end
end 

--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @errmsg output
If @rcode = 1
begin
	goto vspexit
end
	
/* get the most recent transfer date that has been recorded for the equipment */
select @emlh_date = null, @emlh_mth = null, @emlh_trans = null, @emlh_time = null

/**** check EMLH for this equipment ****/
--If no records exists in Location History, check EM Equipment Maint.
if not exists (select  top 1 1 from dbo.EMLH with(nolock)where EMCo = @emco and Equipment = @equip  )
begin
	--If no location history record and Equip Master fields are blank then it's first time transfer which means from??? should be blank'
	--Most likely should for new customers or equipment codes
	--exit stored procedure
	select @jcco = JCCo, @job = Job, @location = Location from dbo.EMEM with(nolock)
	where EMCo = @emco and Equipment = @equip
	goto vspexit 
end

/* retrieve defaults from emem if no record exists in EMLH for this equipment prior to this equipment's date in */
select @emlh_date = max(DateIn) from dbo.EMLH with(nolock)
where EMCo = @emco and Equipment = @equip 

/* the most recent month from the most recent prior transfer */
select @emlh_mth = max(Month) from dbo.EMLH with(nolock)
where EMCo = @emco and Equipment = @equip and DateIn = @emlh_date

/* the most recent time in from the most recent prior transfer */
select @emlh_time = max(TimeIn) from dbo.EMLH with(nolock)
where EMCo = @emco and Equipment = @equip and Month = @emlh_mth    and DateIn = @emlh_date 

/* the most recent transaction from the most recent prior transfer */
select @emlh_trans = max(Trans)	from dbo.EMLH with(nolock)
where EMCo = @emco and Equipment = @equip 
and Month = @emlh_mth and DateIn = @emlh_date and (TimeIn = @emlh_time or @emlh_time is null)

select @jcco = ToJCCo, @job = ToJob, @location = ToLocation from dbo.EMLH with(nolock)
where EMCo = @emco and Month = @emlh_mth and Trans = @emlh_trans

select ToJCCo=@jcco, ToJob=@job, ToLoc=@location 
/*,EMLH_Trans = @emlh_trans, EMLH_Mth=@emlh_mth, EMLH_DateIn = @emlh_date, EMLH_TimeIn=@emlh_time*/


vspexit:
if @rcode = 1
begin
	select isnull(@errmsg,'')
end

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMImportEquipCurrentLocation] TO [public]
GO
