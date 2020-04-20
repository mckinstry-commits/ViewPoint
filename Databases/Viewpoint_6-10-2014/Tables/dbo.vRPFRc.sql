CREATE TABLE [dbo].[vRPFRc]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ReportID] [int] NOT NULL,
[Active] [dbo].[bYN] NOT NULL,
[OvrDocumentTitle] [varchar] (500) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtRPFRcd] ON [dbo].[vRPFRc] FOR Delete AS
/************************************************************
 * Created: GG 10/31/06 
 * Modified: 
 *
 * Delete trigger on custom Form Reports (vRPFRc)
 *
 * Adds HQ Audit entry 
 *
 *********************************************************/

DECLARE	@numrows int, @errmsg varchar(255)
  
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

/* Audit deletions */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPFRc','Form: ' + Form + ' Report ID: ' + convert(varchar,ReportID),
  	null, 'D',NULL, NULL, NULL, getdate(), suser_name()
from deleted 
  
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete custom Form Report.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
  
  
  
  
  
  
  
  
 
 
 













GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtRPFRci] on [dbo].[vRPFRc] for INSERT as
/***************************************************
* Created: GG 10/31/06
* Modified: 
*
* Insert trigger on custom Form Reports (vRPFRc)
*
* Rejects insert if the following conditions exist:
*	Invalid Form
*	Invalid Report ID
*
* Adds HQ Audit entry
*
*********************************************************/
declare @numrows int, @errmsg varchar(255), @validcnt int
  
select @numrows = @@rowcount 
if @numrows = 0 return

set nocount on 

-- validate Form - all forms
select @validcnt = count(*)
from inserted i
join dbo.DDFHShared f on f.Form = i.Form
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Form'
	goto error
	end  
-- validate ReportID# - all reports
select @validcnt = count(*)
from inserted i
join dbo.RPRTShared p on p.ReportID = i.ReportID 
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Report ID#'
	goto error
	end
  
/* Audit inserts */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vRPFRc','Form: ' + Form + ' Report ID: ' + convert(varchar, ReportID),
 	 null, 'A', NULL, NULL, NULL, getdate(), suser_name()
FROM inserted 
 
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert custom Form Report.'
    RAISERROR(@errmsg, 11, -1);
	rollback transaction
 
 
 
 
 
 
 
 
 













GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPFRcu] ON [dbo].[vRPFRc] FOR Update AS
/***************************************************
* Created: GG 10/31/06
* Modified: 
*
* Update trigger on custom Form Reports (vRPFRc)
*
* Rejects insert if the following conditions exist:
*	Change primary key
*
* Adds HQ Audit entry
*
*********************************************************/
 
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @validcnt2 int
  
select @numrows = @@rowcount 
if @numrows = 0 return

set nocount on 

-- check for update to primary key
if update(Form) or update(ReportID)
	begin
	select @errmsg = 'Cannot update Form or ReportID#'
	goto error
	end

/* Audit changed values */
if update(Active)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPFRc', 'Form: ' + i.Form + ' ReportID: ' + convert(varchar, i.ReportID), null, 'C',
 		'Active', d.Active, i.Active, getdate(), suser_name()
  	from inserted i
	join deleted d on i.Form = d.Form and i.ReportID = d.ReportID 
 	where i.Active <> d.Active

return
 
 
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update custom Form Report.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 
 
 
 
 
 
 
 
 
 
 
 
 











GO
ALTER TABLE [dbo].[vRPFRc] WITH NOCHECK ADD CONSTRAINT [CK_vRPFRc_Active] CHECK (([Active]='Y' OR [Active]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [viRPFRc] ON [dbo].[vRPFRc] ([Form], [ReportID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
