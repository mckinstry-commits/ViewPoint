CREATE TABLE [dbo].[vSMDeliveryGroupInvoice]
(
[SMDeliveryGroupInvoiceID] [int] NOT NULL IDENTITY(1, 1),
[SMDeliveryGroupID] [int] NOT NULL,
[SMInvoiceID] [bigint] NOT NULL,
[SMDeliveryReportID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDeliveryGroupInvoice] ADD CONSTRAINT [PK_vSMDeliveryGroupInvoice] PRIMARY KEY CLUSTERED  ([SMDeliveryGroupInvoiceID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDeliveryGroupInvoice] ADD CONSTRAINT [IX_vSMDeliveryGroupInvoice] UNIQUE NONCLUSTERED  ([SMDeliveryGroupID], [SMInvoiceID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDeliveryGroupInvoice] WITH NOCHECK ADD CONSTRAINT [FK_vSMDeliveryGroupInvoice_vSMDeliveryGroup] FOREIGN KEY ([SMDeliveryGroupID]) REFERENCES [dbo].[vSMDeliveryGroup] ([SMDeliveryGroupID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMDeliveryGroupInvoice] WITH NOCHECK ADD CONSTRAINT [FK_vSMDeliveryGroupInvoice_vSMDeliveryReport] FOREIGN KEY ([SMDeliveryReportID]) REFERENCES [dbo].[vSMDeliveryReport] ([SMDeliveryReportID])
GO
ALTER TABLE [dbo].[vSMDeliveryGroupInvoice] WITH NOCHECK ADD CONSTRAINT [FK_vSMDeliveryGroupInvoice_vSMInvoice] FOREIGN KEY ([SMInvoiceID]) REFERENCES [dbo].[vSMInvoice] ([SMInvoiceID]) ON DELETE CASCADE
GO
