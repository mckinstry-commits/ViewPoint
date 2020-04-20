CREATE TABLE [dbo].[vWFStatusCodes]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[StatusID] [int] NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AddedBy] [dbo].[bVPUserName] NOT NULL,
[AddedDate] [datetime] NOT NULL,
[ChangedBy] [dbo].[bVPUserName] NOT NULL,
[ChangeDate] [datetime] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[StatusType] [smallint] NOT NULL,
[IsChecklistStatus] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFStatusCodes_IsChecklistStatus] DEFAULT ('N'),
[IsDefaultStatus] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFStatusCodes_IsDefaultStatus] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[vtWFStatusCodesiu] 
   ON  [dbo].[vWFStatusCodes] 
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
IF EXISTS (SELECT TOP 1 1 FROM inserted WHERE IsChecklistStatus = 'Y')
	IF EXISTS(SELECT TOP 1 1 
			  FROM WFStatusCodes s 
			   INNER JOIN inserted i 
				ON s.IsChecklistStatus = i.IsChecklistStatus 
					AND s.StatusType = i.StatusType 
					AND i.IsChecklistStatus = 'Y' 
					AND s.KeyID <> i.KeyID)
		BEGIN
			ROLLBACK TRANSACTION
			RAISERROR('A checklist status of this type already exists.', 16, 1)
		END
IF EXISTS (SELECT TOP 1 1 FROM inserted WHERE IsDefaultStatus = 'Y')
	IF EXISTS (SELECT TOP 1 1 
				FROM WFStatusCodes s
				INNER JOIN inserted i ON s.StatusType = i.StatusType AND i.KeyID <> s.KeyID
				WHERE s.IsDefaultStatus = 'Y' AND s.IsChecklistStatus = 'N' AND i.IsChecklistStatus = 'N'
				)
		BEGIN
			ROLLBACK TRANSACTION
			RAISERROR('A default status of this type already exists.', 16, 1)
		END
END
GO
ALTER TABLE [dbo].[vWFStatusCodes] ADD CONSTRAINT [PK_vWFStatusCodes] UNIQUE NONCLUSTERED  ([StatusID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_StatusType] ON [dbo].[vWFStatusCodes] ([StatusType], [StatusID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
