CREATE TABLE [dbo].[vSMAgreementRevenueDeferral]
(
[SMAgreementRevenueDeferralID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Revision] [int] NOT NULL,
[Service] [int] NULL,
[Deferral] [int] NOT NULL,
[Date] [dbo].[bDate] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementRevenueDeferral] ADD CONSTRAINT [PK_vSMAgreementRevenueDeferral] PRIMARY KEY CLUSTERED  ([SMAgreementRevenueDeferralID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementRevenueDeferral] ADD CONSTRAINT [IX_vSMAgreementRevenueDeferral] UNIQUE NONCLUSTERED  ([SMCo], [Agreement], [Revision], [Service], [Deferral]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementRevenueDeferral] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementRevenueDeferral_vSMAgreement] FOREIGN KEY ([SMCo], [Agreement], [Revision]) REFERENCES [dbo].[vSMAgreement] ([SMCo], [Agreement], [Revision])
GO
ALTER TABLE [dbo].[vSMAgreementRevenueDeferral] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementRevDefRef_vSMAgreementService] FOREIGN KEY ([SMCo], [Agreement], [Revision], [Service]) REFERENCES [dbo].[vSMAgreementService] ([SMCo], [Agreement], [Revision], [Service]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMAgreementRevenueDeferral] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementRevenueDeferral_vSMAgreementService] FOREIGN KEY ([SMCo], [Agreement], [Revision], [Service]) REFERENCES [dbo].[vSMAgreementService] ([SMCo], [Agreement], [Revision], [Service])
GO
ALTER TABLE [dbo].[vSMAgreementRevenueDeferral] NOCHECK CONSTRAINT [FK_vSMAgreementRevenueDeferral_vSMAgreement]
GO
ALTER TABLE [dbo].[vSMAgreementRevenueDeferral] NOCHECK CONSTRAINT [FK_vSMAgreementRevDefRef_vSMAgreementService]
GO
ALTER TABLE [dbo].[vSMAgreementRevenueDeferral] NOCHECK CONSTRAINT [FK_vSMAgreementRevenueDeferral_vSMAgreementService]
GO
