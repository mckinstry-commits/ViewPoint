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
ALTER TABLE [dbo].[bPRPE] ADD
CONSTRAINT [CK_bPRPE_IncldLiabDist] CHECK (([IncldLiabDist]='Y' OR [IncldLiabDist]='N'))
GO
CREATE NONCLUSTERED INDEX [biPRPE] ON [dbo].[bPRPE] ([VPUserName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRPE].[Rate]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRPE].[IncldLiabDist]'
GO
