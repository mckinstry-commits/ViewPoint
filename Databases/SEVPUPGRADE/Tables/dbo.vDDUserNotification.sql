CREATE TABLE [dbo].[vDDUserNotification]
(
[UserNotificationID] [int] NOT NULL,
[CategoryID] [int] NOT NULL,
[Heading] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Message] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[Extended] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (1000) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDUserNotification] ADD CONSTRAINT [PK_vDDUserNotification] PRIMARY KEY CLUSTERED  ([UserNotificationID]) ON [PRIMARY]
GO
