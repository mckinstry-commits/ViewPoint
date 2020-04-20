CREATE TABLE [dbo].[boldxrefJCDept]
(
[Company] [tinyint] NOT NULL,
[CMSDept] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[VPCo] [tinyint] NOT NULL,
[VPDept] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
