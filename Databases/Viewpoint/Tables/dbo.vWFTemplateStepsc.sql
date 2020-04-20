CREATE TABLE [dbo].[vWFTemplateStepsc]
(
[KeyID] [int] NOT NULL IDENTITY(2, 2),
[Step] [int] NOT NULL,
[Task] [int] NOT NULL,
[Template] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[Summary] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[IsStepRequired] [dbo].[bYN] NOT NULL,
[UseEmail] [dbo].[bYN] NOT NULL,
[Description] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[StepType] [smallint] NOT NULL,
[VPName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFTemplateStepsc_IsStandard] DEFAULT ('N'),
[AddedBy] [dbo].[bVPUserName] NULL,
[AddedOn] [datetime] NULL,
[ChangedBy] [dbo].[bVPUserName] NULL,
[ChangedOn] [datetime] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ReportID] [int] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vWFTemplateStepsc] ADD CONSTRAINT [PK_vWFTemplateStepsc] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: Charles Courchaine 12/20/2007
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information.
*	And enforces task/step requirement concurency
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFTemplateStepsi] 
   ON  [dbo].[vWFTemplateStepsc] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
UPDATE vWFTemplateStepsc SET AddedBy = SUSER_SNAME(), AddedOn = GETDATE(), ChangedBy = SUSER_SNAME(), ChangedOn = GETDATE() 
	FROM vWFTemplateStepsc s
	INNER JOIN inserted i
	ON s.Step = i.Step 
		AND s.Task = i.Task 
		AND s.Template = i.Template 

--if the task is not required and a step becomes required, make the task required.
IF EXISTS (SELECT TOP 1 1 FROM vWFTemplateTasksc t INNER JOIN inserted i 
	ON t.Template = i.Template AND t.Task = i.Task WHERE t.IsTaskRequired = 'N') 
	AND 
	EXISTS (SELECT TOP 1 1 FROM inserted i WHERE i.IsStepRequired = 'Y') 
		UPDATE vWFTemplateTasksc SET IsTaskRequired = 'Y'
		FROM vWFTemplateTasksc t
		INNER JOIN inserted i
		ON t.Template = i.Template AND t.Task = i.Task WHERE i.IsStepRequired = 'Y'

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: Charles Courchaine 12/20/2007
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information.
*	And enforces task/step requirement concurency
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFTemplateStepsu] 
   ON  [dbo].[vWFTemplateStepsc] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
UPDATE vWFTemplateStepsc SET ChangedBy = SUSER_SNAME(), ChangedOn = GETDATE() 
	FROM vWFTemplateStepsc s
	INNER JOIN inserted i
	ON s.Step = i.Step 
		AND s.Task = i.Task 
		AND s.Template = i.Template

IF UPDATE(IsStepRequired)
	IF EXISTS(SELECT TOP 1 1 FROM deleted d INNER JOIN inserted i ON d.Template = i.Template AND d.KeyID = i.KeyID AND d.IsStepRequired <> i.IsStepRequired) 
	BEGIN
		--if the task is not required and a step becomes required, make the task required.
		IF EXISTS (SELECT TOP 1 1 FROM vWFTemplateTasksc t inner join inserted i 
			ON t.Template = i.Template AND t.Task = i.Task WHERE t.IsTaskRequired = 'N') 
			AND 
			EXISTS (SELECT TOP 1 1 FROM inserted i WHERE i.IsStepRequired = 'Y') 
				UPDATE vWFTemplateTasksc SET IsTaskRequired = 'Y'
				FROM vWFTemplateTasksc t INNER JOIN inserted i
				ON t.Template = i.Template AND t.Task = i.Task WHERE i.IsStepRequired = 'Y'
	END	

END

GO
