CREATE TABLE [dbo].[vSMAssociatedCallType]
(
[SMAssociatedCallTypeID] [int] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[ServiceCenter] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Division] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CallType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAssociatedCallType] ADD CONSTRAINT [PK_vSMAssociatedCallType] PRIMARY KEY CLUSTERED  ([SMAssociatedCallTypeID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAssociatedCallType] ADD CONSTRAINT [IX_vSMAssociatedCallType_SMCo_ServiceCenter_Division_CallType] UNIQUE NONCLUSTERED  ([SMCo], [ServiceCenter], [Division], [CallType]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMAssociatedCallType] WITH NOCHECK ADD CONSTRAINT [FK_vSMAssociatedCallType_vSMCallType] FOREIGN KEY ([SMCo], [CallType]) REFERENCES [dbo].[vSMCallType] ([SMCo], [CallType])
GO
ALTER TABLE [dbo].[vSMAssociatedCallType] WITH NOCHECK ADD CONSTRAINT [FK_vSMAssociatedCallType_vSMServiceCenter] FOREIGN KEY ([SMCo], [ServiceCenter]) REFERENCES [dbo].[vSMServiceCenter] ([SMCo], [ServiceCenter]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMAssociatedCallType] WITH NOCHECK ADD CONSTRAINT [FK_vSMAssociatedCallType_vSMDivision] FOREIGN KEY ([SMCo], [ServiceCenter], [Division]) REFERENCES [dbo].[vSMDivision] ([SMCo], [ServiceCenter], [Division]) ON DELETE CASCADE
GO
