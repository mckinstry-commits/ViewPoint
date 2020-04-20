CREATE TABLE [dbo].[vSMEntity]
(
[SMEntityID] [bigint] NOT NULL IDENTITY(1, 1),
[Type] [tinyint] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[ServiceSite] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RateTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[EffectiveDate] [dbo].[bDate] NULL,
[EntitySeq] [int] NOT NULL,
[WorkOrderQuote] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[WorkOrderQuoteScope] [int] NULL,
[WorkOrder] [int] NULL,
[WorkOrderScope] [int] NULL,
[StandardItem] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Agreement] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[AgreementRevision] [int] NULL,
[AgreementService] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [CK_vSMEntity_Type] CHECK ((checksum([dbo].[vfEqualsNull]([CustGroup]),[dbo].[vfEqualsNull]([Customer]),[dbo].[vfEqualsNull]([ServiceSite]),[dbo].[vfEqualsNull]([RateTemplate]),[dbo].[vfEqualsNull]([EffectiveDate]),[dbo].[vfEqualsNull]([StandardItem]),[dbo].[vfEqualsNull]([WorkOrder]),[dbo].[vfEqualsNull]([WorkOrderScope]),[dbo].[vfEqualsNull]([Agreement]),[dbo].[vfEqualsNull]([AgreementRevision]),[dbo].[vfEqualsNull]([AgreementService]),[dbo].[vfEqualsNull]([WorkOrderQuote]),[dbo].[vfEqualsNull]([WorkOrderQuoteScope]))=case [Type] when (1) then checksum((0),(0),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) when (2) then checksum((1),(1),(0),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) when (3) then checksum((1),(1),(1),(0),(1),(1),(1),(1),(1),(1),(1),(1),(1)) when (4) then checksum((1),(1),(1),(0),(0),(1),(1),(1),(1),(1),(1),(1),(1)) when (5) then checksum((1),(1),(1),(1),(1),(0),(1),(1),(1),(1),(1),(1),(1)) when (6) then checksum((1),(1),(1),(1),(1),(1),(0),(1),(1),(1),(1),(1),(1)) when (7) then checksum((1),(1),(1),(1),(1),(1),(0),(0),(1),(1),(1),(1),(1)) when (8) then checksum((1),(1),(1),(1),(1),(1),(1),(1),(0),(0),(1),(1),(1)) when (9) then checksum((1),(1),(1),(1),(1),(1),(1),(1),(0),(0),(0),(1),(1)) when (10) then checksum((1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(0),(1)) when (11) then checksum((1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(0),(0))  end))
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [PK_vSMEntity] PRIMARY KEY CLUSTERED  ([SMEntityID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [IX_vSMEntity_UniqueEntity] UNIQUE NONCLUSTERED  ([SMCo], [CustGroup], [Customer], [ServiceSite], [RateTemplate], [EffectiveDate], [StandardItem], [WorkOrder], [WorkOrderScope], [Agreement], [AgreementRevision], [AgreementService], [WorkOrderQuote], [WorkOrderQuoteScope]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [IX_vSMEntity_SMCo_EntitySeq] UNIQUE NONCLUSTERED  ([SMCo], [EntitySeq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMAgreement] FOREIGN KEY ([SMCo], [Agreement], [AgreementRevision]) REFERENCES [dbo].[vSMAgreement] ([SMCo], [Agreement], [Revision])
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMAgreementService] FOREIGN KEY ([SMCo], [Agreement], [AgreementRevision], [AgreementService]) REFERENCES [dbo].[vSMAgreementService] ([SMCo], [Agreement], [Revision], [Service]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMCustomer] FOREIGN KEY ([SMCo], [CustGroup], [Customer]) REFERENCES [dbo].[vSMCustomer] ([SMCo], [CustGroup], [Customer]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMRateTemplate] FOREIGN KEY ([SMCo], [RateTemplate]) REFERENCES [dbo].[vSMRateTemplate] ([SMCo], [RateTemplate]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMRateTemplateEffectiveDate] FOREIGN KEY ([SMCo], [RateTemplate], [EffectiveDate]) REFERENCES [dbo].[vSMRateTemplateEffectiveDate] ([SMCo], [RateTemplate], [EffectiveDate])
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMServiceSite] FOREIGN KEY ([SMCo], [ServiceSite]) REFERENCES [dbo].[vSMServiceSite] ([SMCo], [ServiceSite]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMStandardItem] FOREIGN KEY ([SMCo], [StandardItem]) REFERENCES [dbo].[vSMStandardItem] ([SMCo], [StandardItem]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMWorkOrderScope] FOREIGN KEY ([SMCo], [WorkOrder], [WorkOrderScope]) REFERENCES [dbo].[vSMWorkOrderScope] ([SMCo], [WorkOrder], [Scope])
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMWorkOrderQuote] FOREIGN KEY ([SMCo], [WorkOrderQuote]) REFERENCES [dbo].[vSMWorkOrderQuote] ([SMCo], [WorkOrderQuote])
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMWorkOrderQuoteScope] FOREIGN KEY ([SMCo], [WorkOrderQuote], [WorkOrderQuoteScope]) REFERENCES [dbo].[vSMWorkOrderQuoteScope] ([SMCo], [WorkOrderQuote], [WorkOrderQuoteScope]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMEntity] ADD CONSTRAINT [FK_vSMEntity_vSMWorkOrder] FOREIGN KEY ([WorkOrder], [SMCo]) REFERENCES [dbo].[vSMWorkOrder] ([WorkOrder], [SMCo])
GO
