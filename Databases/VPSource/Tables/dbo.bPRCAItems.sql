CREATE TABLE [dbo].[bPRCAItems]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[T4BoxNumber] [smallint] NOT NULL,
[T4BoxDescription] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[AmtType] [char] (1) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 09/17/2009
-- Description:	Delete trigger for bPRCAItems
-- =============================================
CREATE TRIGGER [dbo].[btPRCAItemsd] 
   ON  [dbo].[bPRCAItems] 
   for Delete
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if exists(select 1 from bPRCAEmployerItems c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear and c.T4BoxNumber = d.T4BoxNumber)
	begin
		select @errmsg = 'T4 Box Number is used in bPRCAEmployerItems.'
		goto error
	end

	if exists(select 1 from bPRCAEmployeeItems c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear and c.T4BoxNumber = d.T4BoxNumber)
	begin
		select @errmsg = 'T4 Box Number is used in bPRCAEmployeeItems.'
		goto error
	end

	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot delete bPRCAItems.'
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
-- Create date: 09/17/2009
-- Description:	Update trigger for bPRCAItems to prevent key changes.
-- =============================================
CREATE TRIGGER [dbo].[btPRCAItemsu] 
   ON  [dbo].[bPRCAItems] 
   for Update
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if update(PRCo) or update(TaxYear) or update(T4BoxNumber) 
	begin
		select @errmsg = 'Cannot change primary key values'
		goto error
	end

	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot update bPRCAItems.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
CREATE UNIQUE CLUSTERED INDEX [biPRCAItems] ON [dbo].[bPRCAItems] ([PRCo], [TaxYear], [T4BoxNumber]) ON [PRIMARY]
GO
