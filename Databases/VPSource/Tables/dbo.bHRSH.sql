CREATE TABLE [dbo].[bHRSH]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[EffectiveDate] [dbo].[bDate] NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NULL,
[OldSalary] [dbo].[bUnitCost] NULL,
[NewSalary] [dbo].[bUnitCost] NULL,
[NewPositionCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[NextDate] [dbo].[bDate] NULL,
[UpdatedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRSH_UpdatedYN] DEFAULT ('N'),
[HistSeq] [int] NULL,
[CalcYN] [dbo].[bYN] NOT NULL,
[BatchId] [dbo].[bBatchID] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bHRSH] ADD
CONSTRAINT [CK_bHRSH_UpdatedYN] CHECK (([UpdatedYN]='Y' OR [UpdatedYN]='N'))
ALTER TABLE [dbo].[bHRSH] ADD
CONSTRAINT [CK_bHRSH_CalcYN] CHECK (([CalcYN]='Y' OR [CalcYN]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE       trigger [dbo].[btHRSHd] on [dbo].[bHRSH] for Delete
   as
   	

/**************************************************************
   	* Created: 04/03/00 ae
   	* Last Modified:  mh 10/11/02 Added update to HREH
   	*					mh 03/17/03 - Issue 20486
   	*					mh 3/17/04 - 23061
   	*					mh 4/8/04 - corrected audit entries.  Date truncated
	*					mh 10/29/2008 - 127008
   	*
   	**************************************************************/
   
   	declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
    
   	select @numrows = @@rowcount
   	if @numrows = 0 return
   
   	set nocount on
   
   	/* Audit inserts */
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRSH', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(d.HRRef,'')) +
       ' EffectiveDate: ' + convert(varchar(11),isnull(d.EffectiveDate,'')),
     	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
     	from deleted d join dbo.bHRCO e with (nolock)
   	on e.HRCo = d.HRCo
       where e.AuditSalaryHistYN = 'Y'
    
     Return
     error:
     select @errmsg = (@errmsg + ' - cannot delete HRSH! ')
     RAISERROR(@errmsg, 11, -1);
     rollback transaction
    
    
    
    
    
    
    
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   

    CREATE        trigger [dbo].[btHRSHi] on [dbo].[bHRSH] for INSERT as
     

/*-----------------------------------------------------------------
      *   	Created by: ae  3/31/00
      * 	Modified by: mh 9/5/02 - added updates to HREH
      *					mh 3/17/04 - 23061
      *					mh 4/8/04 - corrected audit entries.  Date truncated
      *					mh 7/12/04 25029 - Incorrect History Code type written to HREH
	  *					mh 1/11/08 - 119853 date updated to HREH to EffectiveDate
	  *					mh 10/29/2008 - 127008
      */----------------------------------------------------------------
     declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
     
    
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
    
    
   	declare @hrco bCompany, @hrref bHRRef, @seq int, @salhistyn bYN, @salhistcode varchar(10), 
   	@opencurs tinyint, @effdate bDate
   
   	declare insert_curs cursor local fast_forward for
   
   	select HRCo, HRRef, EffectiveDate from inserted 
   
   	open insert_curs
   
   	select @opencurs = 1
   
   	fetch next from insert_curs into @hrco, @hrref, @effdate
   
   	while @@fetch_status = 0
   	begin
   
   		select @salhistyn = SalaryHistYN, @salhistcode = SalaryHistCode
   		from dbo.bHRCO with (nolock) 
   		where HRCo = @hrco
   
   		if @salhistyn = 'Y' and @salhistcode is not null
   		begin
   			select @seq = isnull(max(Seq),0)+1
   			from dbo.bHREH with (nolock) 
   			where HRCo = @hrco and HRRef = @hrref
   
   			insert dbo.bHREH (HRCo, HRRef, Seq, Code, DateChanged, Type)
   			values (@hrco, @hrref, @seq, @salhistcode, @effdate, 'H')
   
   	  		update dbo.bHRSH 
   			set HistSeq = @seq 
   			where HRCo = @hrco and HRRef = @hrref and EffectiveDate = @effdate
   		end	
   
   		fetch next from insert_curs into @hrco, @hrref, @effdate
   	end
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   		select @opencurs = 0
   	end
   
   
   	/* Audit inserts */
    
	insert into bHQMA select 'bHRSH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
	' EffectiveDate: ' + convert(varchar(11),isnull(i.EffectiveDate,'')),
	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
	from inserted i join dbo.bHRCO e with (nolock) on e.HRCo = i.HRCo and e.AuditSalaryHistYN = 'Y'
   
   	return
    
   	error:
   
   	if @opencurs = 1
   	begin
   		close insert_curs
   		deallocate insert_curs
   	end
   
     	select @errmsg = @errmsg + ' - cannot insert into HRSH!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE          trigger [dbo].[btHRSHu] on [dbo].[bHRSH] for update as
     
      

/*--------------------------------------------------------------
       *
       *  Update trigger for HRSH
       *  Created By:  ae 03/29/00
       *  Modified by: mh 9/5/2002 - added updates to bHREH
       *					mh 03/17/03 - Issue 20486
       *					mh 3/17/04 - 23061
       *					mh 4/8/04 - corrected audit entries.  Date truncated.  Also
    						had arithmetic overflow on converting new and old salaries to 
    						varchar
   	   *					mh 4/29/2005 - 28581 - Change HRRef conversion from varchar(5) to varchar(6)
	   *					mh 10/29/2008 - 127008
       *
       *--------------------------------------------------------------*/
     
    	/***  basic declares for SQL Triggers ****/
    	declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
        @errno tinyint, @audit bYN, @validcnt int, @nullcnt int, @rcode int
     
    	select @numrows = @@rowcount
    	if @numrows = 0 return
    
    	set nocount on

    	 /*Insert HQMA records*/
		
		if update([Type])
    		insert into dbo.bHQMA select 'bHRSH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' EffectiveDate: ' + convert(varchar(11),isnull(i.EffectiveDate,'')),
			i.HRCo, 'C','Type',
			convert(varchar(1),d.Type), convert(varchar(1),i.Type),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d
    		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.EffectiveDate = d.EffectiveDate
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.Type,'') <> isnull(d.Type,'') and e.AuditSalaryHistYN = 'Y'

		if update(OldSalary)     
    		insert into dbo.bHQMA select 'bHRSH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' EffectiveDate: ' + convert(varchar(11),isnull(i.EffectiveDate,'')),
			i.HRCo, 'C','OldSalary',
			convert(varchar(20),d.OldSalary), convert(varchar(20),i.OldSalary),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d
    		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.EffectiveDate = d.EffectiveDate
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.OldSalary,0) <> isnull(d.OldSalary,0) and e.AuditSalaryHistYN = 'Y'

		if update(NewSalary)     
    		insert into dbo.bHQMA select 'bHRSH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' EffectiveDate: ' + convert(varchar(11),isnull(i.EffectiveDate,'')),
			i.HRCo, 'C','NewSalary',
			convert(varchar(20),d.NewSalary), convert(varchar(20),i.NewSalary),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d
    		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.EffectiveDate = d.EffectiveDate
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.NewSalary,0) <> isnull(d.NewSalary,0) and e.AuditSalaryHistYN = 'Y'

		if update(NewPositionCode)	     
    		insert into dbo.bHQMA select 'bHRSH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' EffectiveDate: ' + convert(varchar(11),isnull(i.EffectiveDate,'')),
			i.HRCo, 'C','NewPositionCode',
			convert(varchar(10),d.NewPositionCode), convert(varchar(10),i.NewPositionCode),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d
    		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.EffectiveDate = d.EffectiveDate
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.NewPositionCode,'') <> isnull(d.NewPositionCode,'') and e.AuditSalaryHistYN = 'Y'

		if update(EffectiveDate)     
    		insert into dbo.bHQMA select 'bHRSH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' EffectiveDate: ' + convert(varchar(11),isnull(i.EffectiveDate,'')),
			i.HRCo, 'C','NextDate',
			convert(varchar(20),d.NextDate), convert(varchar(20),i.NextDate),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d
    		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.EffectiveDate = d.EffectiveDate
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.NextDate,'') <> isnull(d.NextDate,'') and e.AuditSalaryHistYN = 'Y'

		if update(CalcYN)     
    		insert into dbo.bHQMA select 'bHRSH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
			' EffectiveDate: ' + convert(varchar(11),isnull(i.EffectiveDate,'')),
			i.HRCo, 'C','CalcYN',
			convert(varchar(1),d.CalcYN), convert(varchar(1),i.CalcYN),
     		getdate(), SUSER_SNAME()
     		from inserted i join deleted d
    		on i.HRCo = d.HRCo and i.HRRef = d.HRRef and i.EffectiveDate = d.EffectiveDate
    		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    		where isnull(i.CalcYN,'') <> isnull(d.CalcYN,'') and e.AuditSalaryHistYN = 'Y'
	    
     
     return
     
      error:

         select @errmsg = @errmsg + ' - cannot update HRSH'
         RAISERROR(@errmsg, 11, -1);
         rollback transaction
     
     
     
     
     
     
    
    
    
    
    
    
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRSH] ON [dbo].[bHRSH] ([HRCo], [HRRef], [EffectiveDate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRSH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRSH].[UpdatedYN]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bHRSH].[UpdatedYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRSH].[CalcYN]'
GO
