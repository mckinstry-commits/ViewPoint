CREATE TABLE [dbo].[vHQResponseValue]
(
[ValueCode] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQResponseValue] ADD CONSTRAINT [PK_vHQResponseValue] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vHQResponseValue_ValueCode] ON [dbo].[vHQResponseValue] ([ValueCode]) ON [PRIMARY]
GO
