CREATE TABLE [dbo].[vRPRP]
(
[ReportID] [int] NOT NULL,
[ParameterName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[DisplaySeq] [tinyint] NOT NULL,
[ReportDatatype] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ActiveLookup] [dbo].[bYN] NULL,
[LookupParams] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[LookupSeq] [tinyint] NULL,
[Description] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[ParameterDefault] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[InputType] [tinyint] NULL,
[InputMask] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputLength] [smallint] NULL,
[Prec] [tinyint] NULL,
[PortalParameterDefault] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PortalAccess] [int] NOT NULL CONSTRAINT [DF_vRPRP_PortalAccess] DEFAULT ((1)),
[ParamRequired] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vRPRP] ADD
CONSTRAINT [CK_vRPRP_ActiveLookup] CHECK (([ActiveLookup]='Y' OR [ActiveLookup]='N' OR [ActiveLookup] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPRPd] ON [dbo].[vRPRP] FOR Delete  AS
/************************************************************
 * Created: TL 6/13/05
 * Modified: GG 10/26/06 
 *
 * Delete trigger on standard Report Parameters (vRPRP)
 *
 * Performs cascade delete on all tables referencing deleted parameters
 *
 * Adds HQ Audit entry 
 *
 *********************************************************/

DECLARE	@numrows int, @errmsg varchar(255)
  
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
join dbo.vRPFDc c on c.ReportID = d.ReportID and c.ParameterName = d.ParameterName
-- remove standard form/report parameter defaults
delete dbo.vRPFD
from deleted d
join dbo.vRPFD c on c.ReportID = d.ReportID and c.ParameterName = d.ParameterName

-- remove custom parameter lookups
delete dbo.vRPPLc
from deleted d
join dbo.vRPPLc c on c.ReportID = d.ReportID and c.ParameterName = d.ParameterName
-- remove standard parameter lookups
delete dbo.vRPPL
from deleted d
join dbo.vRPPL c on c.ReportID = d.ReportID and c.ParameterName = d.ParameterName

-- remove parameter overrides
delete dbo.vRPRPc
from deleted d
join dbo.vRPRPc c on c.ReportID = d.ReportID and c.ParameterName = d.ParameterName


/* Audit deletions */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPRP','Report ID: ' + convert(varchar,ReportID) + ' ParameterName: ' + ParameterName,
  	null, 'D',NULL, NULL, NULL, getdate(),
   	case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
from deleted 
  
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete standard Report Parameter.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
  
  
  
  
  
  
  
  
 
 
 












GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[vtRPRPi] on [dbo].[vRPRP] for INSERT as
/***************************************************
* Created: TL 06/13/05
* Modified: GG 10/26/06
*			GG 06/20/07 - #123500 - added Parameter Defaults for Active Info
*			CJG 2/1/2010 - #131919 - Changed Parameter Name validation to ignore for SSRS reports
*
* Insert trigger on standard Report Parameters (vRPRP)
*
* Rejects insert if the following conditions exist:
*	Invalid Report ID - must be standard
*	Invalid ParameterName
*	Invalid ReportDatatype
*	Invalid Datatype
*	Invalid ParameterDefault
*	Invalid InputType
*
* Adds HQ Audit entry
*
*********************************************************/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @appType varchar(30)
  
select @numrows = @@rowcount 
if @numrows = 0 return

set nocount on 

-- validate login
if suser_name() <> 'viewpointcs'
	begin
	select @errmsg = 'Current login does not have permission'
	goto error
	end 
-- validate ReportID# - must be a standard report
select @validcnt = count(*)
from inserted i
join dbo.vRPRT t on t.ReportID = i.ReportID
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Report ID#'
	goto error
	end
-- validate Parameter Name
select @appType = AppType
from inserted i
join dbo.vRPRT t on t.ReportID = i.ReportID
-- Only Crystal reports require ? or @
if @appType='Crystal' and exists(select top 1 1 from inserted where SUBSTRING(ParameterName,1,1) not in ('?','@'))
     begin
     select @errmsg = 'Parameter Name must begin with @ or ?'
     goto error
     end
-- validate Report Datatype
if exists(select top 1 1 from inserted where ReportDatatype not in ('S','N','D','M'))
     begin
     select @errmsg = 'Report Datatype must be ''S'', ''N'', ''D'' or "M"'
     goto error
     end
-- validate Datatype
select @nullcnt = count(*) from inserted where Datatype is null
select @validcnt = count(*)
from inserted i
join dbo.DDDTShared d (nolock) on d.Datatype = i.Datatype
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Datatype'
	goto error
	end
-- validate Parameter Default
if exists(select top 1 1 from inserted where substring(ParameterDefault,1,1) = '%'
			and (substring(ParameterDefault,2,1) not in ('C','D','M') and substring(ParameterDefault,2,2) <> 'RP')
	and upper(ParameterDefault) not in ('%PROJECT','%JOB','%CONTRACT','%PRGROUP','%PRENDDATE','%JBPROGMTH','%JBPROGBILL','%JBTMMTH','%JBTMBILL','%RAC','%C'))
	begin
	select @errmsg = 'Invalid Parameter Default'
	goto error
	end

-- validate Input Type
select @nullcnt = count(*) from inserted where Datatype is not null and InputType is null
select @validcnt = count(*) from inserted where Datatype is null and InputType in (0,1,2,3,4,5,6)
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Input Type' 
	goto error
	end

 
/* Audit inserts */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vRPRP','Report ID: ' + convert(varchar, ReportID) + ' ParameterName: ' + ParameterName,
 	 null, 'A', NULL, NULL, NULL, getdate(),
     case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
FROM inserted
 
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert standard Report Parameter.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPRPu] ON [dbo].[vRPRP] FOR Update AS
/***************************************************
* Created: TL 06/13/05
* Modified: GG 10/26/06
*			GG 06/20/07 - #123500 - added Parameter Defaults for Active Info
*
* Update trigger on standard Report Parameters (vRPRP)
*
* Rejects insert if the following conditions exist:
*	Change primary key
*	Invalid ParameterName
*	Invalid ReportDatatype
*	Invalid Datatype
*	Invalid ParameterDefault
*	Invalid InputType
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
if update(ReportID) or update(ParameterName)
	begin
	select @errmsg = 'Cannot update ReportID# or Parameter Name'
	goto error
	end
-- validate Report Datatype
if update(ReportDatatype)
	begin
	if exists(select top 1 1 from inserted where ReportDatatype not in ('S','N','D','M'))
		begin
		select @errmsg = 'Report Datatype must be ''S'', ''N'', ''D'' or "M"'
		goto error
		end
	end
-- validate Datatype
if update(Datatype)
	begin
	select @nullcnt = count(*) from inserted where Datatype is null
	select @validcnt = count(*)
	from inserted i
	join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Datatype'
		goto error
		end
	end

-- validate Parameter Default
if update(ParameterDefault)
	begin
	if exists(select top 1 1 from inserted where substring(ParameterDefault,1,1) = '%'
			and (substring(ParameterDefault,2,1) not in ('C','D','M') and substring(ParameterDefault,2,2) <> 'RP') 
			and upper(ParameterDefault) not in ('%PROJECT','%JOB','%CONTRACT','%PRGROUP','%PRENDDATE','%JBPROGMTH','%JBPROGBILL','%JBTMMTH','%JBTMBILL','%RAC'))	
		begin
		select @errmsg = 'Invalid Parameter Default'
		goto error
		end
	end

-- validate Input Type
if update(InputType)
	begin
	select @nullcnt = count(*) from inserted where Datatype is not null and InputType is null
	select @validcnt = count(*) from inserted where Datatype is null and InputType in (0,1,2,3,4,5,6)
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Input Type' 
		goto error
		end
	end
 
/* Audit updates */
if update(DisplaySeq)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'Report ID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'DisplaySeq', d.DisplaySeq, i.DisplaySeq, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where i.DisplaySeq <> d.DisplaySeq
if update(ReportDatatype)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'ReportDatatype', d.ReportDatatype, i.ReportDatatype, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where i.ReportDatatype <> d.ReportDatatype
if update(Datatype)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'Datatype', d.Datatype, i.Datatype, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.Datatype,'') <> isnull(d.Datatype,'')
if update(ActiveLookup)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'ActiveLookup', d.ActiveLookup, i.ActiveLookup, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.ActiveLookup,'') <> isnull(d.ActiveLookup,'')
if update(LookupParams)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'LookupParams', d.LookupParams, i.LookupParams, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	and isnull(i.LookupParams,'') <> isnull(d.LookupParams,'')
if update(LookupSeq)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'LookupSeq', convert(varchar,d.LookupSeq), convert(varchar,i.LookupSeq), getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	and isnull(i.LookupSeq,255) <> isnull(d.LookupSeq,255)
if update(Description)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'Description', d.Description, i.Description, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	and isnull(i.Description,'') <> isnull(d.Description,'')
if update(ParameterDefault)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'ParameterDefault', d.ParameterDefault, i.ParameterDefault, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	and isnull(i.ParameterDefault,'') <> isnull(d.ParameterDefault,'')
if update(InputType)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'InputType', convert(varchar,d.InputType), convert(varchar,i.InputType), getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	and isnull(i.InputType,255) <> isnull(d.InputType,255)
if update(InputMask)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'InputMask', d.InputMask, i.InputMask, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	and isnull(i.InputMask,'') <> isnull(d.InputMask,'')
if update(InputLength)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'InputLength', d.InputLength, i.InputLength, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	and isnull(i.InputLength, -1) <> isnull(d.InputLength,-1)
if update(Prec)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRP', 'ReportID: ' + convert(varchar,i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'Precision', d.Prec, i.Prec, getdate(),
 		case when suser_name() = 'viewpointcs' then host_name() else suser_name() end
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	and isnull(i.Prec, 255) <> isnull(d.Prec,255)

return
 
 
error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot update standard Report Parameter'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [viRPRP] ON [dbo].[vRPRP] ([ReportID], [ParameterName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vRPRP].[ActiveLookup]'
GO
