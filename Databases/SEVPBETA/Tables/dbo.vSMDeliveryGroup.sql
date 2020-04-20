CREATE TABLE [dbo].[vSMDeliveryGroup]
(
[SMDeliveryGroupID] [int] NOT NULL IDENTITY(1, 1),
[SMSessionID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDeliveryGroup] ADD CONSTRAINT [PK_vSMDeliveryGroup] PRIMARY KEY CLUSTERED  ([SMDeliveryGroupID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vSMDeliveryGroup_SMSessionID] ON [dbo].[vSMDeliveryGroup] ([SMSessionID]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDeliveryGroup] WITH NOCHECK ADD CONSTRAINT [FK_vSMDeliveryGroup_vSMSession] FOREIGN KEY ([SMSessionID]) REFERENCES [dbo].[vSMSession] ([SMSessionID]) ON DELETE CASCADE
GO
