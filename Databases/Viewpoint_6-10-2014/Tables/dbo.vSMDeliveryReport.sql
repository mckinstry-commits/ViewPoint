CREATE TABLE [dbo].[vSMDeliveryReport]
(
[SMDeliveryReportID] [int] NOT NULL IDENTITY(1, 1),
[SMDeliveryGroupID] [int] NOT NULL,
[ReportID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDeliveryReport] ADD CONSTRAINT [PK_vSMDeliveryReport] PRIMARY KEY CLUSTERED  ([SMDeliveryReportID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDeliveryReport] WITH NOCHECK ADD CONSTRAINT [FK_vSMDeliveryReport_vSMDeliveryGroup] FOREIGN KEY ([SMDeliveryGroupID]) REFERENCES [dbo].[vSMDeliveryGroup] ([SMDeliveryGroupID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMDeliveryReport] NOCHECK CONSTRAINT [FK_vSMDeliveryReport_vSMDeliveryGroup]
GO
