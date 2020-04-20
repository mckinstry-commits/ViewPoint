CREATE TABLE [dbo].[vWFVPTemplates]
(
[KeyID] [int] NOT NULL IDENTITY(2, 2),
[Template] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Revised] [datetime] NULL,
[EnforceOrder] [dbo].[bYN] NOT NULL,
[UseEmail] [dbo].[bYN] NOT NULL,
[IsActive] [dbo].[bYN] NOT NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFVPTemplates_IsStandard] DEFAULT ('Y'),
[AddedBy] [dbo].[bVPUserName] NOT NULL,
[AddedOn] [datetime] NOT NULL,
[ChangedBy] [dbo].[bVPUserName] NOT NULL,
[ChangedOn] [datetime] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
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
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFVPTemplatesi] 
   ON  [dbo].[vWFVPTemplates]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
UPDATE vWFVPTemplates SET AddedBy = SUSER_SNAME(), AddedOn = GETDATE(), ChangedBy = SUSER_SNAME(), ChangedOn = GETDATE()
	FROM vWFVPTemplates t
	INNER JOIN inserted i
	ON t.Template = i.Template
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: Charles Courchaine 3/17/2008
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFVPTemplatesu] 
   ON  [dbo].[vWFVPTemplates] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
UPDATE vWFVPTemplates SET ChangedBy = SUSER_SNAME(), ChangedOn = GETDATE() 
	FROM vWFVPTemplates t
	INNER JOIN inserted i
	ON t.Template = i.Template
END

GO
ALTER TABLE [dbo].[vWFVPTemplates] ADD CONSTRAINT [PK_vWFVPTemplates] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
