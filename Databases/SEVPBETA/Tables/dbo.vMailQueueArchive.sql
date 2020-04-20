CREATE TABLE [dbo].[vMailQueueArchive]
(
[MailQueueID] [int] NOT NULL IDENTITY(1, 1),
[SentTo] [varchar] (3000) COLLATE Latin1_General_BIN NOT NULL,
[CC] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[BCC] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[SentFrom] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[Subject] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[Body] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Attempts] [int] NULL,
[FailureDate] [datetime] NULL,
[FailureReason] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[Source] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Sent] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vMailQueueArchive_Sent] DEFAULT ('N'),
[SentDate] [datetime] NULL,
[AttachIDs] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AttachFiles] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[HasAttachments] [dbo].[bYN] NULL CONSTRAINT [DF_vMailQueueArchive_HasAttachments] DEFAULT ('N'),
[TokenID] [int] NULL,
[VPUserName] [dbo].[bVPUserName] NULL
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
CREATE TRIGGER [dbo].[vMailQueueArchivei] 
   ON  [dbo].[vMailQueueArchive] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

INSERT INTO vMailQueueAttchLink
SELECT i.MailQueueID, IDs.* FROM inserted i
	CROSS APPLY vfTableFromArray(i.AttachIDs) AS IDs

INSERT INTO vMailQueueAttchFiles
SELECT i.MailQueueID, Files.Names FROM inserted i
	CROSS APPLY vfTableFromArray(i.AttachFiles) AS Files

UPDATE vMailQueueArchive SET HasAttachments = 'Y', AttachIDs = null, AttachFiles = null
	FROM vMailQueueArchive
	INNER JOIN inserted on vMailQueueArchive.MailQueueID = inserted.MailQueueID
	WHERE (inserted.AttachIDs IS NOT NULL AND inserted.AttachIDs <> '') OR (inserted.AttachFiles IS NOT NULL AND inserted.AttachFiles <> '')
END

GO
