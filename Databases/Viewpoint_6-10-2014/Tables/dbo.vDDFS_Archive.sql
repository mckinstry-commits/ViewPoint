CREATE TABLE [dbo].[vDDFS_Archive]
(
[Co] [smallint] NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[SecurityGroup] [int] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[Access] [tinyint] NOT NULL,
[RecAdd] [dbo].[bYN] NOT NULL,
[RecUpdate] [dbo].[bYN] NOT NULL,
[RecDelete] [dbo].[bYN] NOT NULL,
[AttachmentSecurityLevel] [tinyint] NULL,
[ArchiveDate] [datetime] NULL CONSTRAINT [DF__vDDFS_Arc__Archi__051E8AB9] DEFAULT (getdate()),
[ArchiveID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
