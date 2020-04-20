CREATE TABLE [dbo].[vVPGridQueriesc]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[QueryTitle] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[QueryDescription] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[QueryType] [tinyint] NOT NULL CONSTRAINT [DF_vVPGridQueriesc_QueryType] DEFAULT ((0)),
[Query] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueriesc_IsStandard] DEFAULT ('N'),
[KeyID] [int] NOT NULL IDENTITY(2, 2)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPGridQueriesc] ADD CONSTRAINT [PK_vVPGridQueriesc] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vVPGridQueriesc_QueryName] ON [dbo].[vVPGridQueriesc] ([QueryName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
