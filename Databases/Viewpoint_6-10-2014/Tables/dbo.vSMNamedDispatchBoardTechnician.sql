CREATE TABLE [dbo].[vSMNamedDispatchBoardTechnician]
(
[SMCo] [dbo].[bCompany] NOT NULL,
[SMBoardName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Technician] [nvarchar] (15) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMNamedDispatchBoardTechnician] ADD CONSTRAINT [PK_vSMNamedDispatchBoardTechnician] PRIMARY KEY CLUSTERED  ([SMCo], [SMBoardName], [Technician]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMNamedDispatchBoardTechnician] WITH NOCHECK ADD CONSTRAINT [FK_vSMNamedDispatchBoardTechnician_vSMNamedDispatchBoard] FOREIGN KEY ([SMCo], [SMBoardName]) REFERENCES [dbo].[vSMNamedDispatchBoard] ([SMCo], [SMBoardName]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vSMNamedDispatchBoardTechnician] NOCHECK CONSTRAINT [FK_vSMNamedDispatchBoardTechnician_vSMNamedDispatchBoard]
GO
