CREATE TABLE [dbo].[vWFSentNotifications]
(
[KeyHash] [uniqueidentifier] NOT NULL,
[JobName] [nvarchar] (60) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_HashKeyJobName] ON [dbo].[vWFSentNotifications] ([KeyHash], [JobName]) ON [PRIMARY]
GO
