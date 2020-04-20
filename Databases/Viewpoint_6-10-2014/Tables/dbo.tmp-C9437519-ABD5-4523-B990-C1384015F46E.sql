CREATE TABLE [dbo].[tmp-C9437519-ABD5-4523-B990-C1384015F46E]
(
[Company] [smallint] NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[FSSecurityGroup] [int] NOT NULL,
[FormSecUser] [dbo].[bVPUserName] NOT NULL,
[Access] [tinyint] NOT NULL,
[GroupName] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[SecurityUpdater] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[KeyHash] [uniqueidentifier] NULL,
[SeqForTmpTable] [int] NULL
) ON [PRIMARY]
GO
