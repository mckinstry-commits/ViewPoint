CREATE TABLE [dbo].[vWFSentNotifications]
(
[KeyHash] [uniqueidentifier] NOT NULL,
[JobName] [nvarchar] (60) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vWFSentNotifications] ADD 
CONSTRAINT [PK_vWFSentNotifications] PRIMARY KEY CLUSTERED  ([KeyHash], [JobName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
