CREATE TABLE [dbo].[vPOItemLineDistribution]
(
[HQBatchDistributionID] [bigint] NOT NULL,
[Posted] [bit] NOT NULL CONSTRAINT [DF_vPOItemLineDistribution_Posted] DEFAULT ((0)),
[POCo] [dbo].[bCompany] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[POItemLine] [int] NOT NULL,
[InvUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vPOItemLineDistribution_InvUnits] DEFAULT ((0)),
[InvCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLineDistribution_InvCost] DEFAULT ((0)),
[InvTaxBasis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLineDistribution_InvTaxBasis] DEFAULT ((0)),
[InvDirectExpenseTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLineDistribution_InvDirectExpenseTax] DEFAULT ((0)),
[InvTotalCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPOItemLineDistribution_InvTotalCost] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPOItemLineDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPOItemLineDistribution_vHQBatchDistribution] FOREIGN KEY ([HQBatchDistributionID], [Posted]) REFERENCES [dbo].[vHQBatchDistribution] ([HQBatchDistributionID], [Posted]) ON DELETE CASCADE
GO
