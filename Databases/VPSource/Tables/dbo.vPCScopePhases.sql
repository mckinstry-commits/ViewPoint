CREATE TABLE [dbo].[vPCScopePhases]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[ScopeCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPCScopePhases] ADD CONSTRAINT [PK_vPCScopePhases] PRIMARY KEY CLUSTERED  ([VendorGroup], [ScopeCode], [PhaseGroup], [Phase]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[vPCScopePhases] WITH NOCHECK ADD CONSTRAINT [FK_vPCScopePhases_vPCScopeCodes] FOREIGN KEY ([VendorGroup], [ScopeCode]) REFERENCES [dbo].[vPCScopeCodes] ([VendorGroup], [ScopeCode])
GO
