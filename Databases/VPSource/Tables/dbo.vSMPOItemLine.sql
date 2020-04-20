CREATE TABLE [dbo].[vSMPOItemLine]
(
[POCo] [dbo].[bCompany] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[POItemLine] [int] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[SMCostType] [smallint] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[CostWIPAccount] [dbo].[bGLAcct] NOT NULL,
[CostAccount] [dbo].[bGLAcct] NOT NULL,
[InvTaxBasis] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSMPOItemLine_InvTaxBasis] DEFAULT ((0)),
[InvDirectExpenseTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSMPOItemLine_InvDirectExpenseTax] DEFAULT ((0)),
[InvTotalCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSMPOItemLine_InvTotalCost] DEFAULT ((0))
) ON [PRIMARY]
ALTER TABLE [dbo].[vSMPOItemLine] ADD 
CONSTRAINT [PK_vSMPOItemLine] PRIMARY KEY CLUSTERED  ([POCo], [PO], [POItem], [POItemLine]) ON [PRIMARY]
ALTER TABLE [dbo].[vSMPOItemLine] WITH NOCHECK ADD
CONSTRAINT [FK_vSMPOItemLine_vPOItemLine] FOREIGN KEY ([POCo], [PO], [POItem], [POItemLine]) REFERENCES [dbo].[vPOItemLine] ([POCo], [PO], [POItem], [POItemLine]) ON DELETE CASCADE
GO
