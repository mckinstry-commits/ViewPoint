CREATE TABLE [dbo].[vVPGridQueryAssociationc]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[TemplateName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Active] [dbo].[bYN] NOT NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryAssociationc_IsStandard] DEFAULT ('N'),
[KeyID] [int] NOT NULL IDENTITY(2, 2)
) ON [PRIMARY]
GO
