CREATE TABLE [dbo].[vVPGridQueryAssociation]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryAssociation_IsStandard] DEFAULT ('Y'),
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryAssociation_Active] DEFAULT ('Y'),
[KeyID] [int] NOT NULL IDENTITY(1, 2)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPGridQueryAssociation] ADD CONSTRAINT [PK_vVPGridQueryAssociation] PRIMARY KEY CLUSTERED  ([QueryName], [TemplateName]) ON [PRIMARY]
GO
