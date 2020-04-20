CREATE TABLE [dbo].[bPRVP]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMRef] [dbo].[bCMRef] NOT NULL,
[CMRefSeq] [tinyint] NOT NULL,
[EFTSeq] [smallint] NOT NULL,
[ChkType] [char] (1) COLLATE Latin1_General_BIN NULL,
[PaidDate] [dbo].[bDate] NOT NULL,
[PaidMth] [dbo].[bMonth] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaidAmt] [dbo].[bDollar] NOT NULL,
[VoidMemo] [dbo].[bDesc] NULL,
[Reuse] [dbo].[bYN] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Earnings] [dbo].[bDollar] NOT NULL,
[Dedns] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPRVP] WITH NOCHECK ADD CONSTRAINT [CK_bPRVP_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000)))
GO
ALTER TABLE [dbo].[bPRVP] WITH NOCHECK ADD CONSTRAINT [CK_bPRVP_Reuse] CHECK (([Reuse]='Y' OR [Reuse]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biPRVP] ON [dbo].[bPRVP] ([PRCo], [PRGroup], [PREndDate], [CMCo], [CMAcct], [PayMethod], [CMRef], [CMRefSeq], [EFTSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
