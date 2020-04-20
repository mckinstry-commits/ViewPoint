CREATE TABLE [dbo].[bHRRD]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[Seq] [int] NOT NULL,
[Date] [dbo].[bDate] NOT NULL,
[Code] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[RewardAmt] [dbo].[bDollar] NOT NULL,
[Reason] [dbo].[bDesc] NULL,
[HistSeq] [int] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE      trigger [dbo].[btHRRDd] on [dbo].[bHRRD] for Delete
   as
   

	/**************************************************************
	 * 	Created: 04/03/00 ae
	 *	Last Modified: mh 10/11/02 added update to HREH
	 *					mh 2/20/03 Issue 20486
	 *					mh 23061 3/17/04
	 *					mh 4/8/04 Date truncated in keystring
	 *					mh 10/29/2008 - 127008
     *
     **************************************************************/
   
   	declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, 
   	@nullcnt int, @rcode int, @hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10), 
   	@rewardseq int
    
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
    
   	/* Audit inserts */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
   		select 'bHRRD', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(d.HRRef,'')) +
		' Seq: ' + convert(varchar(10),isnull(d.Seq,'')) + ' Date: ' + convert(varchar(11),isnull(d.Date,'')),
     	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
     	from deleted d join dbo.bHRCO e with (nolock) on
		e.HRCo = d.HRCo where e.AuditRewardsYN = 'Y'
    
   	  Return
   
   error:
   
   	select @errmsg = (@errmsg + ' - cannot delete HRRD! ')
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE       trigger [dbo].[btHRRDi] on [dbo].[bHRRD] for INSERT as
   	

	/*-----------------------------------------------------------------
   	*   Created by: kb 2/25/99
   	*	Modified by: ae 3/31/00 added audits.
   	*				mh 23061 3/17/04
   	*				mh 4/8/04 Date in keystring being truncated
   	*				mh 7/14/04 25029
	*				mh 1/11/2008 119853
	*				mh 10/29/2008 127008
    *				mh 01/09/2009 - 131560  Corrected typo
   	*
   	*	This trigger rejects update in bHRRD (Resource Reward) if the
   	*	following error condition exists:
   	*
   	*		Invalid HQ Company number
   	*		Invalid HR Resource number
   	*
   	*
   	*	Adds HR Employment History Record if HRCO_RewardHistYN = 'Y'
   	*/----------------------------------------------------------------
    
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, 
   	@datechgd bDate, @hrco bCompany, @hrref bHRRef, @rewardseq int, @opencurs tinyint, 
   	@rewardhistyn bYN, @rewardhistcode varchar(10),	@histseq int, @rewarddate bDate
    
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
    
   	/* check for key changes */
   	select @validcnt = count(i.HRCo) from inserted i join dbo.bHQCO h with (nolock) on
   	i.HRCo =h.HQCo
   	if @validcnt <> @numrows
     	begin
     		select @errmsg = 'Invalid HR Company'
   	  	goto error
     	end
    
   	select @validcnt = count(i.HRCo) from inserted i join dbo.bHRRM h with (nolock) on
   	i.HRCo = h.HRCo and i.HRRef = h.HRRef
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid Resource'
   		goto error
   	end
    
   	/* validate reward code*/
   	select @validcnt = count(i.HRCo) from inserted i join dbo.bHRCM h with (nolock) on
   	i.HRCo = h.HRCo and h.Code = i.Code 
   	where h.Type = 'W'
   	if @validcnt <> @numrows
     	begin
     		select @errmsg = 'Invalid Reward Code'
   	  	goto error
     	end
   
   	declare insert_curs cursor local fast_forward for
   	select HRCo, HRRef, Seq, Date from inserted where HRCo is not null and HRRef is not null
   	and Seq is not null
   
   	open insert_curs
   	
	--Issue 131560
	--select @opencurs tinyint
   	select @opencurs = 0
   
   	fetch next from insert_curs into @hrco, @hrref, @rewardseq, @rewarddate
   
   	while @@fetch_status = 0
   	begin
   		select @rewardhistyn = RewardHistYN, @rewardhistcode = RewardHistCode 
   		from dbo.bHRCO with (nolock) 
   		where HRCo = @hrco
   
   		if @rewardhistyn = 'Y' and @rewardhistcode is not null
   		begin
   			select @histseq = isnull(max(Seq),0)+1, @datechgd = isnull(@rewarddate, convert(varchar(11), getdate())) 
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @histseq, @rewardhistcode, @datechgd, 'H')
   
   	  		update dbo.bHRRD 
   			set HistSeq = @histseq 
   			where HRCo = @hrco and HRRef = @hrref and Seq = @rewardseq
   		end
   
   		fetch next from insert_curs into @hrco, @hrref, @rewardseq, @rewarddate
   
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   		select @opencurs = 0
   	end
   
   	/* Audit inserts */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
   	select 'bHRRD', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
    ' Seq: ' + convert(varchar(10),isnull(i.Seq,'')) + ' Date: ' + convert(varchar(11),isnull(i.Date,'')),
    i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    from inserted i join dbo.bHRCO e on 
   	e.HRCo = i.HRCo where e.AuditRewardsYN = 'Y'
   
    
   	return
    
   error:
     	select @errmsg = @errmsg + ' - cannot insert HR Resource Reward!'
     	RAISERROR(@errmsg, 11, -1);
    
     	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   
	CREATE        trigger [dbo].[btHRRDu] on [dbo].[bHRRD] for UPDATE as
   
   	

	/*-----------------------------------------------------------------
   	*   Created by: kb 2/25/99
   	* 	Modified by:	mh 2/20/03 Issue 20486
   	*					mh 23061 3/17/04
   	*					mh 29243 7/12/05 corrected varchar(5),isnull(i.HRRef,'')) to varchar(6)
	*					mh 119853
   	*
   	*	This trigger rejects update in bHRRD if the
   	*	following error condition exists:
   	*
   	*/----------------------------------------------------------------
   
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
   	@hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10), @rewardseq int,
	@rewarddate bDate, @opencurs tinyint, @rewardhistyn bYN, @rewardhist varchar(10),
	@histseq int
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* check for key changes */
   	if update(HRCo)
   	begin
   		select @validcnt = count(i.HRCo) from inserted i join deleted d on
   		i.HRCo = d.HRCo
   		if @validcnt <> @numrows
   		begin
   			select @errmsg = 'Cannot change HR Company'
   			goto error
   		end
   	end
   
   	if update(HRRef)
   	begin
   		select @validcnt = count(i.HRCo) from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.HRRef = d.HRRef
   		if @validcnt <> @numrows
   		begin
   			select @errmsg = 'Cannot change HR Resource'
   			goto error
   		end
   	end
   
   	if update(Seq)
   	begin
   		select @validcnt = count(i.HRCo) from inserted i join deleted d on
   		i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
   		if @validcnt <> @numrows
   		begin
   			select @errmsg = 'Cannot change Reward Seq'
   			goto error
   		end
   	end

	--Issue 119853
	if update(Date)
	begin
		declare update_curs cursor local fast_forward for
			select HRCo, HRRef, Seq, Date, HistSeq from inserted

		open update_curs

		fetch next from update_curs into @hrco, @hrref, @seq, @rewarddate, @histseq

		select @opencurs = 1
		
		while @@fetch_status = 0
		begin

			if @histseq is not null	--assume no history records were ever created.
			begin

				select @rewardhistyn = RewardHistYN, @rewardhist = RewardHistCode
				from bHRCO where HRCo = @hrco

				if @rewardhistyn = 'Y' and @rewardhist is not null
				begin
					if not exists(select 1 from bHREH where HRCo = @hrco and HRRef = @hrref and Seq = @histseq)
					begin
						goto inserthreh
					end
					else
					begin
						update bHREH set DateChanged = isnull(@rewarddate, convert(varchar(11), getdate()))
						where HRCo = @hrco and HRRef = @hrref and Seq = @histseq
						goto endloop
					end
				end
			end
			else
			begin	--insert
				goto inserthreh
			end

			inserthreh:

				select @histseq = isnull(max(Seq),0)+1 
				from dbo.bHREH with (nolock) 
				where HRCo = @hrco and HRRef = @hrref

				insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
				values (@hrco, @hrref, @histseq, @rewardhist, isnull(@rewarddate,convert(varchar(11), getdate())), 'H')

  				update dbo.bHRET 
				set HistSeq = @histseq 
				where HRCo = @hrco and HRRef = @hrref
 				and Seq = @seq

				goto endloop

			endloop:

			fetch next from update_curs into @hrco, @hrref, @seq, @rewarddate, @histseq

		end

		if @opencurs = 1 
		begin
			close update_curs
			deallocate update_curs
		end
	end
     

		--end 199853
   
   	select @validcnt = count(i.HRCo) from inserted i join dbo.bHRCM h with (nolock)
   	on i.HRCo = h.HRCo and i.Code = h.Code 
   	where h.Type = 'W'
   	if @validcnt <> @numrows
    	begin
    		select @errmsg = 'Invalid Reward Code'
   	 	goto error
    	end
   
   	/*Insert HQMA records*/
	if update(Date)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
   		select 'bHRRD', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
		' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
		i.HRCo, 'C','Date',
		convert(varchar(20),d.Date), Convert(varchar(20),i.Date),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d
		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.Date,'') <> isnull(d.Date,'') and e.AuditRewardsYN = 'Y'

	if update(Code)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
   		select 'bHRRD', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
		' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
		i.HRCo, 'C','Code',
		convert(varchar(10),d.Code), Convert(varchar(10),i.Code),
		getdate(), SUSER_SNAME()
    	from inserted i join deleted d
   		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.Code,'') <> isnull(d.Code,'') and e.AuditRewardsYN = 'Y'

	if update([Description])
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRRD', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
		' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
		i.HRCo, 'C','Description',
		convert(varchar(30),d.Description), Convert(varchar(30),i.Description),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d
   		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
   		join dbo.HRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.Description,'') <> isnull(d.Description,'') and e.AuditRewardsYN = 'Y'

	if update(RewardAmt)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRRD', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
		' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
		i.HRCo, 'C','RewardAmt',
		convert(varchar(12),d.RewardAmt), Convert(varchar(12),i.RewardAmt),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d
   		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.RewardAmt,0) <> isnull(d.RewardAmt,0) and e.AuditRewardsYN = 'Y'

	if update(Reason)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRRD', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
		' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
		i.HRCo, 'C','Reason',
		convert(varchar(30),d.Reason), Convert(varchar(30),i.Reason),
    	getdate(), SUSER_SNAME()
    	from inserted i join deleted d
   		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
   		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   		where isnull(i.Reason,'') <> isnull(d.Reason,'') and e.AuditRewardsYN = 'Y'
   
   return
   
    error:
    	select @errmsg = @errmsg + ' - cannot update HR Resource Reward!'
    	RAISERROR(@errmsg, 11, -1);
   
    	rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRRD] ON [dbo].[bHRRD] ([HRCo], [HRRef], [Seq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRRD] ([KeyID]) ON [PRIMARY]
GO
