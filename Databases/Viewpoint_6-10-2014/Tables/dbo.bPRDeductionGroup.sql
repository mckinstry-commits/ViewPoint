CREATE TABLE [dbo].[bPRDeductionGroup]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[DednGroup] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[AnnualLimit] [dbo].[bDollar] NOT NULL CONSTRAINT [DF__bPRDeduct__Annua__4818A9D5] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


 
CREATE trigger [dbo].[btPRDeductionGroupd] on [dbo].[bPRDeductionGroup] for DELETE as
/*-----------------------------------------------------------------
* Created: MCP 10/18/2010
* Modified: 
*
* Checks to see if entries exist in other tables
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

/* check for reference in PR Deductions and LIabilities */
if exists(select 1 from dbo.bPRDL a (nolock) join deleted d on a.PRCo = d.PRCo and a.PreTaxGroup = d.DednGroup)
	begin
	select @errmsg = 'Entries exist in PR Deductions and Liabilities for this Deduction Group'
	goto error
	end

return

error:
	select @errmsg = @errmsg + ' - cannot delete PR Deduction Group!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 





GO
ALTER TABLE [dbo].[bPRDeductionGroup] ADD CONSTRAINT [PK_bPRDeductionGroup_PRCo_DednGroup] PRIMARY KEY CLUSTERED  ([PRCo], [DednGroup]) ON [PRIMARY]
GO
