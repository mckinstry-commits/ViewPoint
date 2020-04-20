CREATE TABLE [dbo].[vWFTemplatesc]
(
[KeyID] [int] NOT NULL IDENTITY(1, 2),
[Template] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Revised] [datetime] NULL,
[EnforceOrder] [dbo].[bYN] NOT NULL,
[UseEmail] [dbo].[bYN] NOT NULL,
[IsActive] [dbo].[bYN] NOT NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFTemplatesc_IsStandard] DEFAULT ('N'),
[AddedBy] [dbo].[bVPUserName] NOT NULL,
[AddedOn] [datetime] NOT NULL,
[ChangedBy] [dbo].[bVPUserName] NOT NULL,
[ChangedOn] [datetime] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vWFTemplatesc] ADD CONSTRAINT [PK_vWFTemplatesc] PRIMARY KEY NONCLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: Charles Courchaine 1/4/2008
* Modified: 
*
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFTemplatesi] 
   ON  [dbo].[vWFTemplatesc]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
UPDATE vWFTemplatesc SET AddedBy = SUSER_SNAME(), AddedOn = GETDATE(), ChangedBy = SUSER_SNAME(), ChangedOn = GETDATE()
	FROM vWFTemplatesc t
	INNER JOIN inserted i
	ON t.Template = i.Template
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
*	This trigger updates the AddedBy, AddedOn, ChangedBy, and ChangedOn fields for audit information
*
************************************************************************/
CREATE TRIGGER [dbo].[vtWFTemplatesu] 
   ON  [dbo].[vWFTemplatesc] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
UPDATE vWFTemplatesc SET ChangedBy = SUSER_SNAME(), ChangedOn = GETDATE() 
	FROM vWFTemplatesc t
	INNER JOIN inserted i
	ON t.Template = i.Template
END

GO
