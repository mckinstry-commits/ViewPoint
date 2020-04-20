CREATE TABLE [dbo].[bPRMyTimesheet]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[EntryEmployee] [dbo].[bEmployee] NOT NULL,
[StartDate] [dbo].[bDate] NOT NULL,
[Sheet] [smallint] NOT NULL,
[Status] [tinyint] NOT NULL,
[CreatedOn] [smalldatetime] NOT NULL,
[CreatedBy] [dbo].[bVPUserName] NOT NULL,
[PRBatchMth] [dbo].[bDate] NULL,
[PRBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PersonalTimesheet] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRMyTimesheet_PersonalTimesheet] DEFAULT ('N'),
[ErrorMessage] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 07/23/2009
-- Description:	
-- =============================================

CREATE TRIGGER [dbo].[btPRMyTimesheetd] 
   ON  [dbo].[bPRMyTimesheet] for DELETE as  
BEGIN

	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int

	select @numrows = @@rowcount
	if @numrows = 0 return

	SET NOCOUNT ON

	if exists(select 1 from bPRMyTimesheetDetail p join deleted d on p.PRCo = d.PRCo and 
	p.EntryEmployee = d.EntryEmployee and p.StartDate = d.StartDate and p.Sheet = d.Sheet)
	begin
		select @errmsg = 'Timesheet Detail entries exist for this Sheet'
	end

-- Auditing?


   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR My Timesheet!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 07/23/2009
-- Description:	
-- =============================================

CREATE TRIGGER [dbo].[btPRMyTimesheetu] 
   ON  [dbo].[bPRMyTimesheet] for UPDATE as  
BEGIN

	declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int

	select @numrows = @@rowcount
	if @numrows = 0 return

	SET NOCOUNT ON

	/* check for key changes */
	if update(PRCo)
	begin
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change PR Company'
			goto error
		end
	end

	if update(EntryEmployee)
	begin	
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo and i.EntryEmployee = d.EntryEmployee
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change Employee'
			goto error
		end
	end

	if update(StartDate)
	begin	
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo and i.StartDate = d.StartDate
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change Start Date'
			goto error
		end
	end

	if update(Sheet)
	begin	
		select @validcnt = count(1) from deleted d
		join inserted i on d.PRCo = i.PRCo and i.Sheet = d.Sheet
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Cannot change Sheet Number'
			goto error
		end
	end
	
	/* Remove the SMMyTimesheetLink records for any PRMyTimesheetDetail records if the PRMyTimesheet header
		records are being marked as sent.
	*/
	DELETE FROM vSMMyTimesheetLink FROM vSMMyTimesheetLink
		INNER JOIN INSERTED ON INSERTED.PRCo=vSMMyTimesheetLink.PRCo
			AND INSERTED.EntryEmployee=vSMMyTimesheetLink.EntryEmployee
			AND INSERTED.StartDate=vSMMyTimesheetLink.StartDate
			AND INSERTED.Sheet=vSMMyTimesheetLink.Sheet
		WHERE INSERTED.Status=4
	
-- Auditing?


   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR My Timesheet!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

END

GO
ALTER TABLE [dbo].[bPRMyTimesheet] ADD CONSTRAINT [biPRMyTimesheet] PRIMARY KEY CLUSTERED  ([PRCo], [EntryEmployee], [StartDate], [Sheet]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPRMyTimesheet] ON [dbo].[bPRMyTimesheet] ([PRCo]) ON [PRIMARY]
GO
