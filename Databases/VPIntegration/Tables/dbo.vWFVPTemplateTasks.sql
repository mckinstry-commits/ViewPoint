CREATE TABLE [dbo].[vWFVPTemplateTasks]
(
[KeyID] [int] NOT NULL IDENTITY(1, 2),
[Task] [int] NOT NULL,
[Template] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Summary] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[IsTaskRequired] [dbo].[bYN] NOT NULL,
[UseEmail] [dbo].[bYN] NOT NULL,
[Description] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[TaskType] [smallint] NOT NULL,
[VPName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFVPTemplateTasks_IsStandard] DEFAULT ('Y'),
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
* Created: Charles Courchaine 3/17/2008
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information.
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFVPTemplateTasksi] 
   ON  [dbo].[vWFVPTemplateTasks] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
UPDATE vWFVPTemplateTasks SET AddedBy = SUSER_SNAME(), AddedOn = GETDATE(), ChangedBy = SUSER_SNAME(), ChangedOn = GETDATE() 
FROM vWFVPTemplateTasks t
INNER JOIN inserted i ON i.Task = t.Task AND i.Template = t.Template

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
CREATE TRIGGER [dbo].[vtWFVPTemplateTasksu] 
   ON  [dbo].[vWFVPTemplateTasks] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
UPDATE vWFVPTemplateTasks SET ChangedBy = SUSER_SNAME(), ChangedOn = GETDATE() 
FROM vWFVPTemplateTasks t
INNER JOIN inserted i ON i.Task = t.Task AND i.Template = t.Template


IF UPDATE(IsTaskRequired)
	IF exists (SELECT TOP 1 1 FROM deleted d INNER JOIN inserted i ON
		d.KeyID = i.KeyID AND d.Template = i.Template AND d.IsTaskRequired <> i.IsTaskRequired WHERE i.IsTaskRequired = 'N')
	BEGIN
		UPDATE vWFVPTemplateSteps SET IsStepRequired = 'N'
			FROM vWFVPTemplateSteps
			INNER JOIN inserted ON
			vWFVPTemplateSteps.Template = inserted.Template
				AND vWFVPTemplateSteps.Task = inserted.Task 
				WHERE inserted.IsTaskRequired = 'N'
	END

END

GO
ALTER TABLE [dbo].[vWFVPTemplateTasks] ADD CONSTRAINT [PK_vWFVPTemplateTasks] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
