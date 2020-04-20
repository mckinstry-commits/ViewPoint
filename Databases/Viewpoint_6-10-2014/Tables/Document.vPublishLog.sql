CREATE TABLE [Document].[vPublishLog]
(
[PublishLogId] [uniqueidentifier] NOT NULL,
[DocumentId] [uniqueidentifier] NOT NULL,
[SuccessFlag] [bit] NOT NULL,
[SendDate] [datetime] NOT NULL,
[ReceiveDate] [datetime] NULL,
[ErrorMessage] [nvarchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [Document].[vPublishLog] ADD CONSTRAINT [PK_vPublishLog] PRIMARY KEY CLUSTERED  ([PublishLogId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPublishLog_DocumentId] ON [Document].[vPublishLog] ([DocumentId]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [Document].[vPublishLog] WITH NOCHECK ADD CONSTRAINT [FK_vPublishLog_Document] FOREIGN KEY ([DocumentId]) REFERENCES [Document].[vDocument] ([DocumentId])
GO
ALTER TABLE [Document].[vPublishLog] NOCHECK CONSTRAINT [FK_vPublishLog_Document]
GO
