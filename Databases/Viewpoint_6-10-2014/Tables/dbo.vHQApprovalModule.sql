CREATE TABLE [dbo].[vHQApprovalModule]
(
[Mod] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[FormClassName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQApprovalModule] ADD CONSTRAINT [PK_vHQApprovalModule] PRIMARY KEY CLUSTERED  ([Mod]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQApprovalModule] WITH NOCHECK ADD CONSTRAINT [FK_vHQApprovalModule_vDDMO] FOREIGN KEY ([Mod]) REFERENCES [dbo].[vDDMO] ([Mod])
GO
ALTER TABLE [dbo].[vHQApprovalModule] NOCHECK CONSTRAINT [FK_vHQApprovalModule_vDDMO]
GO
