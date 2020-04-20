CREATE TABLE [dbo].[vWFMail]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[UserID] [dbo].[bVPUserName] NOT NULL,
[SentTo] [varchar] (3000) COLLATE Latin1_General_BIN NOT NULL,
[CC] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[BCC] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[From] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[Subject] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[Body] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Source] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[SentDate] [datetime] NOT NULL CONSTRAINT [DF_vWFMail_SentDate] DEFAULT (getdate()),
[IsRead] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFMail_IsRead] DEFAULT ('N'),
[IsNew] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFMail_IsNew] DEFAULT ('Y'),
[AttachIDs] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[AttachFiles] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[HasAttachments] [dbo].[bYN] NULL CONSTRAINT [DF_vWFMail_HasAttachments] DEFAULT ('N'),
[Selected] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWFMail_Selected] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 2/20/2008
-- Description:	Trigger to populate the attachment link tables
-- =============================================
CREATE TRIGGER [dbo].[vWFMaili]
   ON  [dbo].[vWFMail] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

INSERT INTO vWFMailAttchLink
SELECT i.KeyID, IDs.* FROM inserted i
	CROSS APPLY vfTableFromArray(i.AttachIDs) as IDs

INSERT INTO vWFMailAttchFiles
SELECT i.KeyID, Files.Names FROM inserted i
	CROSS APPLY vfTableFromArray(i.AttachFiles) AS Files

UPDATE vWFMail SET HasAttachments = 'Y', AttachIDs = null, AttachFiles = null
	FROM vWFMail
	INNER JOIN inserted on vWFMail.KeyID = inserted.KeyID
	WHERE (inserted.AttachIDs IS NOT NULL AND inserted.AttachIDs <> '')OR (inserted.AttachFiles IS NOT NULL AND inserted.AttachFiles <> '')
END

GO
ALTER TABLE [dbo].[vWFMail] ADD CONSTRAINT [PK_vWFMail] PRIMARY KEY CLUSTERED  ([KeyID], [UserID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
