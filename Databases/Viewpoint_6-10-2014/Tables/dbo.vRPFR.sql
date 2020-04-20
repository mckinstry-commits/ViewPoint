CREATE TABLE [dbo].[vRPFR]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ReportID] [int] NOT NULL,
[OvrDocumentTitle] [varchar] (500) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPFRd] ON [dbo].[vRPFR] FOR Delete  AS
/************************************************************
 * Created: GG 10/31/06 
 * Modified: 
 *
 * Delete trigger on standard Form Reports (vRPFR)
 *
 * Rejects insert if the following conditions exist:
 *	Invalid login - must be 'viewpointcs'
 *
 * Adds HQ Audit entry 
 *
 *********************************************************/

declare	@numrows int, @errmsg varchar(255)
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- validate login
if suser_name() <> 'viewpointcs'
	begin
	select @errmsg = 'Current login does not have permission'
	goto error
	end 

-- remove custom form/reports 
delete dbo.vRPFRc
from deleted d
join dbo.vRPFRc c on c.Form = d.Form and c.ReportID = d.ReportID


/* Audit deletions */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPFR','Form: ' + Form + ' Report ID: ' + convert(varchar,ReportID),
  	null, 'D',NULL, NULL, NULL, getdate(),
   	case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
from deleted 
  
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete standard Form Reports.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
  
  
  
  
  
  
  
  
 
 
 













GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtRPFRi] on [dbo].[vRPFR] for INSERT as
/***************************************************
* Created: GG 10/31/06
* Modified: 
*
* Insert trigger on standard Form Reports  (vRPFR)
*
* Rejects insert if the following conditions exist:
*	Invalid login - must be 'viewpointcs'
*	Invalid Form - must be standard
*	Invalid Report - must be standard
*
* Adds HQ Audit entry
*
*********************************************************/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
  
select @numrows = @@rowcount 
if @numrows = 0 return

set nocount on 

-- validate login
if suser_name() <> 'viewpointcs'
	begin
	select @errmsg = 'Current login does not have permission'
	goto error
	end
-- validate Form - must be a standard form
select @validcnt = count(*)
from inserted i
join dbo.vDDFH f on f.Form = i.Form
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Form'
	goto error
	end
-- validate ReportID#/Parameter - must be a standard report
select @validcnt = count(*)
from inserted i
join dbo.vRPRT t on t.ReportID = i.ReportID 
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Report ID#'
	goto error
	end
 
/* Audit inserts */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vRPFR','Form: ' + Form + ' Report ID: ' + convert(varchar, ReportID),
 	 null, 'A', NULL, NULL, NULL, getdate(),
     case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
FROM inserted 
 
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert standard Form Report link.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 
 
 
 
 
 
 
 















GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtRPFRu] ON [dbo].[vRPFR] FOR Update AS
/***************************************************
* Created: GG 10/31/06
* Modified: 
*
* Update trigger on standard Forms Reports (vRPFR)
*
* Rejects insert if the following conditions exist:
*	Invalid login - must be 'viewpointcs'
*	Change primary key
*
* Since nothing can change, no auditing needed.
*
*********************************************************/
 
declare @numrows int, @errmsg varchar(255)
  
select @numrows = @@rowcount 
if @numrows = 0 return

set nocount on 

-- validate login
if suser_name() <> 'viewpointcs'
	begin
	select @errmsg = 'Current login does not have permission'
	goto error
	end 
-- check for update to primary key
if update(Form) or update(ReportID) 
	begin
	select @errmsg = 'Cannot update Form or ReportID#'
	goto error
	end

return
 
error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot update standard Form Reports'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
 
 
 
 
 
 
 
 
 
 
 
 
 
 














GO
CREATE UNIQUE CLUSTERED INDEX [viRPFR] ON [dbo].[vRPFR] ([Form], [ReportID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
