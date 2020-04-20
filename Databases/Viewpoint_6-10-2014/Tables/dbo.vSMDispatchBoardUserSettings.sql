CREATE TABLE [dbo].[vSMDispatchBoardUserSettings]
(
[SMDispatchBoardUserSettingsID] [int] NOT NULL IDENTITY(1, 1),
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[SMCo] [dbo].[bCompany] NOT NULL,
[SMBoardName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[UserSettingsData] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDispatchBoardUserSettings] ADD CONSTRAINT [PK_vSMDispatchBoardUserSettings] PRIMARY KEY CLUSTERED  ([SMDispatchBoardUserSettingsID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDispatchBoardUserSettings] ADD CONSTRAINT [IX_vSMDispatchBoardUserSettings_SMCo_SMBoardName_VPUserName] UNIQUE NONCLUSTERED  ([SMCo], [SMBoardName], [VPUserName]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMDispatchBoardUserSettings] WITH NOCHECK ADD CONSTRAINT [FK_vSMDispatchBoardUserSettings_vSMNamedDispatchBoard] FOREIGN KEY ([SMCo], [SMBoardName]) REFERENCES [dbo].[vSMNamedDispatchBoard] ([SMCo], [SMBoardName]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMDispatchBoardUserSettings] NOCHECK CONSTRAINT [FK_vSMDispatchBoardUserSettings_vSMNamedDispatchBoard]
GO
