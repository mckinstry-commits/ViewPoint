CREATE TABLE [dbo].[vVPGridColumns]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ColumnName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[DefaultOrder] [int] NOT NULL,
[VisibleOnGrid] [dbo].[bYN] NOT NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridColumns_IsStandard] DEFAULT ('Y'),
[KeyID] [int] NOT NULL IDENTITY(1, 2),
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ExcludeFromAggregation] [dbo].[bYN] NULL CONSTRAINT [DF_vVPGridColumns_ExcludeFromAggregation] DEFAULT ('N'),
[ExcludeFromQuery] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridColumns_ExcludeFromQuery] DEFAULT ('N'),
[IsNotifierKeyField] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridColumns_IsNotifierKeyField] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPGridColumns] ADD CONSTRAINT [PK_vVPGridColumns] PRIMARY KEY CLUSTERED  ([QueryName], [ColumnName]) ON [PRIMARY]
GO
