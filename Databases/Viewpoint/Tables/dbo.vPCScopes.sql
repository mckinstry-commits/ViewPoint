CREATE TABLE [dbo].[vPCScopes]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Seq] [tinyint] NOT NULL,
[PhaseCode] [dbo].[bPhase] NULL,
[ScopeCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SelfPerformed] [dbo].[bYN] NULL,
[WorkPrevious] [dbo].[bPct] NULL,
[WorkNext] [dbo].[bPct] NULL,
[NoPriorWork] [dbo].[bYN] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[PhaseGroup] [dbo].[bGroup] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCScopes] ADD CONSTRAINT [PK_vPCScopes] PRIMARY KEY CLUSTERED  ([VendorGroup], [Vendor], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCScopes] WITH NOCHECK ADD CONSTRAINT [FK_vPCScopes_vPCScopeCodes] FOREIGN KEY ([VendorGroup], [ScopeCode]) REFERENCES [dbo].[vPCScopeCodes] ([VendorGroup], [ScopeCode])
GO
