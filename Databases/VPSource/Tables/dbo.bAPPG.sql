CREATE TABLE [dbo].[bAPPG]
(
[APCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BatchSeq] [int] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMRef] [dbo].[bCMRef] NOT NULL,
[CMRefSeq] [tinyint] NOT NULL,
[EFTSeq] [smallint] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[PaidDate] [dbo].[bDate] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bAPPG] ADD
CONSTRAINT [CK_bAPPG_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000)))
GO
CREATE UNIQUE CLUSTERED INDEX [biAPPG] ON [dbo].[bAPPG] ([APCo], [Mth], [BatchId], [GLCo], [GLAcct], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bAPPG].[CMAcct]'
GO
