CREATE TABLE [dbo].[bPRRE]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[SheetNum] [smallint] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[LineSeq] [smallint] NOT NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[Phase1RegHrs] [dbo].[bHrs] NULL,
[Phase1OTHrs] [dbo].[bHrs] NULL,
[Phase1DblHrs] [dbo].[bHrs] NULL,
[Phase2RegHrs] [dbo].[bHrs] NULL,
[Phase2OTHrs] [dbo].[bHrs] NULL,
[Phase2DblHrs] [dbo].[bHrs] NULL,
[Phase3RegHrs] [dbo].[bHrs] NULL,
[Phase3OTHrs] [dbo].[bHrs] NULL,
[Phase3DblHrs] [dbo].[bHrs] NULL,
[Phase4RegHrs] [dbo].[bHrs] NULL,
[Phase4OTHrs] [dbo].[bHrs] NULL,
[Phase4DblHrs] [dbo].[bHrs] NULL,
[Phase5RegHrs] [dbo].[bHrs] NULL,
[Phase5OTHrs] [dbo].[bHrs] NULL,
[Phase5DblHrs] [dbo].[bHrs] NULL,
[Phase6RegHrs] [dbo].[bHrs] NULL,
[Phase6OTHrs] [dbo].[bHrs] NULL,
[Phase6DblHrs] [dbo].[bHrs] NULL,
[Phase7RegHrs] [dbo].[bHrs] NULL,
[Phase7OTHrs] [dbo].[bHrs] NULL,
[Phase7DblHrs] [dbo].[bHrs] NULL,
[Phase8RegHrs] [dbo].[bHrs] NULL,
[Phase8OTHrs] [dbo].[bHrs] NULL,
[Phase8DblHrs] [dbo].[bHrs] NULL,
[RegRate] [dbo].[bUnitCost] NULL,
[OTRate] [dbo].[bUnitCost] NULL,
[DblRate] [dbo].[bUnitCost] NULL,
[TotalHrs] [dbo].[bHrs] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
	CREATE   trigger [dbo].[btPRREd] on [dbo].[bPRRE] for DELETE as
	/*--------------------------------------------------------------
    * Created: MH 07/04/07 
    *
    * Delete trigger on PRRE
    * If the employee deleted 
    *
    *--------------------------------------------------------------*/
	declare @errmsg varchar(255)
	  
	set nocount on

	/*Reject updates if Timesheet is locked, no need to check anything else if locked or
	status is greater then zero*/

	Update bPRRQ set Employee = null
	from bPRRQ q join deleted d on d.PRCo = q.PRCo and d.Crew = q.Crew and d.PostDate = q.PostDate and
	d.SheetNum = q.SheetNum and d.Employee = q.Employee

	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Crew Timesheet Employees (bPRRE)'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRREi    Script Date: 8/28/99 9:38:10 AM ******/
    CREATE     trigger [dbo].[btPRREi] on [dbo].[bPRRE] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: EN 2/21/03
     *		Modified:	EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
	 *					mh 02/06/09	- Issue 131950 Reject inserts if bPRRH.Status > 0
     *
     * Validates PRCo, Crew, PostDate, and SheetNum against bPRRH.
     * Validates Craft and Class.
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on

	/*Reject updates if Timesheet is locked, no need to check anything else if locked or
	status is greater then zero*/

	if exists(select 1 from bPRRH h join inserted i on h.PRCo = i.PRCo and h.Crew = i.Crew and
	h.PostDate = i.PostDate and h.SheetNum = i.SheetNum and h.Status > 0)
	begin
		select @errmsg = 'Timesheet has been locked and cannot be edited.'
		goto error
	end
  
    /* validate PR Company, Crew, PostDate, and Sheet number against bPRRH */
    select @validcnt = count(*) from dbo.bPRRH c with (nolock)
    join inserted i on c.PRCo=i.PRCo and c.Crew=i.Crew and c.PostDate=i.PostDate and c.SheetNum=i.SheetNum
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Timesheet'
    	goto error
    	end
    
    /* validate craft code */
    select @validcnt = count(*) from inserted where Craft is not null
    select @validcnt2 = count(*) from dbo.bPRCM c with (nolock)
     	join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft
     	where i.Craft is not null
    if @validcnt2 <> @validcnt
     	begin
     	select @errmsg = 'Invalid craft code'
     	goto error
     	end
    
    /* validate class code */
    select @validcnt = count(*) from inserted where Craft is not null and Class is null
    if @validcnt <> 0
     	begin
     	select @errmsg = 'Missing class code'
     	goto error
     	end
    select @validcnt = count(*) from inserted where Craft is not null and Class is not null
    select @validcnt2 = count(*) from dbo.bPRCC c with (nolock)
     	join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft and c.Class = i.Class
     	where i.Craft is not null and i.Class is not null
    if @validcnt2 <> @validcnt
     	begin
     	select @errmsg = 'Invalid class code'
     	goto error
     	end
    
    
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Crew Timesheet Employee Hours!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
    
    
    
    
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE    trigger [dbo].[btPRREu] on [dbo].[bPRRE] for UPDATE as
   

	/*-----------------------------------------------------------------
    *  Created: EN 2/21/03
    *  Modified:	EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *				EN 11/22/04 - issue 22571  relabel "Posting Date" to "Timecard Date"
	*				mh 02/06/09	- issue 131950 Reject updates if bPRRH.Status > 0
    *
    * Cannot change primary key.
    * Validate VendorGroup and Vendor.
    * Inserts HQ Master Audit entry.
    */----------------------------------------------------------------

   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
	/*Reject updates if Timesheet is locked, no need to check anything else if locked or
	status is greater then zero*/
	if exists(select 1 from bPRRH h join inserted i on h.PRCo = i.PRCo and h.Crew = i.Crew and
	h.PostDate = i.PostDate and h.SheetNum = i.SheetNum and h.Status > 0)
	begin
		select @errmsg = 'Timesheet has been locked and cannot be edited.'
		goto error
	end

   /* check for key changes */
   if update(PRCo)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change PR Company '
        	goto error
        	end
       end
   if update(Crew)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Crew '
        	goto error
        	end
       end
   if update(PostDate)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Timecard Date '
        	goto error
        	end
       end
   if update(SheetNum)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate and d.SheetNum = i.SheetNum
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Sheet # '
        	goto error
        	end
       end
   if update(Employee)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate and d.SheetNum = i.SheetNum
   			and d.Employee = i.Employee
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Employee '
        	goto error
        	end
       end
   if update(LineSeq)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew and d.PostDate = i.PostDate and d.SheetNum = i.SheetNum
   			and d.Employee = i.Employee and d.LineSeq = i.LineSeq
       if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Line Sequence '
        	goto error
        	end
       end
   
   /* validate craft code */
   select @validcnt = count(*) from inserted where Craft is not null
   select @validcnt2 = count(*) from dbo.bPRCM c with (nolock)
    	join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft
    	where i.Craft is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid craft code'
    	goto error
    	end
   
   /* validate class code */
   select @validcnt = count(*) from inserted where Craft is not null
   select @validcnt2 = count(*) from inserted where Craft is not null and Class is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Missing class code'
    	goto error
    	end
   select @validcnt = count(*) from inserted where Craft is not null and Class is not null
   select @validcnt2 = count(*) from dbo.bPRCC c with (nolock)
    	join inserted i on c.PRCo = i.PRCo and c.Craft = i.Craft and c.Class = i.Class
    	where i.Craft is not null and i.Class is not null
   if @validcnt2 <> @validcnt
    	begin
    	select @errmsg = 'Invalid class code'
    	goto error
    	end

--Test Auditing Code

--	if update(Craft)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Craft',
--		convert(varchar(10),d.Craft), Convert(varchar(10),i.Craft),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Craft,'') <> isnull(d.Craft,'') 
--
--	if update(Class)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Class',
--		convert(varchar(10),d.Class), Convert(varchar(10),i.Class),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Class,'') <> isnull(d.Class,'') 
--
--	if update(Phase1RegHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase1RegHrs',
--		convert(varchar(10),d.Phase1RegHrs), Convert(varchar(10),i.Phase1RegHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase1RegHrs,0) <> isnull(d.Phase1RegHrs,0) 
--
--	if update(Phase1OTHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase1OTHrs',
--		convert(varchar(10),d.Phase1OTHrs), Convert(varchar(10),i.Phase1OTHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase1OTHrs,0) <> isnull(d.Phase1OTHrs,0) 
--
--	if update(Phase1DblHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase1DblHrs',
--		convert(varchar(10),d.Phase1DblHrs), Convert(varchar(10),i.Phase1DblHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase1DblHrs,0) <> isnull(d.Phase1DblHrs,0) 
--
--	if update(Phase2RegHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase2RegHrs',
--		convert(varchar(10),d.Phase2RegHrs), Convert(varchar(10),i.Phase2RegHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase2RegHrs,0) <> isnull(d.Phase2RegHrs,0) 
--
--	if update(Phase2OTHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase2OTHrs',
--		convert(varchar(10),d.Phase2OTHrs), Convert(varchar(10),i.Phase2OTHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase2OTHrs,0) <> isnull(d.Phase2OTHrs,0) 
--
--	if update(Phase2DblHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase2DblHrs',
--		convert(varchar(10),d.Phase2DblHrs), Convert(varchar(10),i.Phase2DblHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase2DblHrs,0) <> isnull(d.Phase2DblHrs,0) 
--
--
--	if update(Phase3RegHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase3RegHrs',
--		convert(varchar(10),d.Phase3RegHrs), Convert(varchar(10),i.Phase3RegHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase3RegHrs,0) <> isnull(d.Phase3RegHrs,0) 
--
--	if update(Phase3OTHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase3OTHrs',
--		convert(varchar(10),d.Phase3OTHrs), Convert(varchar(10),i.Phase3OTHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase3OTHrs,0) <> isnull(d.Phase3OTHrs,0) 
--
--	if update(Phase3DblHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase3DblHrs',
--		convert(varchar(10),d.Phase3DblHrs), Convert(varchar(10),i.Phase3DblHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase3DblHrs,0) <> isnull(d.Phase3DblHrs,0) 
--
--
--	if update(Phase4RegHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase4RegHrs',
--		convert(varchar(10),d.Phase4RegHrs), Convert(varchar(10),i.Phase4RegHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase4RegHrs,0) <> isnull(d.Phase4RegHrs,0) 
--
--	if update(Phase4OTHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase4OTHrs',
--		convert(varchar(10),d.Phase4OTHrs), Convert(varchar(10),i.Phase4OTHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase4OTHrs,0) <> isnull(d.Phase4OTHrs,0) 
--
--	if update(Phase4DblHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase4DblHrs',
--		convert(varchar(10),d.Phase4DblHrs), Convert(varchar(10),i.Phase4DblHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase4DblHrs,0) <> isnull(d.Phase4DblHrs,0) 
--
--
--	if update(Phase5RegHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase5RegHrs',
--		convert(varchar(10),d.Phase5RegHrs), Convert(varchar(10),i.Phase5RegHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase5RegHrs,0) <> isnull(d.Phase5RegHrs,0) 
--
--	if update(Phase5OTHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase5OTHrs',
--		convert(varchar(10),d.Phase5OTHrs), Convert(varchar(10),i.Phase5OTHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase5OTHrs,0) <> isnull(d.Phase5OTHrs,0) 
--
--	if update(Phase5DblHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase5DblHrs',
--		convert(varchar(10),d.Phase5DblHrs), Convert(varchar(10),i.Phase5DblHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase5DblHrs,0) <> isnull(d.Phase5DblHrs,0) 
--
--
--	if update(Phase6RegHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase6RegHrs',
--		convert(varchar(10),d.Phase6RegHrs), Convert(varchar(10),i.Phase6RegHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase6RegHrs,0) <> isnull(d.Phase6RegHrs,0) 
--
--	if update(Phase6OTHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase6OTHrs',
--		convert(varchar(10),d.Phase6OTHrs), Convert(varchar(10),i.Phase6OTHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase6OTHrs,0) <> isnull(d.Phase6OTHrs,0) 
--
--	if update(Phase6DblHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase6DblHrs',
--		convert(varchar(10),d.Phase6DblHrs), Convert(varchar(10),i.Phase6DblHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase6DblHrs,0) <> isnull(d.Phase6DblHrs,0) 
--
--
--	if update(Phase7RegHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase7RegHrs',
--		convert(varchar(10),d.Phase7RegHrs), Convert(varchar(10),i.Phase7RegHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase7RegHrs,0) <> isnull(d.Phase7RegHrs,0) 
--
--	if update(Phase7OTHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase7OTHrs',
--		convert(varchar(10),d.Phase7OTHrs), Convert(varchar(10),i.Phase7OTHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase7OTHrs,0) <> isnull(d.Phase7OTHrs,0) 
--
--	if update(Phase7DblHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase7DblHrs',
--		convert(varchar(10),d.Phase7DblHrs), Convert(varchar(10),i.Phase7DblHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase7DblHrs,0) <> isnull(d.Phase7DblHrs,0) 
--
--
--	if update(Phase8RegHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase8RegHrs',
--		convert(varchar(10),d.Phase8RegHrs), Convert(varchar(10),i.Phase8RegHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase8RegHrs,0) <> isnull(d.Phase8RegHrs,0) 
--
--	if update(Phase8OTHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase8OTHrs',
--		convert(varchar(10),d.Phase8OTHrs), Convert(varchar(10),i.Phase8OTHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase8OTHrs,0) <> isnull(d.Phase8OTHrs,0) 
--
--	if update(Phase8DblHrs)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','Phase8DblHrs',
--		convert(varchar(10),d.Phase8DblHrs), Convert(varchar(10),i.Phase8DblHrs),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.Phase8DblHrs,0) <> isnull(d.Phase8DblHrs,0) 
--
--
--	if update(RegRate)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','RegRate',
--		convert(varchar(10),d.RegRate), Convert(varchar(10),i.RegRate),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.RegRate,0) <> isnull(d.RegRate,0) 
--
--	if update(OTRate)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','OTRate',
--		convert(varchar(10),d.OTRate), Convert(varchar(10),i.OTRate),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.OTRate,0) <> isnull(d.OTRate,0) 
--
--
--	if update(DblRate)
--		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)    
--		select 'bPRRE', 'PRCo: ' + convert(char(3),isnull(i.PRCo,'')) + 
--		' Crew: ' + convert(varchar,isnull(i.Crew,'')) +
--		' PostDate: ' + convert(varchar,isnull(i.PostDate,'')) +  
--		' SheetNum: ' + convert(varchar,isnull(i.SheetNum,'')) +
--		' Employee: ' + convert(varchar, isnull(i.Employee,'')) + 
--		' LineSeq: ' + convert(varchar, isnull(i.LineSeq,'')),
--		i.PRCo, 'C','DblRate',
--		convert(varchar(10),d.DblRate), Convert(varchar(10),i.DblRate),
--		getdate(), SUSER_SNAME()
--		from inserted i join deleted d on 
--		i.PRCo = d.PRCo and i.Crew = d.Crew and i.PostDate = d.PostDate and 
--		i.SheetNum = d.SheetNum and i.Employee = d.Employee and i.LineSeq = d.LineSeq
--		where isnull(i.DblRate,0) <> isnull(d.DblRate,0) 


--End Auditing Code   

   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Crew Timesheet Employee Hours!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biPRRE] ON [dbo].[bPRRE] ([PRCo], [Crew], [PostDate], [SheetNum], [Employee], [LineSeq]) ON [PRIMARY]
GO
