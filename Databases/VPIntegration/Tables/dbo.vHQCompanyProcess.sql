CREATE TABLE [dbo].[vHQCompanyProcess]
(
[Mod] [char] (2) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vHQCompanyProcess_Mod] DEFAULT ('HQ'),
[HQCo] [dbo].[bCompany] NOT NULL,
[DocType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Process] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQCompanyProcess_Active] DEFAULT ('Y'),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtHQCompanyProcessd] on [dbo].[vHQCompanyProcess] for DELETE as
/*********************************************************
* Created:		GP 4/6/12
* Modified: 
*
* Delete trigger for HQ Company Process
*
***********************************************************/
declare @errmsg varchar(255)

set nocount on

begin try

	--insert audit record
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	select 'vHQCompanyProcess', 'Mod: ' + d.[Mod] + ' HQCo: ' + cast(d.HQCo as varchar(3)) + ' DocType: ' + d.DocType, d.HQCo, 'D', NULL, NULL, NULL, getdate(), suser_sname()
	from deleted d

end try


begin catch

	select @errmsg = @errmsg + ' - cannot delete HQ Company Process'
	RAISERROR(@errmsg, 11, -1);
	
end catch




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtHQCompanyProcessi] on [dbo].[vHQCompanyProcess] for INSERT as
/*********************************************************
* Created:		GP 4/6/12
* Modified: 
*
* Insert trigger for HQ Company Process
*
***********************************************************/
declare @errmsg varchar(255)

set nocount on

begin try

	--insert audit record
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
	select 'vHQCompanyProcess', 'Mod: ' + i.[Mod] + ' HQCo: ' + cast(i.HQCo as varchar(3)) + ' DocType: ' + i.DocType, i.HQCo, 'A', NULL, NULL, NULL, getdate(), suser_sname()
	from inserted i

end try


begin catch

	select @errmsg = @errmsg + ' - cannot insert HQ Company Process'
	RAISERROR(@errmsg, 11, -1);
	
end catch




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE trigger [dbo].[vtHQCompanyProcessu] on [dbo].[vHQCompanyProcess] for UPDATE as
/*********************************************************
* Created:		GP 4/6/12
* Modified: 
*
* Update trigger for HQ Company Process
*
***********************************************************/
declare @errmsg varchar(255)

set nocount on

begin try
	
	if update(Process)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vHQCompanyProcess', 'Mod: ' + i.[Mod] + ' HQCo: ' + cast(i.HQCo as varchar(3)) + ' DocType: ' + i.DocType, i.HQCo, 'C', 'Process', d.Process, i.Process, getdate(), suser_sname()
		from inserted i
		join deleted d on d.[Mod] = i.[Mod] and d.HQCo = i.HQCo and d.DocType = i.DocType
	end	
	
	if update(Active)
	begin
		--insert audit record
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		select 'vHQCompanyProcess', 'Mod: ' + i.[Mod] + ' HQCo: ' + cast(i.HQCo as varchar(3)) + ' DocType: ' + i.DocType, i.HQCo, 'C', 'Active', d.Active, i.Active, getdate(), suser_sname()
		from inserted i
		join deleted d on d.[Mod] = i.[Mod] and d.HQCo = i.HQCo and d.DocType = i.DocType
	end	
	
end try


begin catch

	select @errmsg = @errmsg + ' - cannot update HQ Company Process'
	RAISERROR(@errmsg, 11, -1);
	
end catch




GO
ALTER TABLE [dbo].[vHQCompanyProcess] ADD CONSTRAINT [PK_vHQCompanyProcess] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [IX_vHQCompanyProcess_HQCoDocType] ON [dbo].[vHQCompanyProcess] ([Mod], [HQCo], [DocType]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vHQCompanyProcess_ProcessOnly] ON [dbo].[vHQCompanyProcess] ([Process]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQCompanyProcess] WITH NOCHECK ADD CONSTRAINT [FK_vHQCompanyProcess_vDDMO] FOREIGN KEY ([Mod]) REFERENCES [dbo].[vDDMO] ([Mod])
GO
ALTER TABLE [dbo].[vHQCompanyProcess] WITH NOCHECK ADD CONSTRAINT [FK_vHQCompanyProcess_vWFProcess] FOREIGN KEY ([Process]) REFERENCES [dbo].[vWFProcess] ([Process])
GO
