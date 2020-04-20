CREATE TABLE [dbo].[tmp-44FB8177-A892-4133-84CA-91CE6A87507D]
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
