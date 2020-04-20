CREATE TABLE [dbo].[bHRED]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[Seq] [smallint] NOT NULL,
[Date] [dbo].[bDate] NULL,
[Code] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[IncidentDesc] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DiscAction] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DaysSuspended] [tinyint] NULL,
[WarningNoticeYN] [dbo].[bYN] NOT NULL,
[FollowUpDate] [dbo].[bDate] NULL,
[HistSeq] [int] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bHRED] ADD
CONSTRAINT [CK_bHRED_WarningNoticeYN] CHECK (([WarningNoticeYN]='Y' OR [WarningNoticeYN]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE     trigger [dbo].[btHREDd] on [dbo].[bHRED] for Delete
   
   as
   
   

	/**************************************************************
   *	Created: 04/03/00 ae
   * 	Last Modified:  mh 10/11/02 added update to HREH
   *					mh 2/20/03 Issue 20486
   *					mh 3/16/04 23061
   *					mh 10/29/2008 - 127008
   *
   **************************************************************/
   
   	declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, 
   	@nullcnt int, @rcode int, @hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10), 
   	@disciplineseq int
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* Audit inserts */
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRED',  'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(d.HRRef,'')) +
    ' Seq: ' + convert(varchar(10),isnull(d.Seq,'')),
    d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    from deleted d join dbo.bHRCO e on
    e.HRCo = d.HRCo and e.AuditDisciplineYN = 'Y'
   
   	Return
   
   error:
   
   	select @errmsg = (@errmsg + ' - cannot delete HRED! ')
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE      trigger [dbo].[btHREDi] on [dbo].[bHRED] for INSERT as
   	

	/*-----------------------------------------------------------------
   	 *   	Created by: 	kb 2/25/99
   	 * 		Modified by: 	ae 03/31/00 added audits.
   	 *						mh 3/16/04 - 23061
	 *						mh 1/14/07 - 119853
	 *						mh 10/29/2008 - 127008  
   	 *
   	 *	This trigger rejects update in bHRED (Resource Discipline) if the
   	 *	following error condition exists:
   	 *
   	 *		Invalid HQ Company number
   	 *		Invalid HR Resource number
   	 *
   	 *
   	 *	Adds HR Employment History Record if HRCO_DisciplineHistYN = 'Y'
   	 */----------------------------------------------------------------
   
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
   	@hrco bCompany, @hrref bHRRef, @histseq int, @disipcode varchar(10), @disciplineseq int,
   	@disiplhistcode varchar(10), @disiplhistYN bYN, @datechgd bDate, @opencurs tinyint, @dispdate bDate
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* check for key changes */
   	select @validcnt = count(i.HRCo) from inserted i join dbo.bHQCO h with (nolock)
   	on i.HRCo =h.HQCo
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid HR Company'
   		goto error
   	end
   
   	select @validcnt = count(i.HRCo) from inserted i, dbo.bHRRM h with (nolock)
   	where i.HRCo = h.HRCo and i.HRRef = h.HRRef
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid Resource'
   		goto error
   	end
   
   	/* validate reason code*/
   	select @validcnt = count(i.HRCo) from inserted i, dbo.bHRCM h with (nolock) where i.HRCo = h.HRCo and
   	h.Code = i.Code and h.Type = 'N'
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid Reason Code'
   		goto error
   	end
   
   	/*Insert HREH Record*/
   	declare insert_curs cursor local fast_forward for
   	select HRCo, HRRef, Seq, Date from inserted i
   	where i.HRCo is not null and i.HRRef is not null and i.Seq is not null
   
   	open insert_curs
   
   	select @opencurs = 1
   
   	fetch next from insert_curs into @hrco, @hrref, @disciplineseq, @dispdate
   
   	while @@fetch_status = 0
   	begin
   		select @disiplhistYN = DisciplineHistYN, @disiplhistcode = DisciplineHistCode 
   		from dbo.bHRCO with (nolock) 
   		where HRCo = @hrco
   
   		if @disiplhistYN = 'Y' and @disiplhistcode is not null
   		begin
			--119853
   			select @histseq = isnull(max(Seq),0)+1, @datechgd = isnull(@dispdate, convert(varchar(11), getdate())) 
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @histseq, @disiplhistcode, @datechgd, 'H')
   
   	  		update dbo.bHRED
   			set HistSeq = @histseq 
   			where HRCo = @hrco and HRRef = @hrref
     			and Seq = @disciplineseq
   		end
   
   		fetch next from insert_curs into @hrco, @hrref, @disciplineseq, @dispdate
   
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   		select @opencurs = 0
   	end		
   
   
   	/* Audit inserts */
   
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
   	select 'bHRED', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
    ' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
    i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    from inserted i join dbo.bHRCO e with (nolock) on
   	e.HRCo = i.HRCo where e.AuditDisciplineYN = 'Y'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert HR Resource Discipline!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE      trigger [dbo].[btHREDu] on [dbo].[bHRED] for UPDATE as
    	

		/*-----------------------------------------------------------------
    	*	Created by: kb 2/25/99
    	* 	Modified by: ae 4/5/00 --added audits.
    	*				mh 9/5/02 --add update to HREH
    	*				mh 2/20/03 Issue 20486
    	*				mh 3/16/04 23061
   		*				mh 4/29/2005 - 28581 - Change HRRef conversion from varchar(5) to varchar(6)
		*				mh 1/14/2008 - 119853
		*				mh 10/29/2008 - 127008
    	*					
    	*	This trigger rejects update in bHRED (Companies) if the
    	*	following error condition exists:
    	*
    	*/----------------------------------------------------------------
    
    	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
    	@hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10), @disciplineseq int,
    	@disiplhistcode varchar(10), @disiplhistyn bYN, @opencurs tinyint, @disipldate bDate,
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
     			select @errmsg = 'Cannot change Discipline Seq'
     			goto error
     		end
     	end

		--Issue 119853
		if update(Date)
		begin
			declare update_curs cursor local fast_forward for
				select HRCo, HRRef, Seq, Date, HistSeq from inserted

			open update_curs
	
			fetch next from update_curs into @hrco, @hrref, @seq, @disipldate, @histseq

			select @opencurs = 1
			
			while @@fetch_status = 0
			begin

				if @histseq is not null	--assume no history records were ever created.
				begin

					select @disiplhistyn = DisciplineHistYN, @disiplhistcode = DisciplineHistCode
					from bHRCO where HRCo = @hrco

					if @disiplhistyn = 'Y' and @disiplhistcode is not null and @disipldate is not null
					begin
						if not exists(select 1 from bHREH where HRCo = @hrco and HRRef = @hrref and Seq = @histseq)
						begin
							goto inserthreh
						end
						else
						begin
							update bHREH set DateChanged = isnull(@disipldate, convert(varchar(11), getdate()))
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
   					values (@hrco, @hrref, @histseq, @disiplhistcode, isnull(@disipldate, convert(varchar(11), getdate())), 'H')
   
   	  				update dbo.bHRED 
   					set HistSeq = @histseq 
   					where HRCo = @hrco and HRRef = @hrref
     				and Seq = @seq

					goto endloop

				endloop:

				fetch next from update_curs into @hrco, @hrref, @seq, @disipldate, @histseq

			end

			if @opencurs = 1 
			begin
				close update_curs
				deallocate update_curs
			end
		end
     

		--end 199853
    
    	select @validcnt = count(i.HRCo) from inserted i join dbo.bHRCM h with (nolock) on
    	i.HRCo = h.HRCo and i.Code = h.Code 
    	where h.Type = 'N'
    	if @validcnt <> @numrows
     	begin
     		select @errmsg = 'Invalid Reason Code'
    	 	goto error
     	end
    
    	/*Insert HQMA records*/
		if update(Date)
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRED', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),i.HRRef) +
			' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
			i.HRCo, 'C','Date',
			convert(varchar(20),d.Date), Convert(varchar(20),i.Date),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and
    		i.Seq = d.Seq
    		join dbo.bHRCO e on i.HRCo = e.HRCo
    		where isnull(i.Date,'') <> isnull(d.Date,'') and e.AuditDisciplineYN = 'Y'

		if update(Code)
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRED', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),i.HRRef) +
			' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
			i.HRCo, 'C','Code',
			convert(varchar(10),d.Code), Convert(varchar(10),i.Code),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and
    		i.Seq = d.Seq
    		join dbo.bHRCO e on i.HRCo = e.HRCo
    		where isnull(i.Code,'') <> isnull(d.Code,'') and e.AuditDisciplineYN = 'Y'

		if update(DaysSuspended)
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRED', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),i.HRRef) +
			' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
			i.HRCo, 'C','DaysSuspended',
			convert(varchar(6),d.DaysSuspended), Convert(varchar(6),i.DaysSuspended),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and
    		i.Seq = d.Seq
    		join dbo.bHRCO e on i.HRCo = e.HRCo
    		where isnull(i.DaysSuspended,'') <> isnull(d.DaysSuspended,'') and e.AuditDisciplineYN = 'Y'

		if update(WarningNoticeYN)
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRED', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),i.HRRef) +
			' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
			i.HRCo, 'C','WarningNoticeYN',
			convert(varchar(1),d.WarningNoticeYN), Convert(varchar(1),i.WarningNoticeYN),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and
    		i.Seq = d.Seq
    		join dbo.bHRCO e on i.HRCo = e.HRCo
    		where isnull(i.WarningNoticeYN,'') <> isnull(d.WarningNoticeYN,'') and e.AuditDisciplineYN = 'Y'

		if update(FollowUpDate)
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
			select 'bHRED', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),i.HRRef) +
            ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
		    i.HRCo, 'C','FollowUpDate',
			convert(varchar(20),d.FollowUpDate), Convert(varchar(20),i.FollowUpDate),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and
    		i.Seq = d.Seq
    		join dbo.bHRCO e on i.HRCo = e.HRCo
    		where isnull(i.FollowUpDate,'') <> isnull(d.FollowUpDate,'') and e.AuditDisciplineYN = 'Y'
    
    	return
    
    error:
    
     	select @errmsg = @errmsg + ' - cannot update HR Resource Discipline!'
     	RAISERROR(@errmsg, 11, -1);
    
     	rollback transaction
    
    
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRED] ON [dbo].[bHRED] ([HRCo], [HRRef], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRED] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRED].[WarningNoticeYN]'
GO
