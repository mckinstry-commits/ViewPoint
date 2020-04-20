CREATE TABLE [dbo].[budxrefGLAcct_LWO_20140508]
(
[Company] [dbo].[bCompany] NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[newCompany] [dbo].[bCompany] NULL,
[newDescription] [dbo].[bDesc] NULL,
[newGLAcct] [dbo].[bGLAcct] NULL,
[oldGLAcct] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[olgGLBaseAccount] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
