CREATE TABLE [dbo].[bPRCAEmployerItems]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[T4BoxNumber] [smallint] NOT NULL,
[T4BoxNumberSeq] [smallint] NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NULL,
[EDLCode] [dbo].[bEDLCode] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CHS
-- Create date: 09/30/2010	- #141451 Add auditing
-- Description:	Delete trigger for bPRCAEmployerItems
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployerItemsd] 
   ON  [dbo].[bPRCAEmployerItems] 
   for Delete
   
AS 

set nocount on

/* HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRCAEmployerItems', 
	'PRCo: ' + cast(d.PRCo as varchar(10)) + ',  Tax Year: ' + d.TaxYear + ',  Box #: ' + cast(d.T4BoxNumber as varchar(10)) + ',  Box Seq: ' + cast(d.T4BoxNumberSeq as varchar(10)), 
	d.PRCo, 
	'D', 
	null, 
	null, 
	null, 
	getdate(), 
	SUSER_SNAME() 
from deleted d
join dbo.bPRCO c (nolock) on d.PRCo = c.PRCo
where c.W2AuditYN = 'Y'

return


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btPRCAEmployerItemsi] on [dbo].[bPRCAEmployerItems] for INSERT as
/*-----------------------------------------------------------------
* Created:		CHS	09/30/2010	#141451
* Modified: 
*
*	Insert trigger for bPRCAEmployerItems table
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------

  
set nocount on
 
/* add HQ Master Audit entry */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 
	'bPRCAEmployerItems', 
	'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Box #: ' + cast(i.T4BoxNumber as varchar(10)) + ',  Box Seq: ' + cast(i.T4BoxNumberSeq as varchar(10)), 
	i.PRCo, 
	'A', 
	null, 
	null, 
	null, 
	getdate(), 
	SUSER_SNAME() 
from inserted i
join dbo.bPRCO c (nolock) on i.PRCo = c.PRCo
where c.W2AuditYN = 'Y'
  
return


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mark H
-- Create date: 09/17/2009
-- Modified		CHS	09/30/2010	- #141451 Add auditing
-- Description:	Update trigger for bPRCAEmployerItems to prevent key changes.
-- =============================================
CREATE TRIGGER [dbo].[btPRCAEmployerItemsu] 
   ON  [dbo].[bPRCAEmployerItems] 
   for Update
AS 
BEGIN

	declare @errmsg varchar(255), @numrows int
	select @numrows = @@rowcount

	set nocount on
	if @numrows = 0 return

	if update(PRCo) or update(TaxYear) or update(T4BoxNumber) or update(T4BoxNumberSeq) 
	begin
		select @errmsg = 'Cannot change primary key values'
		goto error
	end
		
/* add HQ Master Audit entry */
if update(EDLType)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployerItems', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Box #: ' + cast(i.T4BoxNumber as varchar(10)) + ',  Box Seq: ' + cast(i.T4BoxNumberSeq as varchar(10)), 
		i.PRCo, 
		'C', 
		'EDLType', 
		d.EDLType, 
		i.EDLType, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.EDLType, '') <> isnull(d.EDLType, '') and a.W2AuditYN = 'Y'
	end		
	
if update(EDLCode)
   	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 
		'bPRCAEmployerItems', 
		'PRCo: ' + cast(i.PRCo as varchar(10)) + ',  Tax Year: ' + i.TaxYear + ',  Box #: ' + cast(i.T4BoxNumber as varchar(10)) + ',  Box Seq: ' + cast(i.T4BoxNumberSeq as varchar(10)), 
 		i.PRCo, 
		'C', 
		'EDLCode', 
		d.EDLCode, 
		i.EDLCode, 
		getdate(), 
		SUSER_SNAME() 
    from inserted i
		join deleted d on i.PRCo = d.PRCo and i.TaxYear = d.TaxYear
		join dbo.bPRCO a (nolock) on i.PRCo = a.PRCo
    where isnull(i.EDLCode, -1) <> isnull(d.EDLCode, -1) and a.W2AuditYN = 'Y'
	end			
	
	

	return

error:

	select @errmsg = isnull(@errmsg,'') + ' - cannot update bPRCAEmployerItems.'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

END

GO
CREATE UNIQUE CLUSTERED INDEX [biPRCAEmployerItems] ON [dbo].[bPRCAEmployerItems] ([PRCo], [TaxYear], [T4BoxNumber], [T4BoxNumberSeq]) ON [PRIMARY]
GO
