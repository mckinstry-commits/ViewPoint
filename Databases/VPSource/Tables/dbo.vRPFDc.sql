CREATE TABLE [dbo].[vRPFDc]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ReportID] [int] NOT NULL,
[ParameterName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ParameterDefault] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[UsedForPublish] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vRPFDc_UsedForPublish] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtRPFDcd] ON [dbo].[vRPFDc] FOR Delete AS
/************************************************************
 * Created: GG 10/30/06 
 * Modified: 
 *
 * Delete trigger on custom Report Parameter Defaults (vRPFDc)
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
select 'vRPFDc','Form: ' + Form + ' Report ID: ' + convert(varchar,ReportID) + ' ParameterName: ' + ParameterName,
  	null, 'D',NULL, NULL, NULL, getdate(), suser_name()
from deleted 
  
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete custom Report Parameter Default.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
  
  
  
  
  
  
  
  
 
 
 












GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtRPFDci] on [dbo].[vRPFDc] for INSERT as
/***************************************************
* Created: GG 10/30/06
* Modified: 
*
* Insert trigger on custom Report Parameter Defaults (vRPFDc)
*
* Rejects insert if the following conditions exist:
*	Invalid Form
*	Invalid Report ID/ParameterName
*	Invalid ParameterDefault
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
-- validate ReportID#/Parameter - all reports
select @validcnt = count(*)
from inserted i
join dbo.RPRPShared p on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Report ID#/Parameter Name'
	goto error
	end

-- validate Parameter Default
--relpaced by stored procedure vspRPVPParameterDefaults
/*
select @validcnt = count(*)
from inserted
where substring(ParameterDefault,1,2) in ('%C','%D','%M') or substring(ParameterDefault,1,3) = '%RP'
	or substring(ParameterDefault,1,3) = '%FI'
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Parameter Default'
	goto error
	end
  */

/* Audit inserts */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vRPFDc','Form: ' + Form + ' Report ID: ' + convert(varchar, ReportID) + ' ParameterName: ' + ParameterName,
 	 null, 'A', NULL, NULL, NULL, getdate(), suser_name()
FROM inserted 
 
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert custom Report Parameter Default.'
    RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPFDcu] ON [dbo].[vRPFDc] FOR Update AS
/***************************************************
* Created: GG 10/30/06
* Modified: 
*
* Update trigger on custom Report Parameter Defaults (vRPFDc)
*
* Rejects insert if the following conditions exist:
*	Change primary key
*	Invalid ParameterDefault
*
* Adds HQ Audit entry
*
*********************************************************/
 
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @validcnt2 int
  
select @numrows = @@rowcount 
if @numrows = 0 return

set nocount on 

-- check for update to primary key
if update(Form) or update(ReportID) or update(ParameterName)
	begin
	select @errmsg = 'Cannot update Form, ReportID# or Parameter Name'
	goto error
	end
-- validate Parameter Default
/*if update(ParameterDefault)
	begin
	select @validcnt = count(*)
	from inserted
	where substring(ParameterDefault,1,2) in ('%C','%D','%M') or substring(ParameterDefault,1,3) = '%RP'
		or substring(ParameterDefault,1,3) = '%FI'
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid Parameter Default'
		goto error
		end
	end
*/

/* Audit changed values */
if update(ParameterDefault)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPFDc', 'Form: ' + i.Form + ' ReportID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'ParameterDefault', d.ParameterDefault, i.ParameterDefault, getdate(), suser_name()
  	from inserted i
	join deleted d on i.Form = d.Form and i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where i.ParameterDefault <> d.ParameterDefault

return
 
 
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update custom Report Parameter Default.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [viRPFDc] ON [dbo].[vRPFDc] ([Form], [ReportID], [ParameterName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
