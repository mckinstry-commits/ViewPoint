CREATE TABLE [dbo].[bPRCACodes]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[T4CodeNumber] [smallint] NOT NULL,
[T4CodeDescription] [varchar] (255) COLLATE Latin1_General_BIN NULL,
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
-- Description:	Delete trigger for bPRCACodes
-- =============================================
CREATE TRIGGER [dbo].[btPRCACodesd] 
   ON  [dbo].[bPRCACodes] 
   for Delete
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if exists(select 1 from bPRCAEmployerCodes c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear and c.T4CodeNumber = d.T4CodeNumber)
	begin
		select @errmsg = 'T4 Code Number is used in bPRCAEmployerCodes.'
		goto error
	end

	if exists(select 1 from bPRCAEmployeeCodes c join deleted d on
	c.PRCo = d.PRCo and c.TaxYear = d.TaxYear and c.T4CodeNumber = d.T4CodeNumber)
	begin
		select @errmsg = 'T4 Code Number is used in bPRCAEmployeeCodes.'
		goto error
	end

	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot delete bPRCACodes.'
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
-- Description:	Update trigger for bPRCACodes to prevent key changes.
-- =============================================
CREATE TRIGGER [dbo].[btPRCACodesu] 
   ON  [dbo].[bPRCACodes] 
   for Update
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if update(PRCo) or update(TaxYear) or update(T4CodeNumber)
	begin
		select @errmsg = 'Cannot change primary key values'
		goto error
	end

	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot update bPRCACodes.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
CREATE CLUSTERED INDEX [biPRCACodes] ON [dbo].[bPRCACodes] ([PRCo], [TaxYear], [T4CodeNumber]) ON [PRIMARY]
GO
