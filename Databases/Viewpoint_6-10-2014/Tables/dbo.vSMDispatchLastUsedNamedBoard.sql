CREATE TABLE [dbo].[vSMDispatchLastUsedNamedBoard]
(
[SMCo] [dbo].[bCompany] NOT NULL,
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[SMBoardName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDispatchLastUsedNamedBoard] ADD CONSTRAINT [IX_SMDispatchLastUsedNamedBoard] UNIQUE NONCLUSTERED  ([SMCo], [VPUserName]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDispatchLastUsedNamedBoard] WITH NOCHECK ADD CONSTRAINT [FK_vSMDispatchLastUsedNamedBoard_vSMNamedDispatchBoard] FOREIGN KEY ([SMCo], [SMBoardName]) REFERENCES [dbo].[vSMNamedDispatchBoard] ([SMCo], [SMBoardName]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMDispatchLastUsedNamedBoard] NOCHECK CONSTRAINT [FK_vSMDispatchLastUsedNamedBoard_vSMNamedDispatchBoard]
GO
