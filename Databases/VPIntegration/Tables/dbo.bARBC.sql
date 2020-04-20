CREATE TABLE [dbo].[bARBC]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[CMDeposit] [dbo].[bCMRef] NOT NULL,
[OldNew] [tinyint] NOT NULL,
[ActualDate] [dbo].[bDate] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biARBC] ON [dbo].[bARBC] ([ARCo], [Mth], [BatchId], [CMCo], [CMAcct], [CMDeposit], [OldNew]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bARBC].[CMAcct]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBC].[Amount]'
GO
