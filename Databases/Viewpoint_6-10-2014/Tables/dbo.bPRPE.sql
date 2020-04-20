CREATE TABLE [dbo].[bPRPE]
(
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[PostSeq] [smallint] NOT NULL,
[PostDate] [dbo].[bDate] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[Factor] [dbo].[bRate] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPRPE_Rate] DEFAULT ((0)),
[Amt] [dbo].[bDollar] NOT NULL,
[IncldLiabDist] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRPE_IncldLiabDist] DEFAULT ('Y')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPRPE] WITH NOCHECK ADD CONSTRAINT [CK_bPRPE_IncldLiabDist] CHECK (([IncldLiabDist]='Y' OR [IncldLiabDist]='N'))
GO
CREATE NONCLUSTERED INDEX [biPRPE] ON [dbo].[bPRPE] ([VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
