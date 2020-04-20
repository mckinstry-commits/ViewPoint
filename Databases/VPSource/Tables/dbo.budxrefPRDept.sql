CREATE TABLE [dbo].[budxrefPRDept]
(
[Company] [tinyint] NOT NULL,
[CMSCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PRDept] [dbo].[bDept] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
