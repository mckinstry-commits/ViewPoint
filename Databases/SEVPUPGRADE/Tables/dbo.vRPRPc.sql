CREATE TABLE [dbo].[vRPRPc]
(
[ReportID] [int] NOT NULL,
[ParameterName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[DisplaySeq] [tinyint] NULL,
[ReportDatatype] [char] (1) COLLATE Latin1_General_BIN NULL,
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
[PortalAccess] [int] NOT NULL CONSTRAINT [DF_vRPRPc_PortalAccess] DEFAULT ((1)),
[ParamRequired] [dbo].[bYN] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[vtRPRPcd] ON [dbo].[vRPRPc] FOR Delete AS
/************************************************************
 * Created: TL 6/13/05
 * Modified: GG 10/27/06 
 *
 * Delete trigger on custom Report Parameters (vRPRPc)
 *
 * Removes entries from custom reports referencing deleted parameters
 *
 * Adds HQ Audit entry 
 *
 *********************************************************/

DECLARE	@numrows int, @errmsg varchar(255)
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- remove custom form/report parameter defaults 
delete dbo.vRPFDc
from deleted d
join dbo.vRPFDc c on c.ReportID = d.ReportID and c.ParameterName = d.ParameterName
where d.ReportID > 9999

-- remove custom parameter lookups
delete dbo.vRPPLc
from deleted d
join dbo.vRPPLc c on c.ReportID = d.ReportID and c.ParameterName = d.ParameterName
where d.ReportID > 9999


/* Audit deletions */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vRPRPc','Report ID: ' + convert(varchar,ReportID) + ' ParameterName: ' + ParameterName,
  	null, 'D',NULL, NULL, NULL, getdate(), suser_name()
from deleted 
  
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete custom Report Parameter.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
  
  
  
  
  
  
  
  
 
 
 











GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtRPRPci] on [dbo].[vRPRPc] for INSERT as
/***************************************************
* Created: TL 06/13/05
* Modified: GG 10/27/06
*
* Insert trigger on custom Report Parameters (vRPRPc)
*
* Rejects insert if the following conditions exist:
*	Invalid Report ID# 
*	Invalid ParameterName
*	Invalid ReportDatatype
*	Invalid Datatype
*	Invalid ParameterDefault
*	Invalid InputType
*
* Adds HQ Audit entry
*
*********************************************************/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, 
	@validcnt2 int, @nullcnt1 int
  
select @numrows = @@rowcount 
if @numrows = 0 return
set nocount on    

-- validate ReportID# - all reports
select @validcnt = count(*)
from inserted i
join dbo.RPRTShared t on t.ReportID = i.ReportID
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Report ID#'
	goto error
	end
-- validate standard ReportID and Parameter Name
select @validcnt = count(*) 
from inserted i
join dbo.vRPRP p (nolock) on p.ReportID = i.ReportID and p.ParameterName = i.ParameterName
where i.ReportID < 10000
select @validcnt2 = count(*) from inserted
where ReportID < 10000
if @validcnt <> @validcnt2
	begin
	select @errmsg = 'Parameter override is missing standard entry'
  	goto error
  	end
DECLARE @appType varchar(30)  	
-- validate Parameter Name
select @appType = AppType
from inserted i
join dbo.RPRTShared t on t.ReportID = i.ReportID
-- Only Crystal reports require ? or @
if @appType='Crystal' and exists(select top 1 1 from inserted where SUBSTRING(ParameterName,1,1) not in ('?','@'))
     begin
     select @errmsg = 'Parameter Name must begin with @ or ?'
     goto error
     end
-- validate Report Datatype
if exists(select top 1 1 from inserted where ReportID > 9999 and ReportDatatype not in ('S','N','D','M'))
     begin
     select @errmsg = 'Report Datatype must be ''S'', ''N'', ''D'' or "M"'
     goto error
     end
-- validate Datatype
if exists(select top 1 1 from inserted where Datatype is not null and ReportID < 10000)
	begin
	select @errmsg = 'Cannot override Datatype on a standard Report Parameter'
	goto error
	end
select @nullcnt = count(*) from inserted where Datatype is null
select @validcnt = count(*)
from inserted i
join dbo.DDDTShared d (nolock) on d.Datatype = i.Datatype
where i.ReportID > 9999
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
if exists(select top 1 1 from inserted where InputType is not null and ReportID < 10000)
	begin
	select @errmsg = 'Cannot override Input Type on a standard Report Parameter'
	goto error
	end
select @nullcnt1 - count(*) from inserted where ReportID < 10000
select @nullcnt = count(*) from inserted
where Datatype is not null and InputType is null and ReportID > 9999
select @validcnt = count(*) from inserted
where Datatype is null and InputType in (0,1,2,3,5,6) and ReportID > 9999
if  @nullcnt1 + @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Input Type' 
	goto error
	end

  
/* Audit inserts */
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vRPRPc','Report ID: ' + convert(varchar, ReportID) + 'ParameterName: ' + ParameterName,
 	 null, 'A', NULL, NULL, NULL, getdate(), suser_name()
FROM inserted i
 
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert custom Report Parameter.'
    RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPRPcu] ON [dbo].[vRPRPc] FOR Update AS
/***************************************************
* Created: TL 06/13/05
* Modified: GG 10/30/06
*
* Update trigger on custom Report Parameters (vRPRPc)
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
 
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @validcnt2 int
  
select @numrows = @@rowcount 
if @numrows = 0 return

set nocount on 

-- check for update to primary key
if update(ReportID) or update(ParameterName)
	begin
	select @errmsg = 'Cannot update ReportID# or Parameter Name'
	goto error
	end
-- validate Report Datatype
if update(ReportDatatype)
	begin
	if exists(select top 1 1 from inserted where ReportID < 10000 and ReportDatatype is not null)
		begin
		select @errmsg = 'Canot override Report Datatype on a standard report parameter'
		goto error
		end
	if exists(select top 1 1 from inserted where ReportID > 9999 and ReportDatatype not in ('S','N','D','M'))
		 begin
		 select @errmsg = 'Report Datatype must be ''S'', ''N'', ''D'' or "M"'
		 goto error
		 end
	end
-- validate Datatype
if update(Datatype)
	begin
	if exists(select top 1 1 from inserted where ReportID < 10000 and Datatype is not null)
		begin
		select @errmsg = 'Canot override Datatype on a standard report parameter'
		goto error
		end
	-- validate on custom reports
	select @validcnt = count(*) from inserted where ReportID > 9999	
	select @nullcnt = count(*) from inserted where ReportID > 9999 and Datatype is null
	select @validcnt2 = count(*)
	from inserted i
	join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
	where i.ReportID > 9999
	if @validcnt2 + @nullcnt <> @validcnt
		begin
		select @errmsg = 'Invalid Datatype'
		goto error
		end
	end
-- validate Parameter Default
--if update(ParameterDefault)
--	begin
--	if exists(select top 1 1 from inserted where substring(ParameterDefault,1,1) = '%'
--			and (substring(ParameterDefault,2,1) not in ('C','D','M') and substring(ParameterDefault,2,2) <> 'RP'))
--		begin
--		select @errmsg = 'Invalid Parameter Default'
--		goto error
--		end
--	end
if update(ParameterDefault)
	begin
	if exists(select top 1 1 from inserted where substring(ParameterDefault,1,1) = '%'
			and (substring(ParameterDefault,2,1) not in ('C','D','M') and substring(ParameterDefault,2,2) <> 'RP') 
			and upper(ParameterDefault) not in ('%PROJECT','%JOB','%CONTRACT','%PRGROUP','%PRENDDATE','%JBPROGMTH','%JBPROGBILL','%JBTMMTH','%JBTMBILL','%RAC','%C'))	
		begin
		select @errmsg = 'Invalid Parameter Default'
		goto error
		end
	end
-- validate Input Type
if update(InputType)
	begin
	if exists(select top 1 1 from inserted where ReportID < 10000 and InputType is not null)
		begin
		select @errmsg = 'Cannot override Input Type on a standard report parameter'
		goto error
		end
	--validate on custom reports
	select @validcnt = count(*) from inserted where ReportID > 9999
	select @nullcnt = count(*) from inserted where ReportID > 9999 and Datatype is not null and InputType is null
	select @validcnt2 = count(*) from inserted where ReportID > 9999 and Datatype is null and InputType in (0,1,2,3,4,5,6)
	if @validcnt2 + @nullcnt <> @validcnt
		begin
		select @errmsg = 'Invalid Input Type' 
		goto error
		end
	end
 
 /* Audit inserts */
if update(DisplaySeq)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'Report ID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'DisplaySeq', convert(varchar,d.DisplaySeq), convert(varchar,i.DisplaySeq), getdate(), suser_name()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.DisplaySeq,255) <> isnull(d.DisplaySeq,255)
if update(ReportDatatype)	
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'ReportID: ' +convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'ReportDatatype', d.ReportDatatype, i.ReportDatatype, getdate(), suser_name()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.ReportDatatype,'') <> isnull(d.ReportDatatype,'')
if update(Datatype)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'ReportID: ' +convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'Datatype', d.Datatype, i.Datatype, getdate(), suser_name()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.Datatype,'') <> isnull(d.Datatype,'')
if update(ActiveLookup)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'ReportID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'ActiveLookup', d.ActiveLookup, i.ActiveLookup, getdate(), suser_name()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.ActiveLookup,'') <> isnull(d.ActiveLookup,'')
if update(LookupParams)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'ReportID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'LookupParams', d.LookupParams, i.LookupParams, getdate(), suser_name()
  	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.LookupParams,'') <> isnull(d.LookupParams,'')
if update(LookupSeq)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'Report ID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'LookupSeq', convert(varchar,d.LookupSeq), convert(varchar,i.LookupSeq), getdate(), suser_name()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.LookupSeq,255) <> isnull(d.LookupSeq,255)
if update(Description)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'ReportID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'Description', d.Description, i.Description, getdate(), suser_name()
  	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.Description,'') <> isnull(d.Description,'')
if update(ParameterDefault)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'ReportID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'ParameterDefault', d.ParameterDefault, i.ParameterDefault, getdate(), suser_name()
  	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.ParameterDefault,'') <> isnull(d.ParameterDefault,'')
if update(InputType)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'Report ID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'InputType', convert(varchar,d.InputType), convert(varchar,i.InputType), getdate(), suser_name()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.InputType,255) <> isnull(d.InputType,255)
if update(InputMask)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'ReportID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'InputMask', d.InputMask, i.InputMask, getdate(), suser_name()
  	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.InputMask,'') <> isnull(d.InputMask,'')
if update(InputLength)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'Report ID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'InputLength', convert(varchar,d.InputLength), convert(varchar,i.InputLength), getdate(), suser_name()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.InputLength,-1) <> isnull(d.InputLength,-1)
if update(Prec)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'vRPRPc', 'Report ID: ' + convert(varchar, i.ReportID) + ' ParameterName: ' + i.ParameterName, null, 'C',
 		'Prec', convert(varchar,d.Prec), convert(varchar,i.Prec), getdate(), suser_name()
 	from inserted i
	join deleted d on i.ReportID = d.ReportID and i.ParameterName = d.ParameterName
 	where isnull(i.Prec,255) <> isnull(d.Prec,255)
 
return
 
 
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update custom Report Parameter.'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [viRPRPc] ON [dbo].[vRPRPc] ([ReportID], [ParameterName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vRPRPc].[ActiveLookup]'
GO
