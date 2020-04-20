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
CREATE UNIQUE CLUSTERED INDEX [biPMOZ] ON [dbo].[bPMOZ] ([UserId], [ContractItem]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMOZ].[Fixed]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMOZ].[Generate]'
GO
