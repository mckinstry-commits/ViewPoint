CREATE TABLE [dbo].[bAPT5]
(
[APCo] [dbo].[bCompany] NOT NULL,
[PeriodEndDate] [smalldatetime] NOT NULL,
[VendorGroup] [tinyint] NOT NULL,
[Vendor] [int] NOT NULL,
[OrigReportDate] [smalldatetime] NULL,
[OrigAmount] [money] NULL,
[ReportDate] [smalldatetime] NULL,
[Amount] [money] NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[RefilingYN] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bAPT5_RefilingYN] DEFAULT ('N')
) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPT5] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
ALTER TABLE [dbo].[bAPT5] ADD CONSTRAINT [PK_bAPT5] PRIMARY KEY CLUSTERED  ([APCo], [PeriodEndDate], [VendorGroup], [Vendor]) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_bAPT5] ON [dbo].[bAPT5] ([PeriodEndDate]) ON [PRIMARY]
GO
