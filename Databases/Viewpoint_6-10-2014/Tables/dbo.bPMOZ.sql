CREATE TABLE [dbo].[bPMOZ]
(
[UserId] [dbo].[bVPUserName] NOT NULL,
[ContractItem] [dbo].[bContractItem] NOT NULL,
[PMCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[COItem] [dbo].[bPCOItem] NULL,
[OrigUnits] [dbo].[bUnits] NOT NULL,
[OrigAmt] [dbo].[bDollar] NOT NULL,
[CurrUnits] [dbo].[bDollar] NOT NULL,
[CurrAmt] [dbo].[bDollar] NOT NULL,
[CurrBillAmt] [dbo].[bDollar] NOT NULL,
[CurrBillUnits] [dbo].[bDollar] NOT NULL,
[ProjUnits] [dbo].[bUnits] NOT NULL,
[AddlUnits] [dbo].[bUnits] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[JBITBillAmt] [dbo].[bDollar] NOT NULL,
[JBITBillUnits] [dbo].[bUnits] NOT NULL,
[Fixed] [dbo].[bYN] NOT NULL,
[Generate] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMOZ] WITH NOCHECK ADD CONSTRAINT [CK_bPMOZ_Fixed] CHECK (([Fixed]='Y' OR [Fixed]='N'))
GO
ALTER TABLE [dbo].[bPMOZ] WITH NOCHECK ADD CONSTRAINT [CK_bPMOZ_Generate] CHECK (([Generate]='Y' OR [Generate]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biPMOZ] ON [dbo].[bPMOZ] ([UserId], [ContractItem]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
