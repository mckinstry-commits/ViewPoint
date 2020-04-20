CREATE TABLE [dbo].[bPRRN]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[SheetNum] [smallint] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[LineSeq] [smallint] NOT NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[StdPayRate] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRRN_StdPayRate] DEFAULT ('Y'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRRN] ON [dbo].[bPRRN] ([PRCo], [Crew], [PostDate], [SheetNum], [Employee], [LineSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRRN] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   

   CREATE    trigger [dbo].[btPRRNi] on [dbo].[bPRRN] for INSERT as
   

	/*-----------------------------------------------------------------
    *   	Created by: EN 2/21/03
    *		Modified:	EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
	*					mh 02/06/09 - issue 131950 reject inserts if bPRRH.Status > 0
    *
    * Validates PRCo, Crew, PostDate, and SheetNum against bPRRH.
    * Validates Craft, Class, and EarnCode.
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
   
   /* validate earnings code */
   select @validcnt = count(*) from dbo.bPREC e with (nolock)
    	join inserted i on e.PRCo = i.PRCo and e.EarnCode = i.EarnCode
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid earnings code'
    	goto error
    	end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Crew Timesheet Non-Job Earnings!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRRNu    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE    trigger [dbo].[btPRRNu] on [dbo].[bPRRN] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 2/21/03
    *	Modified:	EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *				EN 11/22/04 - issue 22571  relabel "Post Date" to "Timecard Date"
	*				mh 02/06/09 - issue 131950 reject updates if bPRRH.Status > 0
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
   
   /* validate earnings code */
   select @validcnt = count(*) from dbo.bPREC e with (nolock)
    	join inserted i on e.PRCo = i.PRCo and e.EarnCode = i.EarnCode
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid earnings code'
    	goto error
    	end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Crew Timesheet Employee Non-Job Earnings!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
   
   
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRRN].[StdPayRate]'
GO
