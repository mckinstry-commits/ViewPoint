CREATE TABLE [dbo].[boldxrefGLSubLedger]
(
[Company] [tinyint] NOT NULL,
[oldAppCode] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
[newSubLedgerCode] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
