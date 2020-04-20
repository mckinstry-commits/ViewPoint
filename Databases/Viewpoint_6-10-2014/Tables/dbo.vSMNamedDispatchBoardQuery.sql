CREATE TABLE [dbo].[vSMNamedDispatchBoardQuery]
(
[SMCo] [dbo].[bCompany] NOT NULL,
[SMBoardName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMNamedDispatchBoardQuery] ADD CONSTRAINT [PK_vSMNamedDispatchBoardQuery] PRIMARY KEY CLUSTERED  ([SMCo], [SMBoardName], [QueryName]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMNamedDispatchBoardQuery] WITH NOCHECK ADD CONSTRAINT [FK_vSMNamedDispatchBoardQuery_vSMNamedDispatchBoard] FOREIGN KEY ([SMCo], [SMBoardName]) REFERENCES [dbo].[vSMNamedDispatchBoard] ([SMCo], [SMBoardName]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMNamedDispatchBoardQuery] NOCHECK CONSTRAINT [FK_vSMNamedDispatchBoardQuery_vSMNamedDispatchBoard]
GO
