CREATE TABLE [dbo].[vDMAttachmentDeletionQueue]
(
[AttachmentID] [int] NOT NULL,
[UserName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[DeletedFromRecord] [dbo].[bYN] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
