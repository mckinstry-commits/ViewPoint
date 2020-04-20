SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspEMEquipValXfer]
     
/***********************************************************
* CREATED BY:    bc 05/26/99
* MODIFIED By :  bc 04/06/00
*		TV 02/11/04 - 23061 added isnulls	
*		TV 02/024/05 26702 - If equipment is existing batch, the message displays ID, no Month
*		TJL 01/18/07 - Issue #27822, 6x Recode.  Added output for EquipAttachmentsYN when Attachements exist.
*									Added output for Equipment this Equipment is attached to.
*		CHS 05/06/2008 - issue # 128187 - allow 'D' down equipment to be transferred.
*		TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
*
* USAGE:
*
*	If equipment needs to be active send flag @checkactive = 'Y' and the status must be 'A'.
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
* 	@checkactive 	send in a 'Y' or 'N'
*
*
* OUTPUT PARAMETERS
*	ret val		EMEM column
*	-------		-----------
*	@jcco		default job cost company from emem
*	@job		default job from emem
*	@location	default location from emem
*	@equipattachmentsyn		Equip Attachments exist for this piece of Equipment
*	@equipattachedto		Equip this Equip is attached to.  Opposite the above
*	@errmsg		Description or Error msg if error
 **********************************************************/
(@emco bCompany, @mth bMonth, @batch bBatchID, @seq int, @equip bEquip, @datein bDate = null, @timein smalldatetime = null, @checkactive bYN,
@jcco bCompany = null output, @job bJob = null output, @location bLoc = null output, @equipattachmentsyn bYN = 'N' output, 
@equipattachedto bEquip = null output, @errmsg varchar(255) output)

as

set nocount on

declare @rcode int, @status char(1), @type char(1), @cnt int, @errorbatch bBatchID,
@emlh_date bDate, @emlh_mth bMonth, @emlh_trans bTrans, @emlh_time smalldatetime,
@emlb_date bDate, @emlb_seq int, @emlb_time smalldatetime,
@LHflag bYN, @LBflag bYN, @month bMonth

select @rcode = 0, @equipattachmentsyn = 'N'

if @emco is null
begin
	select @errmsg = 'Missing EM Company.', @rcode = 1
	goto bspexit
end

if isnull(@equip,'') =''
begin
	select @errmsg = 'Missing Equipment.', @rcode = 1
	goto bspexit
end

/* the equipment being transfered cannot exist in a different batch */
select @errorbatch = BatchId, @month = Mth from dbo.EMLB with(nolock)
where Co = @emco and Equipment = @equip and BatchId <> @batch
     
if @errorbatch is not null
begin 
	-- TV 02/024/05 26702 - If equipment is existing batch, the message displays ID, no Month
	select @errmsg = 'Equipment already exists in batch ' + convert(varchar(2),datepart(mm,@month))+ '/' + 
	convert(varchar(4),datepart(yy,@month)) + ' ID: ' + isnull(convert(varchar(8),@errorbatch),''), @rcode = 1
	goto bspexit
end

--Return if Equipment Change in progress for New Equipment Code - 126196
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @errmsg output
If @rcode = 1
begin
	goto bspexit
end

/* validate equipment and retrieve emem flags */
select @type = Type, @status = Status, @errmsg = Description from dbo.EMEM with(nolock)
where EMCo = @emco and Equipment = @equip

if @@rowcount = 0
begin
	select @errmsg = 'Equipment invalid.', @rcode = 1
	goto bspexit
end

/* get the most recent transfer date that has been recorded for the equipment */
select @emlh_date = null, @emlh_mth = null, @emlh_trans = null, @emlh_time = null,
@emlb_date = null, @emlb_seq = null, @emlb_time = null,@LHflag = 'N', @LBflag = 'N'

/**** check EMLH for this equipment ****/
select @emlh_date = max(DateIn)from dbo.EMLH with(nolock)
where EMCo = @emco and Equipment = @equip and (DateIn <= @datein or @datein is null)

if @emlh_date is not null
begin
	/* the most recent month from the most recent prior transfer */
	select @emlh_mth = max(Month) from dbo.EMLH with(nolock)
	where EMCo = @emco and Equipment = @equip and DateIn = @emlh_date

	/* the most recent time in from the most recent prior transfer */
	select @emlh_time = max(TimeIn) from dbo.EMLH with(nolock)
	where EMCo = @emco and Month = @emlh_mth and Equipment = @equip and DateIn = @emlh_date

	/* the most recent transaction from the most recent prior transfer */
	select @emlh_trans = max(Trans)	from dbo.EMLH with(nolock)
	where EMCo = @emco and Month = @emlh_mth and Equipment = @equip and DateIn = @emlh_date 
	and (TimeIn = @emlh_time or @emlh_time is null)
     
	if @emlh_date = @datein
	begin
		select @emlh_trans = max(Trans)from dbo.EMLH with(nolock)
		where EMCo = @emco and Month = @emlh_mth and Equipment = @equip and DateIn = @emlh_date and
		isnull(TimeIn,@emlh_date + '00:00') < isnull(@timein,@emlh_date + '00:00')

		if @emlh_trans is null
		begin
			/* check for another prior transfer before the datein of inserted record */
			select @emlh_date = max(DateIn) from dbo.EMLH with(nolock)
			where EMCo = @emco and Equipment = @equip and DateIn < @datein

			if @emlh_date is null
				begin
					/* no prior transfers for this equipment */
					select @emlh_trans = null
				end
			else
				begin
					/* at least one transfer for this equipment */
					select @emlh_mth = max(Month) from dbo.EMLH with(nolock)
					where EMCo = @emco and Equipment = @equip and DateIn = @emlh_date

					select @emlh_trans = max(Trans)from dbo.EMLH with(nolock)
					where EMCo = @emco and Month = @emlh_mth and Equipment = @equip and DateIn = @emlh_date
				end
		end
	end
end
     
/**** check EMLB for this equipment ****/
select @emlb_date = max(DateIn)   from dbo.EMLB with(nolock)
where Co = @emco and Mth = @mth and BatchId = @batch and BatchSeq <> @seq and Equipment = @equip 
and  (DateIn <= @datein or @datein is null)

if @emlb_date is not null
begin
	/* the most recent time in from the most recent prior transfer */
	select @emlb_time = max(TimeIn)from dbo.EMLB with(nolock)
	where Co = @emco and Mth = @mth and BatchId = @batch and BatchSeq <> @seq and Equipment = @equip and DateIn = @emlb_date

	/* the most recent transaction from the most recent prior transfer */
	select @emlb_seq = max(BatchSeq)from dbo.EMLB with(nolock)
	where Co = @emco and Mth = @mth and BatchId = @batch and BatchSeq <> @seq and Equipment = @equip 
	and DateIn = @emlb_date and  (TimeIn = @emlb_time or @emlb_time is null)

	if @emlb_date = @datein
	begin
		select @emlb_seq = max(BatchSeq) from dbo.EMLB with(nolock)
		where Co = @emco and Mth = @mth and BatchId = @batch and BatchSeq <> @seq and Equipment = @equip 
		and DateIn = @emlb_date and isnull(TimeIn,@emlb_date + '00:00') < isnull(@timein,@emlb_date + '00:00')

		if @emlb_seq is null
		begin
			/* check for another prior transfer before the datein of inserted record */
			select @emlb_date = max(DateIn)from dbo.EMLB with(nolock)
			where Co = @emco and Mth = @mth and BatchId = @batch and BatchSeq <> @seq and Equipment = @equip and DateIn < @datein

			if @emlb_date is null
				begin
					/* no prior transfers for this equipment */
					select @emlb_seq = null
				end
			else
				begin
					/* at least one transfer for this equipment */
					select @emlb_seq = max(BatchSeq) from dbo.EMLB with(nolock)
					where Co = @emco and Mth = @mth and BatchId = @batch and BatchSeq <> @seq and Equipment = @equip and DateIn = @emlb_date
				end
		end
	end
end
     
if @emlb_seq is not null 
begin 
	select @LBflag = 'Y'
end
if @emlh_trans is not null 
begin 
	select @LHflag = 'Y'
end

if @LBflag = 'Y' and @LHflag = 'Y'
begin
	if @emlb_date > @emlh_date 
	begin
		select @LHflag = 'N'
	end
	if @emlb_date < @emlh_date 
	begin
		select @LBflag = 'N'
	end
	if @emlb_date = @emlh_date
	begin
		if isnull(@emlb_time,@emlb_date + '00:00') > isnull(@emlh_time,@emlh_date + '00:00') 
			begin 
				select @LHflag = 'N' 
			end
		else
			begin
				select @LBflag = 'N'
			end
	end
end
     
if @LHflag = 'Y'
begin
	select @jcco = ToJCCo, @job = ToJob, @location = ToLocation from dbo.EMLH with(nolock)
	where EMCo = @emco and Month = @emlh_mth and Trans = @emlh_trans
end

if @LBflag = 'Y'
begin
	select @jcco = ToJCCo, @job = ToJob, @location = ToLocation from dbo.EMLB with(nolock)
	where Co = @emco and Mth = @mth and BatchId = @batch and BatchSeq = @emlb_seq
end

if @LHflag = 'N' and @LBflag = 'N'
begin
	/* retrieve defaults from emem if no record exists in EMLH for this equipment prior to this equipment's date in */
	select @jcco = JCCo, @job = Job, @location = Location from dbo.EMEM with(nolock)
	where EMCo = @emco and Equipment = @equip
end

if @checkactive='Y'
begin
	-- #128187 05/06/2008 - allow D down Xfers
	-- if status is I inactive or data is dirty then don't allow
	if @status <>'A' and @status <>'D' 
	begin
		select @errmsg = 'Equipment must be active.', @rcode = 1
		goto bspexit
	end
end

if @type = 'C'
begin
	select @errmsg = 'Components will automatically transfer with their primary equipment.  '
	select @errmsg = @errmsg + 'This component cannot be transferred, by itself, to another location.', @rcode = 1
	goto bspexit
end

/* Look for Equipments attached to this Equipment */
if exists(select top 1 1 from dbo.EMEM with (nolock) where EMCo = @emco and AttachToEquip = @equip)
begin
	select @equipattachmentsyn = 'Y'
end

/* Look for Equipment this Equipment is attached to.  The opposite from above. */
if exists (select top 1  1 from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @equip and AttachToEquip is not null) 
begin
	select @equipattachedto = AttachToEquip from dbo.EMEM with (nolock)
	where EMCo = @emco and Equipment = @equip and AttachToEquip is not null
end
     
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMEquipValXfer] TO [public]
GO
