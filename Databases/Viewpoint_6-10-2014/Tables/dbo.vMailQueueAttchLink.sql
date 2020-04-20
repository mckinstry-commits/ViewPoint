CREATE TABLE [dbo].[vMailQueueAttchLink]
(
[MailID] [int] NOT NULL,
[AttachID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vMailQueueAttchLink] ADD CONSTRAINT [PK_vMailQueueAttchLink] PRIMARY KEY CLUSTERED  ([MailID], [AttachID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
