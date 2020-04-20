CREATE TABLE [dbo].[bPRDS]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[DistSeq] [tinyint] NOT NULL,
[RoutingId] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[BankAcct] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Amt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPRDS_Amt] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRDS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRDS] ON [dbo].[bPRDS] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq], [DistSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
