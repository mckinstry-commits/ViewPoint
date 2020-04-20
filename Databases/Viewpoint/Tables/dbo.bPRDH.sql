CREATE TABLE [dbo].[bPRDH]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMRef] [dbo].[bCMRef] NOT NULL,
[CMRefSeq] [tinyint] NOT NULL,
[EFTSeq] [smallint] NOT NULL,
[DistSeq] [tinyint] NOT NULL,
[RoutingId] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[BankAcct] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRDH] ON [dbo].[bPRDH] ([PRCo], [CMCo], [CMAcct], [PayMethod], [CMRef], [CMRefSeq], [EFTSeq], [DistSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bPRDH].[CMAcct]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRDH].[Amt]'
GO
