CREATE TABLE [dbo].[vVPGridQueryLinkParameters]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[RelatedQueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ParameterName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[MatchingColumn] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[UseDefault] [dbo].[bYN] NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryLinkParameters_IsStandard] DEFAULT ('Y'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_vVPGridQueryLinkParameters_QueryName_RelatedQueryName_ParameterName] ON [dbo].[vVPGridQueryLinkParameters] ([QueryName], [RelatedQueryName], [ParameterName]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
ALTER TABLE [dbo].[vVPGridQueryLinkParameters] ADD CONSTRAINT [PK_vVPGridQueryLinkParameters] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
