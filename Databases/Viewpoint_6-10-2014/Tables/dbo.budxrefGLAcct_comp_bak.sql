CREATE TABLE [dbo].[budxrefGLAcct_comp_bak]
(
[Company] [dbo].[bCompany] NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[newCompany] [dbo].[bCompany] NULL,
[newGLAcct] [dbo].[bGLAcct] NULL,
[oldGLAcct] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
