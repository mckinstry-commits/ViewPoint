CREATE TABLE [dbo].[oldPRDG20131105]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRDept] [dbo].[bDept] NOT NULL,
[LiabType] [dbo].[bLiabilityType] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[JCAppBurdenGLAcct] [dbo].[bGLAcct] NULL,
[EMAppBurdenGLAcct] [dbo].[bGLAcct] NULL,
[IntercoAppBurdenGLAcct] [dbo].[bGLAcct] NULL,
[SMAppBurdenGLAcct] [dbo].[bGLAcct] NULL
) ON [PRIMARY]
GO
