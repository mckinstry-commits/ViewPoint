CREATE TABLE [dbo].[vBITargetLevel]
(
[TargetLevel] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vBITargetLevel] ADD CONSTRAINT [PK_vBITargetLevel] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vBITargetLevel_TargetLevel] ON [dbo].[vBITargetLevel] ([TargetLevel]) ON [PRIMARY]
GO
