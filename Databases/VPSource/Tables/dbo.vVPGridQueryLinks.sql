CREATE TABLE [dbo].[vVPGridQueryLinks]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[RelatedQueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DisplaySeq] [tinyint] NULL,
[DefaultDrillThrough] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryLinks_DefaultDrillThrough] DEFAULT ('N'),
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryLinks_IsStandard] DEFAULT ('Y'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[LinksConfigured] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPGridQueryLinks] ADD CONSTRAINT [PK_vVPGridQueryLinks] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vVPGridQueryLinks_QueryName_RelatedQueryName] ON [dbo].[vVPGridQueryLinks] ([QueryName], [RelatedQueryName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
