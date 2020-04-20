CREATE TABLE [dbo].[bHRDT]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[Date] [dbo].[bDate] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[Location] [dbo].[bDesc] NULL,
[Tester] [dbo].[bDesc] NULL,
[TestType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[TestStatus] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Results] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ActionTaken] [varchar] (max) COLLATE Latin1_General_BIN NULL,
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
 
  
   
   
   
   CREATE      trigger [dbo].[btHRDTd] on [dbo].[bHRDT] for Delete
   as
   
   	 

	/**************************************************************
   	 *	Created: 04/03/00 ae
   	 *	Last Modified:  mh 10/11/02
   	 *					mh 3/4/04 Issue 20486
	 *					mh 10/29/2008 - 127008
   	 *
   	 **************************************************************/
   
   	declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @numrows int, 
   	@nullcnt int, @rcode int
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* Audit inserts */
   	insert into dbo.bHQMA select 'bHRDT','HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(d.HRRef,'')),
    	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    	from deleted d join dbo.bHRCO e with (nolock) on e.HRCo = d.HRCo 
   	where e.AuditDrugYN  = 'Y'
   
    Return
    error:
    select @errmsg = (@errmsg + ' - cannot delete HRDT! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE          trigger [dbo].[btHRDTi] on [dbo].[bHRDT] for INSERT as
   
   	

/*-----------------------------------------------------------------
   	 *   	Created by: 	kb 2/25/99
   	 * 		Modified by: 	ae 3/31/00 added audits.
   	 *						mh 3/16/04 - 23061
	 *						mh 10/29/2008 - 127008
   	 *
   	 *	This trigger rejects update in bHRDT (Resource Drug Testing) if the
   	 *	following error condition exists:
   	 *
   	 *		Invalid HQ Company number
   	 *		Invalid HR Resource number
   	 *
   	 *	Adds HR Employment History Record if HRCO_DrugHistYN = 'Y'
   	 */----------------------------------------------------------------
   
   	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, 
   	@hrco bCompany, @hrref bHRRef, @histseq int, @date bDate, @drughistcode varchar(10), 
   	@drughistyn bYN, @opencurs tinyint
   
   
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   	set nocount on
   
   	/* check for key changes */
   	select @validcnt = count(i.HRCo) from inserted i join dbo.bHQCO h on
   	i.HRCo = h.HQCo
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid HR Company'
   		goto error
   	end
   
   	select @validcnt = count(i.HRCo) from inserted i join dbo.bHRRM h on
   	i.HRCo = h.HRCo and i.HRRef = h.HRRef
   	if @validcnt <> @numrows
   	begin
   		select @errmsg = 'Invalid Resource'
   		goto error
   	end
   
   	/* validate jcco*/
   	select @validcnt = count(i.HRCo) from inserted i where i.JCCo is not null
   	if @validcnt > 0
   	begin
   		select @validcnt2 = count(i.HRCo) from inserted i join dbo.bJCCO h with (nolock) on
   		i.JCCo = h.JCCo
   		if @validcnt <> @validcnt2
   		begin
   			select @errmsg = 'Invalid JC Company'
   			goto error
   		end
   	end
   
   	select @validcnt = count(i.HRCo) from inserted i where i.Job is not null
   	if @validcnt > 0
   	begin
   		select @validcnt2 = count(i.HRCo) from inserted i join dbo.bJCJM h with (nolock) on
   		i.JCCo = h.JCCo and i.Job = h.Job
   		if @validcnt <> @validcnt2
   		begin
   			select @errmsg = 'Invalid Job'
   			goto error
   		end
   	end
   
   	select @validcnt = count(i.HRCo) from inserted i
   	join dbo.bHRCM cm with (nolock) on i.TestType = cm.Code and i.HRCo = cm.HRCo
   	where cm.Type = 'D'
   	if @validcnt<>@numrows
   	begin
   		select @errmsg = 'Test Type selected must have a Type code (D) - Drug Testing'
   		goto error
   	end
   
   	/*Insert HREH Record*/
   	declare insert_curs cursor local fast_forward for
   	select HRCo, HRRef, Date from inserted i
   	where i.HRCo is not null and i.HRRef is not null and i.Date is not null
   
   	open insert_curs
   
   	select @opencurs = 1
   
   	fetch next from insert_curs into @hrco, @hrref, @date
   
   	while @@fetch_status = 0
   	begin
   		select @drughistyn = DrugHistYN, @drughistcode = DrugHistCode 
   		from dbo.bHRCO with (nolock) 
   		where HRCo = @hrco
   
   		if @drughistyn = 'Y' and @drughistcode is not null
   		begin
   			select @histseq = isnull(max(Seq),0)+1
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @histseq, @drughistcode, @date, 'H')
   
   	  		update dbo.bHRDT 
   			set HistSeq = @histseq 
   			where HRCo = @hrco and HRRef = @hrref
     			and Date = @date
   		end
   
   		fetch next from insert_curs into @hrco, @hrref, @date
   
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   		select @opencurs = 0
   	end		
   
   	 /* Audit inserts */
   	insert into dbo.bHQMA select 'bHRDT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')),
    	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    	from inserted i join dbo.bHRCO e with (nolock) on
       e.HRCo = i.HRCo where e.AuditDrugYN = 'Y'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert HR Resource Drug Testing!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
   
   
   
   
   
   
   
  
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE           trigger [dbo].[btHRDTu] on [dbo].[bHRDT] for UPDATE as
    
    	

		/*-----------------------------------------------------------------
    	*  Created by: ae 04/04/00
    	* 	Modified by: mh 3/4/03 Issue 20486
    	*				mh 3/16/04 23061
   		*				mh 4/29/05 - 28581 convert HRRef from varchar(5) to varchar(6)
		*				mh 10/29/2008 - 127008
    	*/----------------------------------------------------------------
    
    	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
    	@hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10), @date bDate
    
    	select @numrows = @@rowcount
    	if @numrows = 0 return
    	set nocount on

		if update(JCCo)    
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRDT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' Date: ' + convert(varchar(20),isnull(i.Date,'')), i.HRCo, 'C','JCCo',
			convert(varchar(1),d.JCCo), Convert(varchar(1),i.JCCo),
    		getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.HRCo = d.HRCo and 
    		i.HRRef = d.HRRef and i.Date = d.Date
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.JCCo,0) <> isnull(d.JCCo,0) and AuditDrugYN = 'Y'
    
		if update(Job)
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRDT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' Date: ' + convert(varchar(20),isnull(i.Date,'')),
			i.HRCo, 'C','Job',
			convert(varchar(1),d.Job), Convert(varchar(1),i.Job),
    		getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.HRCo = d.HRCo and 
    		i.HRRef = d.HRRef and i.Date = d.Date
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.Job,'') <> isnull(d.Job,'') and AuditDrugYN = 'Y'

		if update(Location)
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    		select 'bHRDT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' Date: ' + convert(varchar(20),isnull(i.Date,'')),
			i.HRCo, 'C','Location',
			convert(varchar(30),d.Location), Convert(varchar(30),i.Location),
    		getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.HRCo = d.HRCo and 
    		i.HRRef = d.HRRef and i.Date = d.Date
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.Location,'') <> isnull(d.Location,'') and AuditDrugYN = 'Y'

		if update(Tester)
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
    		select 'bHRDT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' Date: ' + convert(varchar(20),isnull(i.Date,'')),
			i.HRCo, 'C','Tester',
			convert(varchar(30),d.Tester), Convert(varchar(30),i.Tester),
    		getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.HRCo = d.HRCo and 
    		i.HRRef = d.HRRef and i.Date = d.Date
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.Tester,'') <> isnull(d.Tester,'') and AuditDrugYN = 'Y'

		if update(TestType)    
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRDT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' Date: ' + convert(varchar(20),isnull(i.Date,'')),
			i.HRCo, 'C','TestType',
			convert(varchar(10),d.TestType), Convert(varchar(10),i.TestType),
    		getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.HRCo = d.HRCo and 
    		i.HRRef = d.HRRef and i.Date = d.Date
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.TestType,'') <> isnull(d.TestType,'') and AuditDrugYN = 'Y'

		if update(TestStatus)    
			insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
    		select 'bHRDT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' Date: ' + convert(varchar(20),isnull(i.Date,'')),
			i.HRCo, 'C','TestStatus',
			convert(varchar(1),d.TestStatus), Convert(varchar(1),i.TestStatus),
    		getdate(), SUSER_SNAME()
    		from inserted i join deleted d on i.HRCo = d.HRCo and 
    		i.HRRef = d.HRRef and i.Date = d.Date
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.TestStatus,'') <> isnull(d.TestStatus,'') and AuditDrugYN = 'Y'
    
    
    return
    
    error:
    
    	select @errmsg = @errmsg + ' - cannot update HRDT!'
    	RAISERROR(@errmsg, 11, -1);
    
    	rollback transaction
    
    
    
    
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRDT] ON [dbo].[bHRDT] ([HRCo], [HRRef], [Date]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRDT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
