CREATE TABLE [dbo].[oldPRDE20131105]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRDept] [dbo].[bDept] NOT NULL,
[EarnType] [dbo].[bEarnType] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[JCAppEarnGLAcct] [dbo].[bGLAcct] NULL,
[EMAppEarnGLAcct] [dbo].[bGLAcct] NULL,
[IntercoAppEarnGLAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SMAppEarnGLAcct] [dbo].[bGLAcct] NULL
) ON [PRIMARY]
GO
