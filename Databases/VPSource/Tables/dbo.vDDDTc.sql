CREATE TABLE [dbo].[vDDDTc]
(
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[InputMask] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputLength] [smallint] NULL,
[Prec] [tinyint] NULL,
[Secure] [dbo].[bYN] NULL,
[DfltSecurityGroup] [int] NULL,
[Label] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputType] [tinyint] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vDDDTc] ADD
CONSTRAINT [CK_vDDDTc_Secure] CHECK (([Secure]='Y' OR [Secure]='N' OR [Secure] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   trigger [dbo].[vtDDDTcd] on [dbo].[vDDDTc] for DELETE
/************************************
* Created: DANF 05/02/2007
* Modified: AL 2/24/09 Auditing added 
*
* Delete trigger on vDDDT (DD Datatype)
*
* Users should not be able to delete entries from this table.
*
*
************************************/
as

declare @errmsg varchar(255)
  
if @@rowcount = 0 return
set nocount on


select @errmsg = 'You are not able to delete data type entries from this table!'
goto error

-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDDTc', 'D', 'Datatype: ' + rtrim(Datatype), null, null,
	null, getdate(), SUSER_SNAME() from deleted

return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Datatype!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[vtDDDTci] on [dbo].[vDDDTc] for INSERT
/*****************************
* Created: GG 02/05/07
* Modified: GG 12/10/07 - #126413 - allow limited Input Type overrides
*
* Insert trigger on vDDDTc (DD Custom Datatypes)
*
* Rejects insert if the following conditions exist:
*	Nonstandard datatype
*	Improperly formatted Input Mask
*
* Adds DD Audit entry
*
*************************************/

as

declare @errmsg varchar(255), @numrows int, @validcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- make sure datatype has standard entry
select @validcnt = count(*) from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
if @validcnt <> @numrows
	begin
	select @errmsg = 'Not a standard Datatype'
	goto error
	end
	
-- #126413 - allow limited Input Type overrides (String can be overridden as Multi-Part and Multi-Part can be overriden as String)
if exists(select top 1 1 from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
			where isnull(i.InputType,d.InputType) not in (0,1,2,3,4,5,6))
	begin
	select @errmsg = 'Invalid Input Type, value must be between 0 and 6 '
	goto error
	end 
if exists(select top 1 1 from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
			where i.InputType is not null and i.InputType not in (0,5) and d.InputType in (0,5))
	begin
	select @errmsg = 'String to Multi-part or Multi-part to String only '
	goto error
	end 

-- validate mask for muti-part datatypes
if exists(select top 1 1 from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
			where isnull(i.InputType,d.InputType) = 5 and CHARINDEX('N',i.InputMask)>0 and PATINDEX('%N[^1-9]%', i.InputMask)>0) 
	begin
	select @errmsg = 'Invalid Input Mask, ''N'' should not be followed by a nonnumeric character '
	goto error
	end 
-- #123484 - additional mask validation
if exists(select top 1 1 from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
			where isnull(i.InputType,d.InputType) = 5 and substring(i.InputMask,len(i.InputMask),1) <> 'N')
	begin
	select @errmsg = 'Invalid Input Mask, ''N'' should be the last character '
	goto error
	end
if exists(select top 1 1 from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
			where isnull(i.InputType,d.InputType) = 5 and ((CHARINDEX('L',i.InputMask)>0 and PATINDEX('%L[0-9]%', i.InputMask)>0)
				or (CHARINDEX('R',i.InputMask)>0 and PATINDEX('%R[0-9]%', i.InputMask)>0)))
	begin
	select @errmsg = 'Invalid Input Mask, ''L'' or ''R'' must be followed by a nonnumeric character '
	goto error
	end


-- DD Audit  
insert vDDDA (TableName, Action, KeyString, FieldName, OldValue, 
  	NewValue, RevDate, UserName, HostName)
select 'vDDDTc', 'I', 'Datatype: ' + rtrim(Datatype), null, null,
	null, getdate(), SUSER_SNAME(), host_name()
from inserted 
  
-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDDTc', 'I', 'Datatype: ' + rtrim(Datatype), null, null,
	null, getdate(), SUSER_SNAME()
from inserted 

return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Datatype override!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
    










GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtDDDTcu] on [dbo].[vDDDTc] for UPDATE
/************************************
* Created: GG 02/05/07
* Modified: GG 12/10/07 - #126413 - allow limited Input Type overrides
*
* Update trigger on vDDDTc (DD Datatype Custom)
*
* Rejects updates if the following conditions exist:
*	Primary key change
*	Improperly formatted Input Mask
*
* Adds DD Audit entries for changed values
*
************************************/

as

declare @errmsg varchar(255), @numrows int, @validcnt int 
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
  
-- check for key changes 
select @validcnt = count(*) from inserted i join deleted d	on i.Datatype = d.Datatype
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Cannot change Datatype'
  	goto error
  	end
-- make sure datatype has standard entry
select @validcnt = count(*) from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
if @validcnt <> @numrows
	begin
	select @errmsg = 'Not a standard Datatype'
	goto error
	end
	
-- #126413 - allow limited Input Type overrides (String can be overridden as Multi-Part and Multi-Part can be overriden as String)
if update(InputType)
	begin
	if exists(select top 1 1 from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
			where isnull(i.InputType,d.InputType) not in (0,1,2,3,4,5,6))
		begin
		select @errmsg = 'Invalid Input Type, value must be between 0 and 6 '
		goto error
		end 
	if exists(select top 1 1 from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
				where i.InputType is not null and i.InputType not in (0,5) and d.InputType in (0,5))
		begin
		select @errmsg = 'String to Multi-part or Multi-part to String only '
		goto error
		end
	end
	 
-- validate mask for muti-part datatypes
if update(InputMask) or update(InputType)
	begin
	if exists(select top 1 1 from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
				where isnull(i.InputType,d.InputType) = 5 and CHARINDEX('N',i.InputMask)>0 and PATINDEX('%N[^1-9]%', i.InputMask)>0) 
		begin
		select @errmsg = 'Invalid Input Mask, ''N'' should not be followed by a nonnumeric character '
		goto error
		end 
	if exists(select top 1 1 from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
			where isnull(i.InputType,d.InputType) = 5 and substring(i.InputMask,len(i.InputMask),1) <> 'N')
		begin
		select @errmsg = 'Invalid Input Mask, ''N'' should be the last character '
		goto error
		end
	if exists(select top 1 1 from inserted i join dbo.vDDDT d (nolock) on d.Datatype = i.Datatype
			where isnull(i.InputType,d.InputType) = 5 and ((CHARINDEX('L',i.InputMask)>0 and PATINDEX('%L[0-9]%', i.InputMask)>0)
				or (CHARINDEX('R',i.InputMask)>0 and PATINDEX('%R[0-9]%', i.InputMask)>0)))
		begin
		select @errmsg = 'Invalid Input Mask, ''L'' or ''R'' must be followed by a nonnumeric character '
		goto error
		end
	end
  	
-- DD Audit
if update(InputMask)
	insert vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select 'vDDDTc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'InputMask',
		d.InputMask, i.InputMask, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype
  	where isnull(i.InputMask,'') <> isnull(d.InputMask,'')
if update(InputLength)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDTc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'InputLength',
		d.InputLength, i.InputLength, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.InputLength,'') <> isnull(d.InputLength,'')
if update(Prec)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDTc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'Prec',
		d.Prec, i.Prec, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.Prec,'') <> isnull(d.Prec,'')
if update(Secure)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDTc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'Secure',
		d.Secure, i.Secure, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.Secure,'') <> isnull(d.Secure,'')
if update(DfltSecurityGroup)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDTc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'DfltSecurityGroup',
		d.DfltSecurityGroup, i.DfltSecurityGroup, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.DfltSecurityGroup,'') <> isnull(d.DfltSecurityGroup,'')
if update(Label)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDTc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'Label',
		d.Label, i.Label, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.Label,'') <> isnull(d.Label,'')
if update(InputType)
	insert dbo.vDDDA(TableName, Action, KeyString, FieldName,
		OldValue, NewValue, RevDate, UserName, HostName)
	select  'vDDDTc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'InputType',
		d.InputType, i.InputType, getdate(), SUSER_SNAME(), host_name()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.InputType,'') <> isnull(d.InputType,'')


--HQMA Audit
if update(Secure)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDDDTc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'Secure',
		d.Secure, i.Secure, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.Secure,'') <> isnull(d.Secure,'')
if update(DfltSecurityGroup)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDDDTc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'DfltSecurityGroup',
		d.DfltSecurityGroup, i.DfltSecurityGroup, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.DfltSecurityGroup,'') <> isnull(d.DfltSecurityGroup,'')
if update(Label)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDDDTc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'Label',
		d.Label, i.Label, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.Label,'') <> isnull(d.Label,'')
return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot override Datatype!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
GO
CREATE UNIQUE CLUSTERED INDEX [viDDDTc] ON [dbo].[vDDDTc] ([Datatype]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDDTc].[Secure]'
GO
