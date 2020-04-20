CREATE TABLE [dbo].[vPRLedgerUpdateMonth]
(
[PRLedgerUpdateMonthID] [bigint] NOT NULL IDENTITY(1, 1),
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[Posted] [bit] NOT NULL CONSTRAINT [DF_vPRLedgerUpdateMonth_vPRLedgerUpdateMonth] DEFAULT ((0)),
[DistributionXML] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRLedgerUpdateMonth] ADD CONSTRAINT [PK_vPRLedgerUpdateMonth] PRIMARY KEY CLUSTERED  ([PRLedgerUpdateMonthID]) ON [PRIMARY]
GO
