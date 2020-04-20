CREATE TABLE [dbo].[bHREG]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[Seq] [smallint] NOT NULL,
[Date] [dbo].[bDate] NULL,
[Grievance] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Outcome] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[HearingDate] [dbo].[bDate] NULL,
[FinalAppealDate] [dbo].[bDate] NULL,
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
 
  
   
   
   
   
   
   
   CREATE     trigger [dbo].[btHREGd] on [dbo].[bHREG] for Delete
   as
   
   	

/**************************************************************
   	* 	Created: 04/03/00 ae
   	* 	Last Modified:  mh 3/16/04 23061
	*					mh 10/29/2008 - 127008
   	*
   	*
   	**************************************************************/
   
   	declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* Audit inserts */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
   	select 'bHREG',  'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(d.HRRef,'')) +
    ' Seq: ' + convert(varchar(10),isnull(d.Seq,'')),
    d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    from deleted d join dbo.bHRCO e with (nolock) on
    e.HRCo = d.HRCo 
   	where e.AuditGrievanceYN = 'Y'
   
   	Return
   
   error:
   
   	select @errmsg = (@errmsg + ' - cannot delete HREG! ')
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE      trigger [dbo].[btHREGi] on [dbo].[bHREG] for INSERT as
   	

	/*-----------------------------------------------------------------
   	 *   	Created by: kb 2/25/99
   	 * 		Modified by: ae 3/31/00 added audits.
   	 *					mh 3/15/04 23061
	 *					mh 01/14/08 119853
	 *					mh 10/29/2008 - 127008
   	 *
   	 *	This trigger rejects update in bHREG (Resource Grievances) if the
   	 *	following error condition exists:
   	 *
   	 *		Invalid HQ Company number
   	 *		Invalid HR Resource number
   	 *
   	 *
   	 *	Adds HR Employment History Record if HRCO_GrievHistYN = 'Y'
   	 */----------------------------------------------------------------
   
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @datechgd bDate,
   	@hrco bCompany, @hrref bHRRef, @histseq int, @grievseq int, @grievhistcode varchar(10), 
   	@grievhistcodeyn bYN, @opencurs tinyint, @reportdate bDate
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* check for key changes */
   	select @validcnt = count(i.HRCo) from inserted i join dbo.bHQCO h on
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
   
   	/*Insert HREH Record*/
   	declare insert_curs cursor local fast_forward for
   	select HRCo, HRRef, Seq, Date from inserted i
   	where i.HRCo is not null and i.HRRef is not null and i.Seq is not null
   
   	open insert_curs
   
   	select @opencurs = 1
   
   	fetch next from insert_curs into @hrco, @hrref, @grievseq, @reportdate
   
   	while @@fetch_status = 0
   	begin
   		select @grievhistcodeyn = GrievHistYN, @grievhistcode = GrievanceHistCode 
   		from dbo.bHRCO with (nolock) 
   		where HRCo = @hrco
   
   		if @grievhistcodeyn = 'Y' and @grievhistcode is not null
   		begin
   			select @histseq = isnull(max(Seq),0)+1, @datechgd = isnull(@reportdate, convert(varchar(11), getdate())) 
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @histseq, @grievhistcode, @datechgd, 'H')
   
   	  		update dbo.bHREG 
   			set HistSeq = @histseq 
   			where HRCo = @hrco and HRRef = @hrref
     			and Seq = @grievseq
   		end
   
   		fetch next from insert_curs into @hrco, @hrref, @grievseq, @reportdate
   
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   		select @opencurs = 0
   	end		
   
   	/* Audit inserts */

	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)   
	select 'bHREG', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
	' Seq: ' + convert(varchar(10),isnull(i.Seq,'')),
	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
	from inserted i join dbo.bHRCO e on
	e.HRCo = i.HRCo where e.AuditGrievanceYN = 'Y'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert HR Resource Grievance!' 	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE      trigger [dbo].[btHREGu] on [dbo].[bHREG] for UPDATE as
    	

		/*-----------------------------------------------------------------
    	*  	Created by: kb 2/25/99
    	* 	Modified by: ae 04/05/00 added audits.
    	*					mh 9/5/02 added update to HREH
    	*					mh 2/20/03 Issue 20486
    	*					mh 3/16/04 Issue 23061
   		*					mh 4/29/2005 - 28581 - Change HRRef conversion from varchar(5) to varchar(6)
		*					mh 01/14/2008 - 119853
		*					mh 10/29/2008 - 127008
    	*
    	*	This trigger rejects update in bHREG (Companies) if the
    	*	following error condition exists:
    	*
    	*
    	*	Adds HR Employment History Record if HRCO_GrievHistYN = 'Y'
    	*/----------------------------------------------------------------
    
    	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
    	@hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10), @grievseq int,
		@reportdate bDate, @opencurs tinyint, @histseq int, @grievhistyn bYN, 
		@grievhistcode varchar(10)
    
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
     			select @errmsg = 'Cannot change Grievance Seq'
    	 		goto error
     		end
     	end
    
		--Issue 119853
		if update(Date)
		begin
			declare update_curs cursor local fast_forward for
				select HRCo, HRRef, Seq, Date, HistSeq from inserted

			open update_curs
	
			fetch next from update_curs into @hrco, @hrref, @seq, @reportdate, @histseq

			select @opencurs = 1
			
			while @@fetch_status = 0
			begin

				if @histseq is not null	--assume no history records were ever created.
				begin

					select @grievhistyn = GrievHistYN, @grievhistcode = GrievanceHistCode
					from bHRCO where HRCo = @hrco

					if @grievhistyn = 'Y' and @grievhistcode is not null and @reportdate is not null
					begin
						if not exists(select 1 from bHREH where HRCo = @hrco and HRRef = @hrref and Seq = @histseq)
						begin
							goto inserthreh
						end
						else
						begin
							update bHREH set DateChanged = isnull(@reportdate, convert(varchar(11), getdate()))
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
   					values (@hrco, @hrref, @histseq, @grievhistcode, isnull(@reportdate, convert(varchar(11), getdate())), 'H')
   
   	  				update dbo.bHRET 
   					set HistSeq = @histseq 
   					where HRCo = @hrco and HRRef = @hrref
     				and Seq = @seq

					goto endloop

				endloop:

				fetch next from update_curs into @hrco, @hrref, @seq, @reportdate, @histseq

			end

			if @opencurs = 1 
			begin
				close update_curs
				deallocate update_curs
			end
		end
     

		--end 199853

	if update(Date)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHREG', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
        i.HRCo, 'C','Date',
        convert(varchar(20),d.Date), Convert(varchar(20),i.Date),
     	getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.HRCo = d.HRCo and 
    	i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo 
    	where isnull(i.Date,'') <> isnull(d.Date,'') and e.AuditGrievanceYN = 'Y'

	if update(HearingDate)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHREG', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
        i.HRCo, 'C','HearingDate',
        convert(varchar(20),d.HearingDate), Convert(varchar(20),i.HearingDate),
     	getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.HRCo = d.HRCo and 
    	i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo 
    	where isnull(i.HearingDate,'') <> isnull(d.HearingDate,'') and e.AuditGrievanceYN = 'Y'

	if update(FinalAppealDate)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHREG', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
        i.HRCo, 'C','FinalAppealDate',
        convert(varchar(20),d.FinalAppealDate), Convert(varchar(20),i.FinalAppealDate),
     	getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.HRCo = d.HRCo and 
    	i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo 
    	where isnull(i.FinalAppealDate,'') <> isnull(d.FinalAppealDate,'') and e.AuditGrievanceYN = 'Y'
    
    	return
    
    error:
    
     	select @errmsg = @errmsg + ' - cannot update HR Resource Grievance!'
     	RAISERROR(@errmsg, 11, -1);
    
     	rollback transaction
    
    
    
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHREG] ON [dbo].[bHREG] ([HRCo], [HRRef], [Seq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHREG] ([KeyID]) ON [PRIMARY]
GO
