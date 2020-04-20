CREATE TABLE [dbo].[oldPRDP20131105]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRDept] [dbo].[bDept] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[JCFixedRateGLAcct] [dbo].[bGLAcct] NULL,
[EMFixedRateGLAcct] [dbo].[bGLAcct] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
