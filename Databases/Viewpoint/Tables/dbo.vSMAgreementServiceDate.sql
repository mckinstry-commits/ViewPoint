CREATE TABLE [dbo].[vSMAgreementServiceDate]
(
[SMAgreementServiceDateID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Revision] [int] NOT NULL,
[Service] [int] NOT NULL,
[ServiceDate] [dbo].[bDate] NOT NULL,
[WorkOrder] [int] NULL,
[Scope] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementServiceDate] ADD CONSTRAINT [PK_vSMAgreementServiceDate] PRIMARY KEY CLUSTERED  ([SMAgreementServiceDateID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementServiceDate] ADD CONSTRAINT [IX_vSMAgreementServiceDate] UNIQUE NONCLUSTERED  ([SMCo], [Agreement], [Revision], [Service], [ServiceDate]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAgreementServiceDate] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementServiceDate_vSMAgreementService] FOREIGN KEY ([SMCo], [Agreement], [Revision], [Service]) REFERENCES [dbo].[vSMAgreementService] ([SMCo], [Agreement], [Revision], [Service])
GO
ALTER TABLE [dbo].[vSMAgreementServiceDate] WITH NOCHECK ADD CONSTRAINT [FK_vSMAgreementServiceDate_vSMWorkOrderScope] FOREIGN KEY ([SMCo], [WorkOrder], [Scope], [Agreement], [Revision], [Service]) REFERENCES [dbo].[vSMWorkOrderScope] ([SMCo], [WorkOrder], [Scope], [Agreement], [Revision], [Service])
GO
