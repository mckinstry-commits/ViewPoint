CREATE TABLE [dbo].[bRQVR]
(
[RQCo] [dbo].[bCompany] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Quote] [int] NOT NULL,
[QuoteLine] [int] NOT NULL,
[Vendor_Group] [dbo].[bGroup] NOT NULL,
[ExpDate] [dbo].[bDate] NULL,
[ReqDate] [dbo].[bDate] NULL,
[VendorMatlId] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bRQVR] ADD
CONSTRAINT [CK_bRQVR_ECM] CHECK (([ECM]='E' OR [ECM]='C' OR [ECM]='M'))
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bRQVR].[ECM]'
GO
