CREATE TABLE [dbo].[bPRAP]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[APFields] [char] (6) COLLATE Latin1_General_BIN NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL,
[Description] [dbo].[bDesc] NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRAP] ON [dbo].[bPRAP] ([PRCo], [PRGroup], [PREndDate], [Mth], [VendorGroup], [Vendor], [EDLType], [EDLCode], [APFields]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
