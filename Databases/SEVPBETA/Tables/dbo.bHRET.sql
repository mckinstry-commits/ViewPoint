CREATE TABLE [dbo].[bHRET]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[Seq] [int] NOT NULL,
[TrainCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Institution] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Class] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Date] [dbo].[bDate] NULL,
[Status] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Grade] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CEUCredits] [numeric] (4, 2) NULL,
[Hours] [dbo].[bHrs] NULL,
[DegreeYN] [dbo].[bYN] NOT NULL,
[DegreeDesc] [dbo].[bDesc] NULL,
[Cost] [dbo].[bDollar] NOT NULL,
[ReimbursedYN] [dbo].[bYN] NOT NULL,
[Instructor1099YN] [dbo].[bYN] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NULL,
[OSHAYN] [dbo].[bYN] NOT NULL,
[MSHAYN] [dbo].[bYN] NOT NULL,
[FirstAidYN] [dbo].[bYN] NOT NULL,
[CPRYN] [dbo].[bYN] NOT NULL,
[WorkRelatedYN] [dbo].[bYN] NOT NULL,
[HistSeq] [int] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHRET_Type] DEFAULT ('T'),
[ClassSeq] [int] NULL,
[CompleteDate] [dbo].[bDate] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE     trigger [dbo].[btHRETd] on [dbo].[bHRET] for Delete
   as
   
   	 

/**************************************************************
   	 * 	Created: 04/03/00 ae
   	 * 	Last Modified:  mh Added update to HREH
   	 *					mh 2/20/03 Issue 20486
   	 *					mh 3/16/04 23061
	 *					mh 10/29/2008 - 127008
   	 *
   	 **************************************************************/
   
   	declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int,
   	@nullcnt int, @rcode int, @hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10), @trainseq int
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* Audit inserts */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(d.HRRef,'')) +
    ' Seq: ' + convert(varchar(10),isnull(d.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(d.TrainCode,'')),
    d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    from deleted d join dbo.bHRCO e with (nolock) on 
    e.HRCo = d.HRCo 
   	where e.AuditTrainingYN = 'Y'
   
   	Return
   	error:
   	select @errmsg = (@errmsg + ' - cannot delete HRET! ')
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE          trigger [dbo].[btHRETi] on [dbo].[bHRET] for INSERT as
   	

/*-----------------------------------------------------------------
   	*	Created by: kb 2/25/99
   	* 	Modified by: ae 3/31/00 added audits.
   	*					mh 2/24/04 - Expanded status codes. Added Absent and Canceled.
   	*					mh 3/16/04 23061
   	*					mh 07/14/04 25029
	*					mh 01/11/2008 Issue 119853.
	*					mh 10/29/2008 - 127008 
   	*
   	*	This trigger rejects update in bHRET (Resource Training) if the
   	*	following error condition exists:
   	*
   	*		Invalid HQ Company number
   	*		Invalid HR Resource number
   	*
   	*
   	*	Adds HR Employment History Record if HRCO_TrainHistYN = 'Y'
   	*/----------------------------------------------------------------
   
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, 
   	@hrco bCompany, @hrref bHRRef, @trainseq int, @opencurs tinyint, @trainhistyn bYN, 
   	@trainhistcode varchar(10), @histseq int, @classdate bDate
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* check for key changes */
   	select @validcnt = count(i.HRCo) 
   	from inserted i join bHQCO h with (nolock) on 
   	i.HRCo = h.HQCo
   	if @validcnt <> @numrows
    	begin
   	 	select @errmsg = 'Invalid HR Company'
    		goto error
    	end
   
   	select @validcnt = count(i.HRCo) 
   	from inserted i join bHRRM h with (nolock) on
   	i.HRCo = h.HRCo and i.HRRef = h.HRRef
   	if @validcnt <> @numrows
    	begin
    		select @errmsg = 'Invalid Resource'
   	 	goto error
    	end
   
   	/* validate train code*/
   	select @validcnt = count(i.HRCo) 
   	from inserted i join bHRCM h on 
   	i.HRCo = h.HRCo and h.Code = i.TrainCode 
   	where h.Type = 'T'
   	if @validcnt <> @numrows
    	begin
    		select @errmsg = 'Invalid Training Code'
   	 	goto error
    	end
   
   	select @validcnt = count(i.HRCo) 
   	from inserted i 
   	where Status in ('U','S','I','C','A','X')
   	if @validcnt<>@numrows
    	begin
    		select @errmsg = 'Status must be (U)-Unscheduled, (S)-Scheduled, (I)-In Progress,
    		(C)-Completed, (A) - Absent, or (X) - Canceled'
   	 	goto error
    	end
   
   	select @validcnt = count(i.HRCo) from inserted i 
   	where VendorGroup is not null
   	if @validcnt > 0
    	begin
    		select @validcnt2 = count(i.HRCo) 
   		from inserted i join bHQGP h on i.VendorGroup = h.Grp
   	 	if @validcnt <> @validcnt2
    		begin
    			select @errmsg = 'Invalid Vendor Group'
    			goto error
    		end
    	end
   
   	select @validcnt = count(i.HRCo) 
   	from inserted i where Vendor is not null
   	if @validcnt > 0
    	begin
    		select @validcnt2 = count(i.HRCo) from inserted i join bAPVM h
    		on i.VendorGroup = h.VendorGroup and i.Vendor = h.Vendor
   	 	if @validcnt <> @validcnt2
    		begin
    			select @errmsg = 'Invalid Vendor'
    			goto error
    		end
    	end
  
   	/*Insert HREH Record*/
   	declare insert_curs cursor local fast_forward for
   	select HRCo, HRRef, Seq, Date from inserted i
   	where i.HRCo is not null and i.HRRef is not null and i.Seq is not null
   
   	open insert_curs
   
   	select @opencurs = 1
   
   	fetch next from insert_curs into @hrco, @hrref, @trainseq, @classdate
   
   	while @@fetch_status = 0
   	begin
   		select @trainhistyn = TrainHistYN, @trainhistcode = TrainHistCode 
   		from dbo.bHRCO with (nolock) 
   		where HRCo = @hrco
   
   		if @trainhistyn = 'Y' and @trainhistcode is not null
   		begin
   			select @histseq = isnull(max(Seq),0)+1 
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @histseq, @trainhistcode, isnull(@classdate, convert(varchar(11), getdate())), 'H')
   
   	  		update dbo.bHRET 
   			set HistSeq = @histseq 
   			where HRCo = @hrco and HRRef = @hrref and Seq = @trainseq
   		end
   
   		fetch next from insert_curs into @hrco, @hrref, @trainseq, @classdate
   
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   		select @opencurs = 0
   	end
   
   	/* Audit inserts */

	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)   
   	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
    ' Seq: ' + convert(varchar(10),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
    i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    from inserted i join dbo.bHRCO e with (nolock) on e.HRCo = i.HRCo
   	where e.AuditTrainingYN = 'Y'
   
   	return
   
   error:
   
   	 	select @errmsg = @errmsg + ' - cannot insert HR Resource Training!'
    		RAISERROR(@errmsg, 11, -1);
   
   	 	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE              trigger [dbo].[btHRETu] on [dbo].[bHRET] for UPDATE as
    	

		/*-----------------------------------------------------------------
    	*	Created by: kb 2/25/99
    	* 	Modified by: ae 04/04/00 -added audits
    	*					 mh 9/5/02 - added updates to HREH
    	*					mh 2/20/03 Issue 20486
    	*					mh 3/16/04 23061
    	*					mh 3/26/04 18429 - added audit for CompleteDate
    	*					mh 4/8/04 - added Training Code to keystring.
    	*					mh 7/14/04 - 25029  
   		*					mh 4/29/2005 - 28581 - Change HRRef conversion from varchar(5) to varchar(6)
		*					mh 1/11/2008 - 119853
		*					mh 10/29/2008 - 127008
		*					mh 05/05/2009 - 132858 - Corrected HREH updates.  Was inserted record when flag
		*						turned off in HRCO.
    	*
    	*	This trigger rejects update in bHRET (Companies) if the
    	*	following error condition exists:
    	*
    	*
    	*	Adds HR Employment History Record if HRCO_TrainHistYN = 'Y'
    	*/----------------------------------------------------------------
     
    	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
     	@hrco bCompany, @hrref bHRRef, @seq int, @histseq int, @code varchar(10), @trainseq int,
		@classdate bDate, @trainhistcode varchar(10), @trainhistyn bYN, @opencurs tinyint
     
    	select @numrows = @@rowcount
    	if @numrows = 0 return
    	set nocount on
     
    	/* check for key changes */
    	if update(HRCo)
    	begin
    		select @validcnt = count(i.HRCo) 
    		from inserted i join deleted d on 
    		i.HRCo = d.HRCo
    		if @validcnt <> @numrows
    		begin
    			select @errmsg = 'Cannot change HR Company'
    			goto error
    		end
    	end
     
    	if update(HRRef)
    	begin
    		select @validcnt = count(i.HRCo) 
    		from inserted i join deleted d on 
    		i.HRCo = d.HRCo and i.HRRef = d.HRRef
    		if @validcnt <> @numrows
    		begin
    			select @errmsg = 'Cannot change HR Resource'
    			goto error
    		end
    	end
     
    	if update(Seq)
    	begin
    		select @validcnt = count(i.HRCo) 
    		from inserted i join deleted d on
    		i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    		if @validcnt <> @numrows
    		begin
    			select @errmsg = 'Cannot change Training Seq'
    			goto error
    		end
    	end

		--Issue 119853
		if update(Date)
		begin
			declare update_curs cursor local fast_forward for
				select HRCo, HRRef, Seq, Date, HistSeq from inserted

			open update_curs
	
			fetch next from update_curs into @hrco, @hrref, @seq, @classdate, @histseq

			select @opencurs = 1
			
			while @@fetch_status = 0
			begin

				if @histseq is not null	--assume no history records were ever created.
				begin

					select @trainhistyn = TrainHistYN, @trainhistcode = TrainHistCode
					from bHRCO where HRCo = @hrco

					if @trainhistyn = 'Y' and @trainhistcode is not null and @classdate is not null
					begin
						if not exists(select 1 from bHREH where HRCo = @hrco and HRRef = @hrref and Seq = @histseq)
						begin
							goto inserthreh
						end
						else
						begin
							update bHREH set DateChanged = isnull(@classdate, convert(varchar(11), getdate()))
							where HRCo = @hrco and HRRef = @hrref and Seq = @histseq

							goto endloop
						end
					end
					else
					begin
						--132858 Without this code would drop into the insert to HREH if the "if" statement
						--evaluated to false.
						goto endloop
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
   					values (@hrco, @hrref, @histseq, @trainhistcode, isnull(@classdate, convert(varchar(11), getdate())), 'H')
   
   	  				update dbo.bHRET 
   					set HistSeq = @histseq 
   					where HRCo = @hrco and HRRef = @hrref
     				and Seq = @trainseq

					goto endloop

				endloop:

				fetch next from update_curs into @hrco, @hrref, @seq, @classdate, @histseq

			end

			if @opencurs = 1 
			begin
				close update_curs
				deallocate update_curs
			end
		end
     

		--end 199853

    	select @validcnt = count(i.HRCo) 
    	from inserted i join dbo.bHRCM h with (nolock) on 
    	i.HRCo = h.HRCo and i.TrainCode = h.Code and h.Type = 'T'
    	if @validcnt <> @numrows
      	begin
      		select @errmsg = 'Invalid Training Code'
    	  	goto error
      	end
     
    	select @validcnt = count(i.HRCo) from inserted i where Status in ('U','S','I','C','A','X')
    	if @validcnt<>@numrows
    	begin
    		select @errmsg = 'Status must be (U)-Unscheduled, (S)-Scheduled, (I)-In Progress,
    		(C)-Completed, (A) - Absent, or (X) - Canceled'
    		goto error
    	end
     
    	select @validcnt = count(i.HRCo) from inserted i where VendorGroup is not null
    	if @validcnt > 0
      	begin
      		select @validcnt2 = count(i.HRCo) 
    		from inserted i join dbo.bHQGP h with (nolock) on
    		i.VendorGroup = h.Grp
    	  	if @validcnt <> @validcnt2
      		begin
    	  		select @errmsg = 'Invalid Vendor Group'
      			goto error
      		end
      	end
     
    	select @validcnt = count(i.HRCo) from inserted i where Vendor is not null
    	if @validcnt > 0
      	begin
      		select @validcnt2 = count(i.HRCo) 
    		from inserted i join dbo.bAPVM h with (nolock) on
      			i.VendorGroup = h.VendorGroup and i.Vendor = h.Vendor
      		if @validcnt <> @validcnt2
      		begin
      			select @errmsg = 'Invalid Vendor'
      			goto error
      		end
      	end
    
    
    	/*Insert HQMA records*/
	if update(TrainCode)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','TrainCode',
        convert(varchar(10),d.TrainCode), Convert(varchar(10),i.TrainCode),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.TrainCode,'') <> isnull(d.TrainCode,'') and e.AuditTrainingYN  = 'Y'

	if update(Description)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','Description',
        convert(varchar(30),d.Description), Convert(varchar(30),i.Description),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Description,'') <> isnull(d.Description,'') and e.AuditTrainingYN  = 'Y'

	if update(Institution)    
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','Institution',
        convert(varchar(30),d.Institution), Convert(varchar(30),i.Institution),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Institution,'') <> isnull(d.Institution,'') and e.AuditTrainingYN  = 'Y'

	if update(Class)    
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','Class',
        convert(varchar(30),d.Class), Convert(varchar(30),i.Class),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Class,'') <> isnull(d.Class,'') and e.AuditTrainingYN  = 'Y'

	if update(Date)    
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','Date',
        convert(varchar(20),d.Date), Convert(varchar(20),i.Date),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Date,'') <> isnull(d.Date,'') and e.AuditTrainingYN  = 'Y'

	if update(Status)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','Status',
        convert(varchar(1),d.Status), Convert(varchar(1),i.Status),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Status,'') <> isnull(d.Status,'') and e.AuditTrainingYN  = 'Y'

	if update(CompleteDate)    
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','CompleteDate',
        convert(varchar(11),d.CompleteDate), Convert(varchar(11),i.CompleteDate),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.CompleteDate,'') <> isnull(d.CompleteDate,'') and e.AuditTrainingYN  = 'Y'

	if update(Grade)    
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','Grade',
        convert(varchar(10),d.Grade), Convert(varchar(10),i.Grade),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Grade,'') <> isnull(d.Grade,'') and e.AuditTrainingYN  = 'Y'

	if update(CEUCredits)    
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','CEUCredits',
        convert(varchar(10),d.CEUCredits), Convert(varchar(10),i.CEUCredits),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.CEUCredits,0) <> isnull(d.CEUCredits,0) and e.AuditTrainingYN  = 'Y'

	if update(Hours)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','Hours',
        convert(varchar(20),d.Hours), Convert(varchar(20),i.Hours),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Hours,0) <> isnull(d.Hours,0) and e.AuditTrainingYN  = 'Y'

	if update(DegreeYN)    
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','DegreeYN',
        convert(varchar(1),d.DegreeYN), Convert(varchar(1),i.DegreeYN),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.DegreeYN,'') <> isnull(d.DegreeYN,'') and e.AuditTrainingYN  = 'Y'

	if update(DegreeDesc)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','DegreeDesc',
        convert(varchar(30),d.DegreeDesc), Convert(varchar(30),i.DegreeDesc),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.DegreeDesc,'') <> isnull(d.DegreeDesc,'') and e.AuditTrainingYN  = 'Y'

	if update(Cost)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','Cost',
        convert(varchar(12),d.Cost), Convert(varchar(12),i.Cost),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Cost,0) <> isnull(d.Cost,0) and e.AuditTrainingYN  = 'Y'

	if update(ReimbursedYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','ReimbursedYN',
        convert(varchar(1),d.ReimbursedYN), Convert(varchar(1),i.ReimbursedYN),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.ReimbursedYN,'') <> isnull(d.ReimbursedYN,'') and e.AuditTrainingYN  = 'Y'

	if update(Instructor1099YN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','Instructor1099YN',
        convert(varchar(1),d.Instructor1099YN), Convert(varchar(1),i.Instructor1099YN),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Instructor1099YN,'') <> isnull(d.Instructor1099YN,'') and e.AuditTrainingYN  = 'Y'

	if update(VendorGroup)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','VendorGroup',
        convert(varchar(6),d.VendorGroup), Convert(varchar(6),i.VendorGroup),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.VendorGroup,0) <> isnull(d.VendorGroup,0) and e.AuditTrainingYN  = 'Y'

	if update(Vendor)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','Vendor',
        convert(varchar(6),d.Vendor), Convert(varchar(6),i.Vendor),
       	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.Vendor,0) <> isnull(d.Vendor,0) and e.AuditTrainingYN  = 'Y'

	if update(OSHAYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','OSHAYN',
        convert(varchar(1),d.OSHAYN), Convert(varchar(1),i.OSHAYN),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.OSHAYN,'') <> isnull(d.OSHAYN,'') and e.AuditTrainingYN  = 'Y'

	if update(MSHAYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','MSHAYN',
        convert(varchar(1),d.MSHAYN), Convert(varchar(1),i.MSHAYN),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.MSHAYN,'') <> isnull(d.MSHAYN,'') and e.AuditTrainingYN  = 'Y'

	if update(FirstAidYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)     
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','FirstAidYN',
        convert(varchar(1),d.FirstAidYN), Convert(varchar(1),i.FirstAidYN),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.FirstAidYN,'') <> isnull(d.FirstAidYN,'') and e.AuditTrainingYN  = 'Y'

	if update(CPRYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','CPRYN',
        convert(varchar(1),d.CPRYN), Convert(varchar(1),i.CPRYN),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.CPRYN,'') <> isnull(d.CPRYN,'') and e.AuditTrainingYN  = 'Y'

	if update(WorkRelatedYN)     
    	insert into dbo.bHQMA select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','WorkRelatedYN',
        convert(varchar(1),d.WorkRelatedYN), Convert(varchar(1),i.WorkRelatedYN),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.WorkRelatedYN,'') <> isnull(d.WorkRelatedYN,'') and e.AuditTrainingYN  = 'Y'

	if update(ClassSeq)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    	select 'bHRET', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
        i.HRCo, 'C','ClassSeq',
        convert(varchar(1),d.ClassSeq), Convert(varchar(1),i.ClassSeq),
      	getdate(), SUSER_SNAME()
    	from inserted i join deleted d on 
    	i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.Seq = d.Seq
    	join dbo.bHRCO e with (nolock) on 
    	i.HRCo = e.HRCo
    	where isnull(i.ClassSeq,0) <> isnull(d.ClassSeq,0) and e.AuditTrainingYN  = 'Y'
     
    	return
     
    error:

      	select @errmsg = @errmsg + ' - cannot update HR Resource Training!'
      	RAISERROR(@errmsg, 11, -1);
     
      	rollback transaction
    
    
    
    
    
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRET] ON [dbo].[bHRET] ([HRCo], [HRRef], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRET] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRET].[DegreeYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRET].[ReimbursedYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRET].[Instructor1099YN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRET].[OSHAYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRET].[MSHAYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRET].[FirstAidYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRET].[CPRYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRET].[WorkRelatedYN]'
GO
