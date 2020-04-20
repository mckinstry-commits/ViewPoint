CREATE TABLE [dbo].[bPMCT]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DocCat] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMCT] ADD CONSTRAINT [PK_bPMCT] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bPMCT_DocCat] ON [dbo].[bPMCT] ([DocCat]) ON [PRIMARY]
GO
