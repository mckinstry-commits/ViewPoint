CREATE TABLE [dbo].[mckTEMPxrefGLAcct]
(
[Sequence] [int] NOT NULL,
[CGCCompany] [int] NULL,
[CGCGLAcct] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[VPGLAcct] [dbo].[bGLAcct] NULL,
[Description] [dbo].[bDesc] NULL,
[VPGLCo] [dbo].[bCompany] NULL
) ON [PRIMARY]
GO
