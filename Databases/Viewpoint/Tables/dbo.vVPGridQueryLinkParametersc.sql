CREATE TABLE [dbo].[vVPGridQueryLinkParametersc]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[RelatedQueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ParameterName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[MatchingColumn] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[UseDefault] [dbo].[bYN] NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryLinkParametersc_IsStandard] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_vVPGridQueryLinkParametersc_QueryName_RelatedQueryName_ParameterName] ON [dbo].[vVPGridQueryLinkParametersc] ([QueryName], [RelatedQueryName], [ParameterName]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
ALTER TABLE [dbo].[vVPGridQueryLinkParametersc] ADD CONSTRAINT [PK_vVPGridQueryLinkParametersc] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
