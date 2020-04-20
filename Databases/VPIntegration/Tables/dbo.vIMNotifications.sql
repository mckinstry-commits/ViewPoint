CREATE TABLE [dbo].[vIMNotifications]
(
[ImportTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[NotificationSeq] [int] NOT NULL,
[DestinationType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[DestinationName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[NotifyOnSuccess] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[NotifyOnFailure] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AttachLogFile] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viIMNotifications] ON [dbo].[vIMNotifications] ([ImportTemplate], [NotificationSeq]) ON [PRIMARY]
GO
