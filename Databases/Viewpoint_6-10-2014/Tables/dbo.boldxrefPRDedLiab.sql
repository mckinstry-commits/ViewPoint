CREATE TABLE [dbo].[boldxrefPRDedLiab]
(
[CMSDedCode] [int] NOT NULL,
[CMSDedType] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMSUnion] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Company] [dbo].[bCompany] NOT NULL,
[DLCode] [dbo].[bEDLCode] NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[VPType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
