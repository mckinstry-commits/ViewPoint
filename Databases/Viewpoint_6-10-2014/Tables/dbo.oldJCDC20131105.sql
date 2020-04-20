CREATE TABLE [dbo].[oldJCDC20131105]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Department] [dbo].[bDept] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[OpenWIPAcct] [dbo].[bGLAcct] NULL,
[ClosedExpAcct] [dbo].[bGLAcct] NULL
) ON [PRIMARY]
GO
