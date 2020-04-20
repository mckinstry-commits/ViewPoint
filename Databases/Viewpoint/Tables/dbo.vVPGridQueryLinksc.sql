CREATE TABLE [dbo].[vVPGridQueryLinksc]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[RelatedQueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DisplaySeq] [tinyint] NULL,
[DefaultDrillThrough] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryLinksc_DefaultDrillThrough] DEFAULT ('N'),
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryLinksc_IsStandard] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[LinksConfigured] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_vVPGridQueryLinksc_QueryName_RelatedQueryName] ON [dbo].[vVPGridQueryLinksc] ([QueryName], [RelatedQueryName]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
ALTER TABLE [dbo].[vVPGridQueryLinksc] ADD CONSTRAINT [PK_vVPGridQueryLinksc] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
