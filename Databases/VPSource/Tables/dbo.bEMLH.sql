CREATE TABLE [dbo].[bEMLH]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Month] [dbo].[bMonth] NOT NULL,
[Trans] [dbo].[bTrans] NOT NULL,
[BatchID] [dbo].[bBatchID] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[FromJCCo] [dbo].[bCompany] NULL,
[ToJCCo] [dbo].[bCompany] NULL,
[FromJob] [dbo].[bJob] NULL,
[ToJob] [dbo].[bJob] NULL,
[FromLocation] [dbo].[bLoc] NULL,
[ToLocation] [dbo].[bLoc] NULL,
[DateIn] [dbo].[bDate] NOT NULL,
[TimeIn] [smalldatetime] NULL,
[DateOut] [dbo].[bDate] NULL,
[TimeOut] [smalldatetime] NULL,
[Memo] [dbo].[bDesc] NULL,
[EstOut] [datetime] NULL,
[InUseBatchID] [dbo].[bBatchID] NULL,
[AttachedToTrans] [dbo].[bTrans] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bEMLH] ADD
CONSTRAINT [FK_bEMLH_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMLH] ADD
CONSTRAINT [FK_bEMLH_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 /****** Object:  Trigger dbo.btEMLHd    Script Date: 8/28/99 9:37:18 AM ******/
 CREATE    trigger [dbo].[btEMLHd] on [dbo].[bEMLH] for Delete as
 /*--------------------------------------------------------------
*
*  Delete trigger for EMLH
*  Created By:  bc  06/16/99
*  Modified by: bc  04/19/00
*               bc  05/16/01
*				  TV 02/11/04 - 23061 added isnulls
*				GP 05/26/09 - 133434 added new HQAT insert
*
*--------------------------------------------------------------*/
/***  basic declares for SQL Triggers ****/
declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
@errno tinyint, @audit bYN, @latestcnt int, @priorcnt int, @nullcnt int
   
declare @emco bCompany, @mth bMonth, @trans bTrans, @equip bEquip,
@prior_mth bMonth, @prior_date bDate, @prior_time smalldatetime, @prior_trans bTrans,
@latest_date bDate, @latest_mth bMonth, @latest_time smalldatetime, @latest_trans bTrans,
@datein smalldatetime, @timein smalldatetime,
@prior_fromjcco bCompany, @prior_fromjob bJob, @prior_fromloc bLoc,
@prior_tojcco bCompany, @prior_tojob bJob, @prior_toloc bLoc,
@tojcco bCompany, @tojob bJob, @toloc bLoc, @fromjcco bCompany, @fromjob bJob, @fromloc bLoc,

@next_fromjcco bCompany, @next_fromjob bJob, @next_fromloc bLoc, @next_datein bDate, @next_timein smalldatetime,
@next_tojcco bCompany, @next_tojob bJob, @next_toloc bLoc

select @numrows = @@rowcount
   
if @numrows = 0 return
	
set nocount on
/* spin through records and possibley adjust emlh and/or emem */
select @emco = min(EMCo) from deleted
while @emco is not null
begin
	select @mth = min(Month) from deleted where EMCo = @emco
	while @mth is not null
	begin
		select @trans = min(Trans) from deleted where EMCo = @emco and Month = @mth
		while @trans is not null
		begin
			select @fromjcco = null, @fromjob = null, @fromloc = null,
			@tojcco = null, @tojob = null, @toloc = null, @timein = null

			select @equip = Equipment, @datein = DateIn, @timein = TimeIn,
			@fromjcco = FromJCCo, @fromjob = FromJob, @fromloc = FromLocation,
			@tojcco = ToJCCo, @tojob = ToJob, @toloc = ToLocation
			from deleted
			where EMCo = @emco and Month = @mth and Trans = @trans

			/* latestcnt = later transaction.  priorcnt = prior transaction */
			/* initialize variables */
			select @latest_date = null, @latest_trans = null, @prior_date = null, @prior_trans = null,
			@latestcnt = 0, @priorcnt = 0

			/* get the next avaiable emlh transaction for this piece of equipment if one exists */
			select @latest_date = min(DateIn) 	from bEMLH
			where EMCo = @emco and Equipment = @equip and
			((DateIn > @datein) or (DateIn = @datein and isnull(TimeIn,'00:00') > isnull(@timein,'00:00'))) and
			((Month <> @mth) or (Month = @mth and Trans <> @trans))

			if @latest_date is not null
			begin
				select @latest_mth = min(Month) from bEMLH
				where EMCo = @emco and Equipment = @equip and DateIn = @latest_date

				select @latest_time = min(TimeIn) 	from bEMLH
				where EMCo = @emco and Month = @latest_mth and Equipment = @equip and DateIn = @latest_date

				select @latest_trans = min(Trans) from bEMLH
				where EMCo = @emco and Month = @latest_mth and Equipment = @equip and DateIn = @latest_date and
				(TimeIn = @latest_time or @latest_time is null)

				if @latest_trans is not null select @latestcnt = 1
			end

			/* get the previous emlh transaction for this piece of equipment */
			select @prior_date = max(DateIn) from bEMLH
			where EMCo = @emco and Equipment = @equip and
			((DateIn < @datein) or (DateIn = @datein and isnull(TimeIn,'00:00') < isnull(@timein,'00:00'))) and
			((Month <> @mth) or (Month = @mth and Trans <> @trans))

			if @prior_date is not null
			begin
				select @prior_mth = max(Month) from bEMLH
				where EMCo = @emco and Equipment = @equip and DateIn = @prior_date and Trans <> @trans

				select @prior_time = max(TimeIn) from bEMLH
				where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and Trans <> @trans

				select @prior_trans = max(Trans) from bEMLH
				where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and Trans <> @trans and
				(TimeIn = @prior_time or @prior_time is null)

				if @prior_trans is not null select @priorcnt = 1
			end

			/* if there are no more lines in emlh for this equipment set emem to the from values which may be null */
			if @latestcnt = 0 and @priorcnt = 0
			begin
				update EMEM
				set JCCo = @fromjcco, Job = @fromjob, Location = @fromloc, JobDate = null
				where EMCo = @emco and Equipment = @equip
			end

			/* if the deleted record was the latest entry in emlh for this equipment,
			clear out the previous lines date and time out columns and adjust emem to prior line */
			if @latestcnt = 0 and @priorcnt = 1
			begin
				select @prior_fromjcco = FromJCCo, @prior_fromjob = FromJob, @prior_fromloc = FromLocation,
				@prior_tojcco = ToJCCo, @prior_tojob = ToJob, @prior_toloc = ToLocation
				from bEMLH
				where EMCo = @emco and Month = @prior_mth and Trans = @prior_trans

				update EMEM
				set JCCo = @prior_tojcco, Job = @prior_tojob, Location = @prior_toloc, JobDate = @prior_date
				where EMCo = @emco and Equipment = @equip

				update bEMLH
				set DateOut = null, TimeOut = null
				where EMCo = @emco and Month = @prior_mth and Trans = @prior_trans and
				((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
				((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
				((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
			end

			/* put next available lines values into previous lines columns */
			if @latestcnt = 1 and @priorcnt = 1
			begin
				select @next_datein = null, @next_timein = null
				select @next_datein = DateIn, @next_timein = TimeIn,
				@next_fromjcco = FromJCCo, @next_fromjob = FromJob, @next_fromloc = FromLocation,
				@next_tojcco = ToJCCo, @next_tojob = ToJob, @next_toloc = ToLocation
				from bEMLH
				where EMCo = @emco and Month = @latest_mth and Trans = @latest_trans

				/* put the next available emlh values into emem */
				if not exists(select 1 from bEMLH where EMCo = @emco and Equipment = @equip and
					((DateIn > @next_datein) or (DateIn = @datein and isnull(TimeIn,'00:00') > isnull(@next_timein,'00:00'))))
				begin
					update EMEM
					set JCCo = @next_tojcco, Job = @next_tojob, Location = @next_toloc, JobDate = @next_datein
					where EMCo = @emco and Equipment = @equip
				end

				/* update previous lines columns */
				update bEMLH
				set DateOut = @next_datein, TimeOut = @next_timein
				where EMCo = @emco and Month = @prior_mth and Trans = @prior_trans and
				((ToJCCo = @next_fromjcco) or (ToJCCo is null and @next_fromjcco is null)) and
				((ToJob = @next_fromjob) or (ToJob is null and @next_fromjob is null)) and
				((ToLocation = @next_fromloc) or (ToLocation is null and @next_fromloc is null))
			end
			select @trans = min(Trans) from deleted where EMCo = @emco and Month = @mth and Trans > @trans
		end
		select @mth = min(Month) from deleted where EMCo = @emco and Month > @mth
	end
	select @emco = min(EMCo) from deleted where EMCo > @emco
end

/* Audit inserts */
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bEMLH','EM Company: ' + convert(char(3),d.EMCo) + ' Month: ' + convert(varchar(8),d.Month) +
'Trans: ' + convert(varchar(10),d.Trans), d.EMCo, 'D',
null, null, null, getdate(), SUSER_SNAME()
from deleted d, EMCO e
where d.EMCo = e.EMCo and e.AuditLocXfer = 'Y'

-- Delete attachments if they exist. Make sure UniqueAttchID is not null
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
select AttachmentID, suser_name(), 'Y' 
from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
where d.UniqueAttchID is not null               

return
error:
select @errmsg = isnull(@errmsg,'') + ' - cannot delete EMLH'
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
   
   
   
  
 



GO

GO

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btEMLHi    Script Date: 8/28/99 9:37:18 AM ******/
CREATE trigger [dbo].[btEMLHi] on [dbo].[bEMLH] for insert as
/*--------------------------------------------------------------
*
*  Insert trigger for EMLH
*  Created By:  bc  06/15/99
*  Modified by: bc  05/02/01 - if an attachment is brought into a transfer batch independent of its primary piece of equipment,
*                              then unattach it.
*					TJL 04/11/07 - Issue #124338, DateOut, TimeOut not updated. Caused by NULL = NULL always False
*						Did an entire isnull(__, '') review throughout procedure.
*					CHS 01/08/2008 - issue #126157 added checks for soft and hard closed JC Jobs
*						re-wrote validation using cursor in order to allow for more explicit error messaging.*
*					CHS 05/07/2008 - issue #128187 allow Xfer of Down equipment
*					CHS 06/07/2008 - #126157
*					GF 05/05/2013 TFS-49039
*
*--------------------------------------------------------------*/
/***  basic declares for SQL Triggers ****/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int

declare @datein smalldatetime, @timein smalldatetime, @dateout smalldatetime, @estout smalldatetime,
@emco bCompany, @mth bMonth, @trans bTrans, @equip bEquip, @fromjcco bCompany, @fromjob bJob,
@fromloc bLoc,
@tojcco bCompany, @tojob bJob, @toloc bLoc, @batchid bBatchID,
@prior_mth bMonth, @prior_trans bTrans, @prior_date bDate, @prior_time smalldatetime,
@prior_tojcco bCompany, @prior_tojob bJob, @prior_toloc bLoc, @attached_trans int,
@validcntjobclosed int, @TimeOut smalldatetime, @Memo bDesc
   
select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

if @numrows = 1
	begin
		select @emco=EMCo, @mth=Month, @trans=Trans, @batchid=BatchID, @equip=Equipment,
		@fromjcco=FromJCCo, @tojcco=ToJCCo, @fromjob=FromJob, @tojob=ToJob, @fromloc=FromLocation,  
		@toloc=ToLocation, @datein=DateIn, @timein=TimeIn, @dateout=DateOut, @TimeOut=TimeOut,  
		@Memo=Memo, @estout=EstOut, @attached_trans=AttachedToTrans
		from inserted
	end
else
	begin
		---- use a cursor to process each inserted row
		declare bEMLH_insert cursor FAST_FORWARD
		for select EMCo, Month, Trans, BatchID, Equipment,
		FromJCCo, ToJCCo, FromJob, ToJob, FromLocation, ToLocation, DateIn, TimeIn, DateOut,
		TimeOut, Memo, EstOut, AttachedToTrans
		from inserted

		open bEMLH_insert
		fetch next from bEMCD_insert into @emco, @mth, @trans, @batchid, @equip,
		@fromjcco, @tojcco, @fromjob, @tojob, @fromloc, @toloc, @datein, @timein, @dateout,
		@TimeOut, @Memo, @estout, @attached_trans

		if @@fetch_status <> 0
		begin
			select @errmsg = 'Cursor error'
			goto error
		end
	end

insert_check:


---- Validate Equipment
if not exists(select 1 from bEMEM r with (nolock) where EMCo=@emco and @equip = Equipment and r.Status in ('A','D'))
begin
	select @errmsg = 'Equipment: ' + isnull(@equip, '') + ' is Invalid or not active.'
	goto error
end

---- Validate From JCCo
if @fromjcco is not null
begin
	if not exists(select 1 from bJCCO with (nolock) where JCCo=@fromjcco)	
	begin
		select @errmsg = 'From JC Company: ' + isnull(convert(varchar(3),@fromjcco), '') + ' is Invalid.'
		goto error
	end
end

---- Validate FromJob
if @fromjob is not null
begin
	if not exists(select 1 from bJCJM with (nolock) where JCCo=@fromjcco and Job=@fromjob)
	begin
		select @errmsg = 'From Job: ' + isnull(@fromjob, '') + ' is Invalid.'
		goto error
	end
end

---- Validate To JCCo
if @tojcco is not null
begin
	if not exists(select 1 from bJCCO with (nolock) where JCCo=@tojcco)
	begin
		select @errmsg = 'To JC Company: ' + isnull(convert(varchar(3),@tojcco), '')+ ' is Invalid.'
		goto error
	end
end

---- Validate ToJob 
if @tojob is not null
begin
	if not exists(select 1 from bJCJM with (nolock) where JCCo=@tojcco and Job=@tojob)
	begin
		select @errmsg = 'To Job: ' + isnull(@tojob, '') + ' is Invalid.'
		goto error
	end
end

---- check soft-closed jobs
if @tojob is not null
begin
	if exists(select top 1 1 from bJCJM j with (nolock)
		join bJCCO c with (nolock) on c.JCCo = j.JCCo
		where j.JCCo=@tojcco and j.Job=@tojob and c.PostSoftClosedJobs = 'N' and j.JobStatus = 2)
	begin
		select @errmsg = 'To Job: ' + isnull(@tojob, '') + ' is soft-closed and JC does not allow posting to soft-closed jobs.'
		goto error
	end
end  

---- check hard-closed jobs
if @tojob is not null
begin
	if exists(select top 1 1 from bJCJM j with (nolock)
		join bJCCO c with (nolock) on c.JCCo = j.JCCo
		where j.JCCo=@tojcco and j.Job=@tojob and c.PostSoftClosedJobs = 'N' and j.JobStatus = 3)
	begin
		select @errmsg = 'To Job: ' + isnull(@tojob, '') + ' is hard-closed and JC does not allow posting to hard-closed jobs.'
		goto error
	end 
end

---- Validate From Location
if @fromloc is not null
begin
	if not exists(select 1 from bEMLM  with (nolock) where EMCo=@emco and EMLoc=@fromloc)
	begin
		select @errmsg = 'From Location: ' + isnull(@fromloc, '') + ' is Invalid.'
		goto error
	end
end

---- Validate To Location
if @toloc is not null
begin
	if not exists(select 1 from bEMLM  with (nolock) where EMCo=@emco and EMLoc=@toloc)
	begin
		select @errmsg = 'To Location: ' + isnull(@toloc, '') + ' is Invalid.'
		goto error
	end
end

if @numrows > 1
begin
	fetch next from bEMCD_insert into @emco, @mth, @trans, @batchid, @equip,
	@fromjcco, @tojcco, @fromjob, @tojob, @fromloc, @toloc, @datein, @timein, @dateout,
	@TimeOut, @Memo, @estout, @attached_trans

	if @@fetch_status = 0 goto insert_check

	---- close and deallocate cursor
	close bEMLH_insert
	deallocate bEMLH_insert
end

/* validate the in and out times and update emem with new site information */
select @emco = min(EMCo) from inserted
while @emco is not null
begin
	select @mth = min(Month) from inserted where EMCo = @emco
	while @mth is not null
	begin
		select @trans = min(Trans) from inserted where EMCo = @emco and Month = @mth
		while @trans is not null
		begin
			/* initialize variables */
			select @datein = null, @timein= null, @dateout = null, @tojcco = null, @tojob = null, @toloc = null,
			@prior_mth = null, @prior_trans = null, @prior_date = null, @prior_time = null
   
			select @datein = DateIn, @timein = TimeIn, @dateout = DateOut, @estout = EstOut, @equip = Equipment,
			@fromjcco = FromJCCo, @fromjob = FromJob, @fromloc = FromLocation,
			@tojcco = ToJCCo, @tojob = ToJob, @toloc = ToLocation, @attached_trans = AttachedToTrans
			from inserted
			where EMCo = @emco and Month = @mth and Trans = @trans
   
			if isnull(@fromjcco,0) = isnull(@tojcco,0) and isnull(@fromjob,'') = isnull(@tojob,'') and	isnull(@fromloc,'') = isnull(@toloc,'')
			begin
				select @errmsg = 'Equipment cannot be transfered to its current job/location.'
				goto error
   			end
   
			/* update emem with the new jcco, job and location */
			if not exists(select 1 from bEMLH where EMCo = @emco and Equipment = @equip and
					   ((DateIn > @datein) or (DateIn = @datein and isnull(TimeIn,@datein + '00:00') > isnull(@timein,@datein + '00:00'))))
			begin
				update bEMEM
				set JCCo = @tojcco, Job = @tojob, Location = @toloc, JobDate = @datein
				where EMCo = @emco and Equipment = @equip
			end
   
			-- if an attachment is brought into the batch independent of its primary piece of equip, unattach it.
			if @attached_trans is null and	exists(select * from EMEM where EMCo = @emco and Equipment = @equip and AttachToEquip is not null)
			begin
				update bEMEM
				set AttachToEquip = null
				where EMCo = @emco and Equipment = @equip
			end
      
			/* update the prior emlh line if the from location is the same as the previous lines to location */
			select @prior_date = max(DateIn)	from bEMLH
			where EMCo = @emco and Equipment = @equip and DateIn <= @datein and
			(isnull(ToJCCo, 0) = isnull(@fromjcco, 0)) and--(or (ToJCCo is null and @fromjcco is null))
			(isnull(ToJob, '') = isnull(@fromjob, '')) and	   --(or (ToJob is null and @fromjob is null)) 
			(isnull(ToLocation, '') = isnull(@fromloc, ''))	   --(or (ToLocation is null and @fromloc is null))
   
			if @prior_date is not null
			begin
				select @prior_mth = max(Month) from bEMLH
				where EMCo = @emco and Equipment = @equip and DateIn = @prior_date and
				(isnull(ToJCCo, 0) = isnull(@fromjcco, 0)) and--(or (ToJCCo is null and @fromjcco is null))
				(isnull(ToJob, '') = isnull(@fromjob, '')) and	    --(or (ToJob is null and @fromjob is null)) 
				(isnull(ToLocation, '') = isnull(@fromloc, ''))	    --(or (ToLocation is null and @fromloc is null))
   
				select @prior_time = max(TimeIn) from bEMLH
				where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
				(isnull(ToJCCo, 0) = isnull(@fromjcco, 0)) and--(or (ToJCCo is null and @fromjcco is null))
				(isnull(ToJob, '') = isnull(@fromjob, '')) and	    --(or (ToJob is null and @fromjob is null)) 
				(isnull(ToLocation, '') = isnull(@fromloc, ''))	    --(or (ToLocation is null and @fromloc is null))
   
				select @prior_trans = max(Trans) from bEMLH
				where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
				(TimeIn = @prior_time or @prior_time is null) and-- TimeIn = @prior_time or we don't care about TimeIn
				(isnull(ToJCCo, 0) = isnull(@fromjcco, 0)) and		--(or (ToJCCo is null and @fromjcco is null))
				(isnull(ToJob, '') = isnull(@fromjob, '')) and			--(or (ToJob is null and @fromjob is null)) 
				(isnull(ToLocation, '') = isnull(@fromloc, ''))			--(or (ToLocation is null and @fromloc is null))
   
				if @prior_date = @datein	--OK here:  Neither can be NULL at this point
				begin
					select @prior_trans = max(Trans)	from bEMLH
					where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @datein and
					isnull(TimeIn, @datein + '00:00') < isnull(@timein, @datein + '00:00') and
					(isnull(ToJCCo, 0) = isnull(@fromjcco, 0)) and--(or (ToJCCo is null and @fromjcco is null))
					(isnull(ToJob, '') = isnull(@fromjob, '')) and	    --(or (ToJob is null and @fromjob is null)) 
					(isnull(ToLocation, '') = isnull(@fromloc, ''))	    --(or (ToLocation is null and @fromloc is null))
   
   					if @prior_trans is null
					begin
						/* Previous checks above were very specific.  This check, for another prior transfer before the datein
					     of inserted record, is much more general and may result in a Transaction value where the above
					    checks did not. */
   						select @prior_date = max(DateIn)	from bEMLH
   						where EMCo = @emco and Equipment = @equip and DateIn < @datein and
						(isnull(ToJCCo, 0) = isnull(@fromjcco, 0)) and--(or (ToJCCo is null and @fromjcco is null))
						(isnull(ToJob, '') = isnull(@fromjob, '')) and	   --(or (ToJob is null and @fromjob is null)) 
						(isnull(ToLocation, '') = isnull(@fromloc, ''))	   --(or (ToLocation is null and @fromloc is null))
	   
						if @prior_date is null
							begin
								/* no prior transfers for this equipment */
								select @prior_trans = null
							end
						else
							begin
								/* Prior DateIn not null:  At least one transfer for this equipment exists. */
								select @prior_mth = max(Month) from bEMLH
								where EMCo = @emco and Equipment = @equip and DateIn = @prior_date and
								(isnull(ToJCCo, 0) = isnull(@fromjcco, 0)) and--(or (ToJCCo is null and @fromjcco is null))
								(isnull(ToJob, '') = isnull(@fromjob, '')) and	   --(or (ToJob is null and @fromjob is null)) 
								(isnull(ToLocation, '') = isnull(@fromloc, ''))	   --(or (ToLocation is null and @fromloc is null))
	   
								select @prior_trans = max(Trans) from bEMLH
								where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
								(isnull(ToJCCo, 0) = isnull(@fromjcco, 0)) and--(or (ToJCCo is null and @fromjcco is null))
								(isnull(ToJob, '') = isnull(@fromjob, '')) and	   --(or (ToJob is null and @fromjob is null)) 
								(isnull(ToLocation, '') = isnull(@fromloc, ''))	   --(or (ToLocation is null and @fromloc is null))
							end
						end--End @prior_trans is null loop
					end--End @prior_date = @datein loop
			end--End @prior_date is not null loop
   
			if @prior_trans is not null
			begin
				select @prior_tojcco = ToJCCo, @prior_tojob = ToJob, @prior_toloc = ToLocation	from bEMLH
				where EMCo = @emco and Month = @prior_mth and Trans = @prior_trans and Equipment = @equip
	   
   				if isnull(@prior_tojcco, 0) = isnull(@fromjcco, 0) and isnull(@prior_tojob, '') = isnull(@fromjob, '') 
					and isnull(@prior_toloc, '') = isnull(@fromloc, '')			--Actual Fix to Issue #124338 Here, added isnull()
				begin
					update bEMLH
					set DateOut = @datein, TimeOut = @timein
					where EMCo = @emco and Month = @prior_mth and Trans = @prior_trans and Equipment = @equip
   					end
   				end
   				select @trans = min(Trans) from inserted where EMCo = @emco and Month = @mth and Trans > @trans
			end--End @trans is not null loop
			select @mth = min(Month) from inserted where EMCo = @emco and Month > @mth
	end--End @mth is not null loop
   	select @emco = min(EMCo) from inserted where EMCo > @emco
end--End @emco is not null loop

---- HQMA Audit inserts
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bEMLH','EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans), i.EMCo, 'A',
	null, null, null, getdate(), SUSER_SNAME()
from inserted i, EMCO e
where i.EMCo = e.EMCo and e.AuditLocXfer = 'Y'

return

error:
select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMLH'
RAISERROR(@errmsg, 11, -1);
rollback transaction

GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  trigger [dbo].[btEMLHu] on [dbo].[bEMLH] for update as
/*--------------------------------------------------------------
*
*  Insert trigger for EMLH
*  Created By:		bc 06/15/99
*  Modified by:		bc 09/06/01 - fixed the update to EMEM
*					bc 04/24/03 - issue # 21107
*					TV 02/11/04 - 23061 added isnulls
*					CHS 01/08/2008 - issue #126157 added checks for soft and hard closed JC Jobs*
*					CHS 05/07/2008 - issue #128187 allow Xfer of Down equipment
*					CHS 06/07/2008 - #126157
*					CHS 10/20/2008 - #130640
*			        JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
*					CHS 02/23/2009 - #130914 - trigger performance changes.
*					TRL 03/18/2009 - 132715 changed validation for from/to job and from/to Loc
*					GF 05/05/2013 TFS-49039
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt INT


declare @datein smalldatetime, @timein smalldatetime, @dateout smalldatetime, @estout smalldatetime, @emco bCompany,
@mth bMonth, @trans bTrans, @equip bEquip, @fromjcco bCompany, @fromjob bJob, @fromloc bLoc,
@tojcco bCompany, @tojob bJob, @toloc bLoc, @batchid bBatchID, @attached_trans int,
@prior_mth bMonth, @prior_trans bTrans, @prior_tojcco bCompany, @prior_tojob bJob, @prior_toloc bLoc,
@prior_date bDate, @prior_time smalldatetime, @TimeOut smalldatetime, 
@last_date bDate, @last_time smalldatetime,  @Memo bDesc

select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

--If the only column that changed was UniqueAttachID, then skip validation.        
IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bEMLH', 'UniqueAttchID') = 1
BEGIN 
	goto Trigger_Skip
END    

----TFS-49039  
SELECT @validcnt = COUNT(*) FROM dbo.bEMEM EMEM JOIN inserted i ON i.EMCo = EMEM.EMCo AND i.Equipment = EMEM.Equipment and EMEM.ChangeInProgress = 'Y'
IF @validcnt = @numrows goto Trigger_Skip

------------------
-- CURSOR BEGIN --
------------------
if @numrows = 1
	begin
   		select @emco=EMCo, @mth=Month, @trans=Trans, @batchid=BatchID, @equip=Equipment,
		@fromjcco=FromJCCo, @tojcco=ToJCCo, @fromjob=FromJob, @tojob=ToJob, @fromloc=FromLocation,  
		@toloc=ToLocation, @datein=DateIn, @timein=TimeIn, @dateout=DateOut, @TimeOut=TimeOut,  
		@Memo=Memo, @estout=EstOut, @attached_trans=AttachedToTrans
		from inserted
	end -- @numrows = 1
else
	begin
   		---- use a cursor to process each inserted row
   		declare bEMLH_insert cursor LOCAL fast_forward for 
   		select EMCo, Month, Trans, BatchID, Equipment, FromJCCo, ToJCCo, FromJob, 
		ToJob, FromLocation, ToLocation, DateIn, TimeIn, DateOut, TimeOut, 
		Memo, EstOut, AttachedToTrans
   		from inserted
   
    		open bEMLH_insert
		fetch next from bEMLH_insert into @emco, @mth, @trans, @batchid, @equip,
		@fromjcco, @tojcco, @fromjob, @tojob, @fromloc, @toloc, @datein, 
		@timein, @dateout, @TimeOut, @Memo, @estout, @attached_trans
	   
		if @@fetch_status <> 0
		begin
   			select @errmsg = 'Cursor error'
   			goto error
   		end -- if @@fetch_status <> 0
	end -- else

insert_check:

-----------------------------------
---- Validate Equipment
if @equip is not null
begin
	if not exists(select 1 from bEMEM r with (nolock)	where EMCo=@emco and @equip = Equipment and r.Status in ('A','D'))
	begin
		select @errmsg = 'Equipment: ' + isnull(@equip, '') + ' is Invalid or not active.'
		goto error
	end
end

---- Validate From JCCo
if @fromjcco is not null
begin
	if not exists(select 1 from bJCCO with (nolock) where JCCo=@fromjcco)	
	begin
		select @errmsg = 'From JC Company: ' + isnull(convert(varchar(3),@fromjcco), '') + ' is Invalid.'
		goto error
	end
end


if @fromjob is not null and not Update(DateOut) and not Update(TimeOut)
begin
	if not exists(select 1 from bJCJM with (nolock) where JCCo=@fromjcco and Job=@fromjob)
	begin
		select @errmsg = 'From Job: ' + isnull(@fromjob, '') + ' is Invalid.'
		goto error
	end
end
/* End 132715*/

---- Validate To JCCo
if @tojcco is not null
begin
	if not exists(select 1 from bJCCO with (nolock) where JCCo=@tojcco)
	begin
		select @errmsg = 'To JC Company: ' + isnull(convert(varchar(3),@tojcco), '')+ ' is Invalid.'
		goto error
	end
end


if @tojob is not null and not Update(DateOut) and not Update(TimeOut)
begin
	if not exists(select 1 from bJCJM with (nolock) where JCCo=@tojcco and Job=@tojob)
	begin
		select @errmsg = 'To Job: ' + isnull(@tojob, '') + ' is Invalid.'
		goto error
	end
end
/* End 132715*/

---- check soft-closed jobs
if @tojob is not null and @dateout is null
begin
	if exists(select top 1 1 from bJCJM j with (nolock)
		join bJCCO c with (nolock) on c.JCCo = j.JCCo
		where j.JCCo=@tojcco and j.Job=@tojob and c.PostSoftClosedJobs = 'N' and j.JobStatus = 2)
	begin
		select @errmsg = 'To Job: ' + isnull(@tojob, '') + ' is soft-closed and JC does not allow posting to soft-closed jobs.'
		goto error
	end
end  

---- check hard-closed jobs
if @tojob is not null and @dateout is null
begin
	if exists(select top 1 1 from bJCJM j with (nolock)
		join bJCCO c with (nolock) on c.JCCo = j.JCCo
		where j.JCCo=@tojcco and j.Job=@tojob and c.PostSoftClosedJobs = 'N' and j.JobStatus = 3)
	begin
		select @errmsg = 'To Job: ' + isnull(@tojob, '') + ' is hard-closed and JC does not allow posting to hard-closed jobs.'
		goto error
	end 
end


if @fromloc is not null and not Update(DateOut) and not Update(TimeOut)
begin
	if not exists(select 1 from bEMLM  with (nolock) where EMCo=@emco and EMLoc=@fromloc)
	begin
		select @errmsg = 'From Location: ' + isnull(@fromloc, '') + ' is Invalid.'
		goto error
	end
end



if @toloc is not null and not Update(DateOut) and not Update(TimeOut)
begin
	if not exists(select 1 from bEMLM  with (nolock) where EMCo=@emco and EMLoc=@toloc)
	begin
		select @errmsg = 'To Location: ' + isnull(@toloc, '') + ' is Invalid.'
		goto error
	end
end


select @datein = DateIn, @timein = TimeIn, @dateout = DateOut, @estout = EstOut, @equip = Equipment,
@fromjcco = FromJCCo, @fromjob = FromJob, @fromloc = FromLocation,
@tojcco = ToJCCo, @tojob = ToJob, @toloc = ToLocation
from inserted
where EMCo = @emco and Month = @mth and Trans = @trans

if isnull(@fromjcco,0) = isnull(@tojcco,0) and isnull(@fromjob,'') = isnull(@tojob,'') and isnull(@fromloc,'') = isnull(@toloc,'')
begin
	select @errmsg = 'Equipment cannot be transfered to its current job/location.'
	goto error
end -- if isnull(@fromjcco,0)

/* initialize variables */
select @last_date = null, @last_time = null, @prior_mth = null, @prior_trans = null, @prior_date = null, @prior_time = null

/* if the entry for this equipment is the most recent in EMLH then update EMEM with the jcco, job and location */
select @last_date = max(DateIn) from bEMLH
where EMCo = @emco and Equipment = @equip and DateIn is not null

if @last_date = @datein
begin
	select @last_time = max(TimeIn)  from bEMLH
	where EMCo = @emco and Equipment = @equip and DateIn = @last_date and TimeIn is not null

	if isnull(@last_time,@last_date + '00:00') <= isnull(@timein,@datein + '00:00') select @last_date = null
end -- if @last_date = @datein
   
if @last_date < @datein or @last_date is null
begin
	update bEMEM
	set JCCo = @tojcco, Job = @tojob, Location = @toloc, JobDate = @datein
	where EMCo = @emco and Equipment = @equip
end -- if @last_date

/* update the prior emlh line with DateOut info if the from values are the same as the previous lines to values */
/* if there is no prior_date then there is no prior_trans                                                       */
select @prior_date = max(DateIn) from bEMLH
where EMCo = @emco and Equipment = @equip and DateIn is not null and DateIn <= @datein and
((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
   
if @prior_date is not null
begin
	select @prior_mth = max(Month)	from bEMLH
	where EMCo = @emco and Equipment = @equip and DateIn = @prior_date and
	 ((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
	 ((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
	 ((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))

	select @prior_time = max(TimeIn) 	from bEMLH
	where EMCo = @emco and TimeIn is not null and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
	((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
	((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
	((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
	   
	select @prior_trans = max(Trans) from bEMLH
	where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
	(TimeIn = @prior_time or @prior_time is null) and
	((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
	((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
	((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
	   
	if @prior_date = @datein
		begin
			/* compare the times for same day transfers */
			select @prior_trans = max(Trans) from bEMLH
			where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
			 ((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
			 ((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
			 ((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null)) and
			 isnull(TimeIn,@prior_date + '00:00') < isnull(@timein,@prior_date + '00:00')
		   
			if @prior_trans is null
			begin
				/* check for another prior transfer before the datein of inserted record */
				select @prior_date = max(DateIn) from bEMLH
				where EMCo = @emco and DateIn is not null and Equipment = @equip and DateIn < @datein and
				((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
				((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
				((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))

				if @prior_date is null
					begin
						/* no prior transfers for this equipment */
						select @prior_trans = null
					end -- if @prior_date
				else
					begin
						/* at least one prior transfer for this equipment
						the time in is not a factor since the prior_date < datein based on above select statement */
						select @prior_mth = max(Month) from bEMLH
						where EMCo = @emco and Equipment = @equip and DateIn = @prior_date and
						((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
						((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
						((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))

						select @prior_trans = max(Trans) from bEMLH
						where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
						((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
						((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
						((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
					end -- else
			end -- if @prior_trans is null
	end -- if @prior_date = @datein
end -- if @prior_date is not null

   
if @prior_trans is not null and not (@prior_mth = @mth and @prior_trans = @trans)
begin
	select @prior_tojcco = ToJCCo, @prior_tojob = ToJob, @prior_toloc = ToLocation 	from bEMLH
	where EMCo = @emco and Month = @prior_mth and Trans = @prior_trans

	-- 04/24/03 bc
	if @prior_tojcco = @fromjcco and @prior_tojob = @fromjob and @prior_toloc = @fromloc
	begin
		update bEMLH
		set DateOut = @datein, TimeOut = @timein
		where EMCo = @emco and Month = @prior_mth and Trans = @prior_trans
	end -- if @prior_tojcco
end -- if @prior_trans
-----------------------------------
if @numrows > 1
begin
	fetch next from bEMLH_insert into @emco, @mth, @trans, @batchid, @equip,
	@fromjcco, @tojcco, @fromjob, @tojob, @fromloc, @toloc, @datein, @timein, @dateout,
	@TimeOut, @Memo, @estout, @attached_trans

   	if @@fetch_status = 0 goto insert_check
		
	---- close and deallocate cursor
	close bEMLH_insert
	deallocate bEMLH_insert
end -- if @numrows > 1
----------------
-- CURSOR END --
----------------

---- Audit inserts
if not exists (select 1 from inserted i left join bEMCO e on i.EMCo = e.EMCo where e.AuditLocXfer = 'Y')
begin
	return
end

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'Equipment', d.Equipment, i.Equipment, getdate(), SUSER_SNAME()

	from inserted i with (nolock)
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.Equipment <> d.Equipment
	left join bEMCO e with (nolock) on e.EMCo = i.EMCo
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'FromJCCo', convert(char(3),d.FromJCCo), convert(char(3),i.FromJCCo), getdate(), SUSER_SNAME()

	from inserted i with (nolock)
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.FromJCCo <> isnull(d.FromJCCo,0)
	left join bEMCO e with (nolock) on e.EMCo = i.EMCo
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'ToJCCo', convert(char(3),d.ToJCCo), convert(char(3),i.ToJCCo), getdate(), SUSER_SNAME()

	from inserted i with (nolock) 
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.ToJCCo <> isnull(d.ToJCCo,0) 
	left join bEMCO e with (nolock) on e.EMCo = i.EMCo 
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'FromJob', d.FromJob, i.FromJob, getdate(), SUSER_SNAME()

	from inserted i with (nolock) 
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.FromJob <> isnull(d.FromJob,'') 
	left join bEMCO e with (nolock) on e.EMCo = i.EMCo 
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'ToJob', d.ToJob, i.ToJob, getdate(), SUSER_SNAME()

	from inserted i with (nolock) 
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.ToJob <> isnull(d.ToJob,'')
	left join bEMCO e with (nolock) on e.EMCo = i.EMCo
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'FromLocation', d.FromLocation, i.FromLocation, getdate(), SUSER_SNAME()

	from inserted i with (nolock) 
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.FromLocation <> isnull(d.FromLocation,'')
	left join EMCO e with (nolock) on e.EMCo = i.EMCo
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'ToLocation', d.ToLocation, i.ToLocation, getdate(), SUSER_SNAME()

	from inserted i with (nolock) 
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.ToLocation <> isnull(d.ToLocation,'') 
	left join EMCO e with (nolock) on e.EMCo = i.EMCo
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'DateIn', convert(char(8),d.DateIn), convert(char(8),i.DateIn), getdate(), SUSER_SNAME()

	from inserted i with (nolock) 
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.DateIn <> isnull(d.DateIn,'')
	left join EMCO e with (nolock) on e.EMCo = i.EMCo
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'TimeIn', convert(char(8),d.TimeIn), convert(char(8),i.TimeIn), getdate(), SUSER_SNAME()

	from inserted i with (nolock) 
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.TimeIn <> isnull(d.TimeIn,'')
	left join EMCO e with (nolock) on e.EMCo = i.EMCo
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'EstOut', convert(char(8),d.EstOut), convert(char(8),i.EstOut), getdate(), SUSER_SNAME()

	from inserted i with (nolock) 
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.EstOut <> isnull(d.EstOut,'')
	left join EMCO e with (nolock) on e.EMCo = i.EMCo
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'DateOut', convert(char(8),d.DateOut), convert(char(8),i.DateOut), getdate(), SUSER_SNAME()

	from inserted i with (nolock) 
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.DateOut <> isnull(d.DateOut,'')
	left join EMCO e with (nolock) on e.EMCo = i.EMCo
	where e.AuditLocXfer = 'Y'

insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
	'Trans: ' + convert(varchar(10),i.Trans),
	i.EMCo, 'C', 'TimeOut', convert(char(8),d.TimeOut), convert(char(8),i.TimeOut), getdate(), SUSER_SNAME()

	from inserted i with (nolock) 
	left join deleted d with (nolock) on i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans and i.TimeOut <> isnull(d.TimeOut,'')
	left join EMCO e with (nolock) on e.EMCo = i.EMCo
	where e.AuditLocXfer = 'Y'

Trigger_Skip:

return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EMLH'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

--*
--*--------------------------------------------------------------*/
--declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int,
--		@rcode int, @validcntsoftclosed int, @validcnthardclosed int
--
---- it looks like the following are unused 
---- @validcnt int, @nullcnt int, @rcode int, @validcntsoftclosed int, @validcnthardclosed int
--
--declare @datein smalldatetime, @timein smalldatetime, @dateout smalldatetime, @estout smalldatetime, @emco bCompany,
--		@mth bMonth, @trans bTrans, @equip bEquip, @fromjcco bCompany, @fromjob bJob, @fromloc bLoc,
--		@tojcco bCompany, @tojob bJob, @toloc bLoc, @batchid bBatchID, @attached_trans int,
--		@prior_mth bMonth, @prior_trans bTrans, @prior_tojcco bCompany, @prior_tojob bJob, @prior_toloc bLoc,
--		@prior_date bDate, @prior_time smalldatetime, @TimeOut smalldatetime, 
--		@last_date bDate, @last_time smalldatetime,  @Memo bDesc
--
--select @numrows = @@rowcount
--if @numrows = 0 return
--set nocount on
--
-- --If the only column that changed was UniqueAttachID, then skip validation.        
--	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bEMLH', 'UniqueAttchID') = 1
--	BEGIN 
--		goto Trigger_Skip
--	END    
--
------ see if any fields have changed that is not allowed
--if update(EMCo) or Update(Month) or Update(Trans)
--	begin
--	select @validcnt = count(*) from inserted i
--	JOIN deleted d ON d.EMCo = i.EMCo and d.Month=i.Month and d.Trans = i.Trans
--	if @validcnt <> @numrows
--		begin
--		select @errmsg = 'Primary key fields may not be changed'
--		GoTo error
--		End
--	End
--
--
--if @numrows = 1
--	begin
--   	select @emco=EMCo, @mth=Month, @trans=Trans, @batchid=BatchID, @equip=Equipment,
--		@fromjcco=FromJCCo, @tojcco=ToJCCo, @fromjob=FromJob, @tojob=ToJob, @fromloc=FromLocation,  
--		@toloc=ToLocation, @datein=DateIn, @timein=TimeIn, @dateout=DateOut, @TimeOut=TimeOut,  
--		@Memo=Memo, @estout=EstOut, @attached_trans=AttachedToTrans
--	from inserted
--	end
--else
--	begin
--   	---- use a cursor to process each inserted row
--   	declare bEMLH_insert cursor FAST_FORWARD
--   		for select EMCo, Month, Trans, BatchID, Equipment,
--				FromJCCo, ToJCCo, FromJob, ToJob, FromLocation, ToLocation, DateIn, TimeIn, DateOut,
--				TimeOut, Memo, EstOut, AttachedToTrans
--   	from inserted
--   
--   	open bEMLH_insert
--	fetch next from bEMLH_insert into @emco, @mth, @trans, @batchid, @equip,
--				@fromjcco, @tojcco, @fromjob, @tojob, @fromloc, @toloc, @datein, @timein, @dateout,
--				@TimeOut, @Memo, @estout, @attached_trans
--   
--	if @@fetch_status <> 0
--		begin
--   		select @errmsg = 'Cursor error'
--   		goto error
--   		end
--	end
--
--
--insert_check:
--
------ Validate EMCo
--if not exists(select 1 from bEMCO with (nolock) where EMCo=@emco)	
--	begin
--	select @errmsg = 'EMCo: ' + isnull(convert(varchar(3),@emco),'') + ' is Invalid.'
--	goto error
--	end
--
------ Validate Equipment
--if not exists(select 1 from bEMEM r with (nolock)
--				where EMCo=@emco and @equip = Equipment and r.Status in ('A','D'))
--	begin
--	select @errmsg = 'Equipment: ' + isnull(@equip, '') + ' is Invalid or not active.'
--	goto error
--	end
--
------ Validate From JCCo
--if @fromjcco is not null
--	begin
--	if not exists(select 1 from bJCCO with (nolock) where JCCo=@fromjcco)	
--		begin
--		select @errmsg = 'From JC Company: ' + isnull(convert(varchar(3),@fromjcco), '') + ' is Invalid.'
--		goto error
--		end
--	end
--
------ Validate FromJob
--if @fromjob is not null
--	begin
--	if not exists(select 1 from bJCJM with (nolock) where JCCo=@fromjcco and Job=@fromjob)
--		begin
--		select @errmsg = 'From Job: ' + isnull(@fromjob, '') + ' is Invalid.'
--		goto error
--		end
--	end
--
------ Validate To JCCo
--if @tojcco is not null
--	begin
--	if not exists(select 1 from bJCCO with (nolock) where JCCo=@tojcco)
--		begin
--		select @errmsg = 'To JC Company: ' + isnull(convert(varchar(3),@tojcco), '')+ ' is Invalid.'
--		goto error
--		end
--	end
--
------ Validate ToJob 
--if @tojob is not null
--	begin
--	if not exists(select 1 from bJCJM with (nolock) where JCCo=@tojcco and Job=@tojob)
--		begin
--		select @errmsg = 'To Job: ' + isnull(@tojob, '') + ' is Invalid.'
--		goto error
--		end
--	end
--
------ check soft-closed jobs
--if @tojob is not null and @dateout is null
--	begin
--	if exists(select top 1 1 from bJCJM j with (nolock)
--			join bJCCO c with (nolock) on c.JCCo = j.JCCo
--			where j.JCCo=@tojcco and j.Job=@tojob and c.PostSoftClosedJobs = 'N' and j.JobStatus = 2)
--		begin
--		select @errmsg = 'To Job: ' + isnull(@tojob, '') + ' is soft-closed and JC does not allow posting to soft-closed jobs.'
--		goto error
--		end
--   end  
--
------ check hard-closed jobs
--if @tojob is not null and @dateout is null
--	begin
--	if exists(select top 1 1 from bJCJM j with (nolock)
--			join bJCCO c with (nolock) on c.JCCo = j.JCCo
--			where j.JCCo=@tojcco and j.Job=@tojob and c.PostSoftClosedJobs = 'N' and j.JobStatus = 3)
--	   begin
--		   select @errmsg = 'To Job: ' + isnull(@tojob, '') + ' is hard-closed and JC does not allow posting to hard-closed jobs.'
--		   goto error
--	   end 
--	end
--
------ Validate From Location
--if @fromloc is not null
--	begin
--	if not exists(select 1 from bEMLM  with (nolock) where EMCo=@emco and EMLoc=@fromloc)
--		begin
--		select @errmsg = 'From Location: ' + isnull(@fromloc, '') + ' is Invalid.'
--		goto error
--		end
--	end
--
------ Validate To Location
--if @toloc is not null
--	begin
--	if not exists(select 1 from bEMLM  with (nolock) where EMCo=@emco and EMLoc=@toloc)
--		begin
--		select @errmsg = 'To Location: ' + isnull(@toloc, '') + ' is Invalid.'
--		goto error
--		end
--	end
--
--
--
--
--if @numrows > 1
--	begin
--	fetch next from bEMLH_insert into @emco, @mth, @trans, @batchid, @equip,
--				@fromjcco, @tojcco, @fromjob, @tojob, @fromloc, @toloc, @datein, @timein, @dateout,
--				@TimeOut, @Memo, @estout, @attached_trans
--
--   	if @@fetch_status = 0 goto insert_check
--	
--	---- close and deallocate cursor
--	close bEMLH_insert
--	deallocate bEMLH_insert
--	end
--
--
--
--   
--   /* validate the in and out times and update emem with new site information */
--   
--   select @emco = min(EMCo) from inserted
--   while @emco is not null
--     begin
--     select @mth = min(Month) from inserted where EMCo = @emco
--     while @mth is not null
--       begin
--       select @trans = min(Trans) from inserted where EMCo = @emco and Month = @mth
--       while @trans is not null
--         begin
--   	  select @datein = DateIn, @timein = TimeIn, @dateout = DateOut, @estout = EstOut, @equip = Equipment,
--   	         @fromjcco = FromJCCo, @fromjob = FromJob, @fromloc = FromLocation,
--   	         @tojcco = ToJCCo, @tojob = ToJob, @toloc = ToLocation
--   	  from inserted
--   	  where EMCo = @emco and Month = @mth and Trans = @trans
--   
--   	  if isnull(@fromjcco,0) = isnull(@tojcco,0) and isnull(@fromjob,'') = isnull(@tojob,'') and
--            isnull(@fromloc,'') = isnull(@toloc,'')
--    	    begin
--   	    select @errmsg = 'Equipment cannot be transfered to its current job/location.'
--   	    goto error
--   	    end
--   
--         /* initialize variables */
--         select @last_date = null, @last_time = null, @prior_mth = null, @prior_trans = null, @prior_date = null, @prior_time = null
--   
--   	  /* if the entry for this equipment is the most recent in EMLH then update EMEM with the jcco, job and location */
--   	  select @last_date = max(DateIn)
--   	  from bEMLH
--   	  where EMCo = @emco and Equipment = @equip
--   
--         if @last_date = @datein
--           begin
--           select @last_time = max(TimeIn)
--           from bEMLH
--           where EMCo = @emco and Equipment = @equip and DateIn = @last_date
--   
--           if isnull(@last_time,@last_date + '00:00') <= isnull(@timein,@datein + '00:00') select @last_date = null
--           end
--   
--   	  if @last_date < @datein or @last_date is null
--   	    begin
--   	    update bEMEM
--   	    set JCCo = @tojcco, Job = @tojob, Location = @toloc, JobDate = @datein
--   	    where EMCo = @emco and Equipment = @equip
--   	    end
--   
--   
--   	  /* update the prior emlh line with DateOut info if the from values are the same as the previous lines to values */
--         /* if there is no prior_date then there is no prior_trans */
--   	  select @prior_date = max(DateIn)
--   	  from bEMLH
--   	  where EMCo = @emco and Equipment = @equip and DateIn <= @datein and
--               ((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
--               ((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
--               ((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
--   
--         if @prior_date is not null
--           begin
--           select @prior_mth = max(Month)
--        	from bEMLH
--           where EMCo = @emco and Equipment = @equip and DateIn = @prior_date and
--                 ((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
--                 ((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
--                 ((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
--   
--           select @prior_time = max(TimeIn)
--        	from bEMLH
--           where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
--                 ((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
--                 ((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
--                 ((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
--   
--           select @prior_trans = max(Trans)
--        	from bEMLH
--           where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
--                 (TimeIn = @prior_time or @prior_time is null) and
--                 ((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
--                 ((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
--       ((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
--   
--           if @prior_date = @datein
--             begin
--               /* compare the times for same day transfers */
--               select @prior_trans = max(Trans)
--               from bEMLH
--               where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
--                     ((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
--                     ((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
--                     ((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null)) and
--                     isnull(TimeIn,@prior_date + '00:00') < isnull(@timein,@prior_date + '00:00')
--   
--               if @prior_trans is null
--                 begin
--                 /* check for another prior transfer before the datein of inserted record */
--   	          select @prior_date = max(DateIn)
--   	          from bEMLH
--   	          where EMCo = @emco and Equipment = @equip and DateIn < @datein and
--                       ((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
--                       ((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
--                       ((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
--   
--                 if @prior_date is null
--                   begin
--                   /* no prior transfers for this equipment */
--                   select @prior_trans = null
--                   end
--                 else
--                   begin
--                   /* at least one prior transfer for this equipment
--                      the time in is not a factor since the prior_date < datein based on above select statement */
--                   select @prior_mth = max(Month)
--        	        from bEMLH
--                   where EMCo = @emco and Equipment = @equip and DateIn = @prior_date and
--                         ((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
--                         ((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
--                         ((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
--   
--                   select @prior_trans = max(Trans)
--        	        from bEMLH
--                   where EMCo = @emco and Month = @prior_mth and Equipment = @equip and DateIn = @prior_date and
--                         ((ToJCCo = @fromjcco) or (ToJCCo is null and @fromjcco is null)) and
--                         ((ToJob = @fromjob) or (ToJob is null and @fromjob is null)) and
--                         ((ToLocation = @fromloc) or (ToLocation is null and @fromloc is null))
--                   end
--                 end
--               end
--             end
--   
--           if @prior_trans is not null and not (@prior_mth = @mth and @prior_trans = @trans)
--   	      begin
--   	      select @prior_tojcco = ToJCCo, @prior_tojob = ToJob, @prior_toloc = ToLocation
--   	      from bEMLH
--   	      where EMCo = @emco and Month = @prior_mth and Trans = @prior_trans
--   
--             -- 04/24/03 bc
--   	      if @prior_tojcco = @fromjcco and @prior_tojob = @fromjob and @prior_toloc = @fromloc
--               begin
--               update bEMLH
--          	    set DateOut = @datein, TimeOut = @timein
--          	    where EMCo = @emco and Month = @prior_mth and Trans = @prior_trans
--          	    end
--             end
--   
--         select @trans = min(Trans) from inserted where EMCo = @emco and Month = @mth and Trans > @trans
--         end
--       select @mth = min(Month) from inserted where EMCo = @emco and Month > @mth
--       end
--     select @emco = min(EMCo) from inserted where EMCo > @emco
--     end
--   
--   
------ Audit inserts
--if not exists (select * from inserted i, EMCO e where i.EMCo = e.EMCo and e.AuditLocXfer = 'Y')
--	begin
--	return
--	end
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'Equipment', d.Equipment, i.Equipment, getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.Equipment <> isnull(d.Equipment,'') and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'FromJCCo', convert(char(3),d.FromJCCo), convert(char(3),i.FromJCCo), getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.FromJCCo <> isnull(d.FromJCCo,0) and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'ToJCCo', convert(char(3),d.ToJCCo), convert(char(3),i.ToJCCo), getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.ToJCCo <> isnull(d.ToJCCo,0) and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'FromJob', d.FromJob, i.FromJob, getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.FromJob <> isnull(d.FromJob,'') and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'ToJob', d.ToJob, i.ToJob, getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.ToJob <> isnull(d.ToJob,'') and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'FromLocation', d.FromLocation, i.FromLocation, getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.FromLocation <> isnull(d.FromLocation,'') and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'ToLocation', d.ToLocation, i.ToLocation, getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.ToLocation <> isnull(d.ToLocation,'') and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'DateIn', convert(char(8),d.DateIn), convert(char(8),i.DateIn), getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.DateIn <> isnull(d.DateIn,'') and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'TimeIn', convert(char(8),d.TimeIn), convert(char(8),i.TimeIn), getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.TimeIn <> isnull(d.TimeIn,'') and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'EstOut', convert(char(8),d.EstOut), convert(char(8),i.EstOut), getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.EstOut <> isnull(d.EstOut,'') and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'DateOut', convert(char(8),d.DateOut), convert(char(8),i.DateOut), getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.DateOut <> isnull(d.DateOut,'') and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--insert into bHQMA select 'bEMLH', 'EM Company: ' + convert(char(3),i.EMCo) + ' Month: ' + convert(varchar(8),i.Month) +
--	'Trans: ' + convert(varchar(10),i.Trans),
--	i.EMCo, 'C', 'TimeOut', convert(char(8),d.TimeOut), convert(char(8),i.TimeOut), getdate(), SUSER_SNAME()
--	from inserted i, deleted d, EMCO e
--	where i.EMCo = d.EMCo and i.Month = d.Month and i.Trans = d.Trans
--	and i.TimeOut <> isnull(d.TimeOut,'') and e.EMCo = i.EMCo and e.AuditLocXfer = 'Y'
--
--
--Trigger_Skip:
--
--return
--
--
--error:
--	select @errmsg = isnull(@errmsg,'') + ' - cannot update EMLH'
--	RAISERROR(@errmsg, 11, -1);
--	rollback transaction
--   
--   
--   
--   
--   
   
   
   
  
 



GO

CREATE NONCLUSTERED INDEX [biEMLHDate] ON [dbo].[bEMLH] ([EMCo], [Equipment], [DateIn], [TimeIn]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMLH] ON [dbo].[bEMLH] ([EMCo], [Month], [Trans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMLH] ([KeyID]) ON [PRIMARY]
GO
