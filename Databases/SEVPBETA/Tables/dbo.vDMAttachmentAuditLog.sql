CREATE TABLE [dbo].[vDMAttachmentAuditLog]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachmentID] [int] NOT NULL,
[DateTime] [datetime] NOT NULL,
[UserName] [dbo].[bVPUserName] NULL,
[FieldName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldValue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[NewValue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Event] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDMAttachmentAuditLog] ADD CONSTRAINT [PK_vDMAttachmentAuditLog] PRIMARY KEY CLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
