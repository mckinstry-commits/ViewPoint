CREATE TABLE [dbo].[boldxrefPREarn]
(
[Company] [smallint] NOT NULL,
[CMSDedCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CMSCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[VPType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[EarnCode] [int] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
