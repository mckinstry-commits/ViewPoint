CREATE TABLE [dbo].[vDDNotificationPrefs]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Source] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Destination] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vDDNotificationPrefs] ADD 
CONSTRAINT [PK_vDDNotificationPrefs] PRIMARY KEY CLUSTERED  ([VPUserName], [Source], [Destination]) WITH (FILLFACTOR=90) ON [PRIMARY]
ALTER TABLE [dbo].[vDDNotificationPrefs] WITH NOCHECK ADD
CONSTRAINT [FK_vDDUP_vDDNP] FOREIGN KEY ([VPUserName]) REFERENCES [dbo].[vDDUP] ([VPUserName])
GO
ALTER TABLE [dbo].[vDDNotificationPrefs] WITH NOCHECK ADD CONSTRAINT [CK_vDDNotificationPrefs_Destination] CHECK (([Destination]='Viewpoint' OR [Destination]='EMail'))
GO
