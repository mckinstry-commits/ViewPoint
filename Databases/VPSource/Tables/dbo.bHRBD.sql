CREATE TABLE [dbo].[bHRBD]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[EmplBasedYN] [dbo].[bYN] NOT NULL,
[Frequency] [dbo].[bFreq] NULL,
[ProcessSeq] [tinyint] NULL,
[OverrideCalc] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[RateAmt] [dbo].[bUnitCost] NOT NULL,
[GLCo] [dbo].[bCompany] NULL,
[OverrideGLAcct] [dbo].[bGLAcct] NULL,
[OverrideLimit] [dbo].[bDollar] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[APTransDesc] [dbo].[bDesc] NULL,
[AutoEarnSeq] [int] NULL,
[Department] [dbo].[bDept] NULL,
[InsCode] [dbo].[bInsCode] NULL,
[AnnualLimit] [dbo].[bDollar] NOT NULL,
[PaySeq] [tinyint] NULL,
[BatchTransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[StdHours] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRBD_StdHours] DEFAULT ('N'),
[Hours] [dbo].[bHrs] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bHRBD] ADD
CONSTRAINT [CK_bHRBD_EmplBasedYN] CHECK (([EmplBasedYN]='Y' OR [EmplBasedYN]='N'))
ALTER TABLE [dbo].[bHRBD] ADD
CONSTRAINT [CK_bHRBD_StdHours] CHECK (([StdHours]='Y' OR [StdHours]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biHRBD] ON [dbo].[bHRBD] ([Co], [Mth], [BatchId], [BatchSeq], [EDLType], [EDLCode], [AutoEarnSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRBD].[EmplBasedYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRBD].[StdHours]'
GO
