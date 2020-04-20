CREATE TABLE [dbo].[vWFTemplateTasksc]
(
[KeyID] [int] NOT NULL IDENTITY(2, 2),
[Task] [int] NOT NULL,
[Template] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Summary] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[IsTaskRequired] [dbo].[bYN] NOT NULL,
[UseEmail] [dbo].[bYN] NOT NULL,
[Description] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[TaskType] [smallint] NOT NULL,
[VPName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFTemplateTasksc_IsStandard] DEFAULT ('N'),
[AddedBy] [dbo].[bVPUserName] NOT NULL,
[AddedOn] [datetime] NOT NULL,
[ChangedBy] [dbo].[bVPUserName] NOT NULL,
[ChangedOn] [datetime] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ReportID] [int] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: Charles Courchaine 12/18/2007
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information.
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFTemplateTasksi] 
   ON  [dbo].[vWFTemplateTasksc] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
update vWFTemplateTasksc set AddedBy = suser_sname(), AddedOn = GetDate(), ChangedBy = suser_sname(), ChangedOn = GetDate() where Task in (select Task from inserted) and Template in (select Template from inserted)

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: Charles Courchaine 12/18/2007
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information.
*	And enforces task/step requirement concurency
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFTemplateTasksu] 
   ON  [dbo].[vWFTemplateTasksc] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
update vWFTemplateTasksc set ChangedBy = suser_sname(), ChangedOn = GetDate() where Task in (select Task from inserted) and Template in (select Template from inserted)

IF Update(IsTaskRequired)
	IF exists (select top 1 1 from deleted d inner join inserted i on
		d.KeyID = i.KeyID and d.IsTaskRequired <> i.IsTaskRequired where i.IsTaskRequired = 'N')
	BEGIN
		update vWFTemplateStepsc set IsStepRequired = 'N'
			from  vWFTemplateStepsc
			inner join inserted on
			vWFTemplateStepsc.Template = inserted.Template
				and vWFTemplateStepsc.Task = inserted.Task 
				where inserted.IsTaskRequired = 'N'
	END

END

GO
ALTER TABLE [dbo].[vWFTemplateTasksc] ADD CONSTRAINT [PK_vWFTemplateTasksc] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
