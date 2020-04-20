CREATE TABLE [dbo].[vVPGridQueries]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[QueryTitle] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[QueryDescription] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[QueryType] [tinyint] NOT NULL CONSTRAINT [DF_vVPGridQueries_QueryType] DEFAULT ((0)),
[Query] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueries_IsStandard] DEFAULT ('Y'),
[KeyID] [int] NOT NULL IDENTITY(1, 2)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPGridQueries] ADD CONSTRAINT [PK_vVPGridQueries] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vVPGridQueries_QueryName] ON [dbo].[vVPGridQueries] ([QueryName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
