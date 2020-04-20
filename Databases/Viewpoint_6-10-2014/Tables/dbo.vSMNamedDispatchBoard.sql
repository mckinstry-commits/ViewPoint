CREATE TABLE [dbo].[vSMNamedDispatchBoard]
(
[SMNamedDispatchBoardID] [int] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[SMBoardName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Division] [nvarchar] (10) COLLATE Latin1_General_BIN NULL,
[ServiceCenter] [nvarchar] (10) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMNamedDispatchBoard] ADD CONSTRAINT [PK_vSMNamedDispatchBoard] PRIMARY KEY CLUSTERED  ([SMNamedDispatchBoardID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMNamedDispatchBoard] ADD CONSTRAINT [IX_vSMNamedDispatchBoard_SMCo_SMBoardName] UNIQUE NONCLUSTERED  ([SMCo], [SMBoardName]) ON [PRIMARY]
GO
