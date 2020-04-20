CREATE TABLE [dbo].[vDMAttachmentGridOptions]
(
[UserName] [dbo].[bVPUserName] NOT NULL,
[HQAIColumnName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDMAttachmentGridOptions] ADD CONSTRAINT [PK_vDMAttachmentGridOptions] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vDMAttachmentGridOptions] ON [dbo].[vDMAttachmentGridOptions] ([UserName], [HQAIColumnName]) ON [PRIMARY]
GO
