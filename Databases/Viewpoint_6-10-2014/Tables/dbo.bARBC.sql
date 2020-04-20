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
[Amount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bARBC_Amount] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bARBC] WITH NOCHECK ADD CONSTRAINT [CK_bARBC_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000)))
GO
CREATE UNIQUE CLUSTERED INDEX [biARBC] ON [dbo].[bARBC] ([ARCo], [Mth], [BatchId], [CMCo], [CMAcct], [CMDeposit], [OldNew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
