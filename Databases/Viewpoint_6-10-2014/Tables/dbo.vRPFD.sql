CREATE TABLE [dbo].[vRPFD]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ReportID] [int] NOT NULL,
[ParameterName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ParameterDefault] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[UsedForPublish] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vRPFD_UsedForPublish] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPFDd] ON [dbo].[vRPFD] FOR Delete  AS
/************************************************************
 * Created: GG 10/26/06 
 * Modified: 
 *
 * Delete trigger on standard Report Parameter Defaults (vRPFD)
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

-- remove custom form/report parameter defaults 
delete dbo.vRPFDc
from deleted d
join dbo.vRPFDc c on c.Form = d.Form and c.ReportID = d.ReportID and c.ParameterName = d.ParameterName


/* Audit deletions */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPFD','Form: ' + Form + ' Report ID: ' + convert(varchar,ReportID) + ' ParameterName: ' + ParameterName,
  	null, 'D',NULL, NULL, NULL, getdate(),
   	case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
from deleted 
  
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete standard Report Parameter Default.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
  
  
  
  
  
  
  
  
 
 
 













GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[vtRPFDi] on [dbo].[vRPFD] for INSERT as
/***************************************************
* Created: GG 10/30/06
* Modified: 
*
* Insert trigger on standard Report Parameter Defaults (vRPFD)
*
* Rejects insert if the following conditions exist:
*	Invalid login - must be 'viewpointcs'
*	Invalid Form - must be standard
*	Invalid Report/ParameterName - must be standard
*	Invalid ParameterDefault
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
join dbo.vRPRP p on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Report ID#/Parameter Name'
	goto error
	end

-- validate Parameter Default
/*select @validcnt = count(*) 
from inserted
where substring(ParameterDefault,1,1) = '%' and (substring(ParameterDefault,1,2) in ('%C','%D','%M') or substring(ParameterDefault,1,3) = '%RP'
	or substring(ParameterDefault,1,3) = '%FI')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Parameter Default'
	goto error
	end
*/

/* Audit inserts */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vRPFD','Form: ' + Form + ' Report ID: ' + convert(varchar, ReportID) + ' ParameterName: ' + ParameterName,
 	 null, 'A', NULL, NULL, NULL, getdate(),
     case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
FROM inserted 
 
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert standard Report Parameter Default.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPFDu] ON [dbo].[vRPFD] FOR Update AS
/***************************************************
* Created: GG 10/26/06
* Modified: 
*
* Update trigger on standard Report Parameter Defaults (vRPFD)
*
* Rejects insert if the following conditions exist:
*	Invalid login - must be 'viewpointcs'
*	Change primary key
*	Invalid ParameterDefault
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
-- check for update to primary key
if update(Form) or update(ReportID) or update(ParameterName)
	begin
	select @errmsg = 'Cannot update Form, ReportID# or Parameter Name'
	goto error
	end

-- validate Parameter Default
--relpaced by stored procedure vspRPVPParameterDefaults
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
 
/* Audit updates */
if update(ParameterDefault)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'Form: ' + i.Form + ' ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'ParameterDefault', d.ParameterDefault, i.ParameterDefault, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	and i.ParameterDefault <> d.ParameterDefault

return
 
 
error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot update standard Report Parameter Default'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [viRPFD] ON [dbo].[vRPFD] ([Form], [ReportID], [ParameterName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
