CREATE TABLE [dbo].[bPMUX]
(
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[XrefType] [tinyint] NOT NULL,
[XrefCode] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[UM] [dbo].[bUM] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[PhaseGroup] [tinyint] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[CostOnly] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUX_CostOnly] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bPMUX] ADD
CONSTRAINT [CK_bPMUX_CostOnly] CHECK (([CostOnly]='Y' OR [CostOnly]='N'))
GO
ALTER TABLE [dbo].[bPMUX] WITH NOCHECK ADD CONSTRAINT [CK_bPMUX_XrefType] CHECK (([XrefType]=(4) OR [XrefType]=(3) OR [XrefType]=(2) OR [XrefType]=(1) OR [XrefType]=(0)))
GO
ALTER TABLE [dbo].[bPMUX] ADD CONSTRAINT [PK_bPMUX] PRIMARY KEY CLUSTERED  ([Template], [XrefType], [XrefCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMUX] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMUX] WITH NOCHECK ADD CONSTRAINT [FK_bPMUX_bPMUT] FOREIGN KEY ([Template]) REFERENCES [dbo].[bPMUT] ([Template]) ON DELETE CASCADE
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMUX].[CostOnly]'
GO
