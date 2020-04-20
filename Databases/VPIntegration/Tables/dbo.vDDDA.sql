CREATE TABLE [dbo].[vDDDA]
(
[TableName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Action] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[KeyString] [varchar] (120) COLLATE Latin1_General_BIN NULL,
[FieldName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OldValue] [varchar] (6000) COLLATE Latin1_General_BIN NULL,
[NewValue] [varchar] (6000) COLLATE Latin1_General_BIN NULL,
[RevDate] [smalldatetime] NOT NULL,
[UserName] [dbo].[bVPUserName] NULL,
[HostName] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
