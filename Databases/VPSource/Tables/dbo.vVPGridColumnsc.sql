CREATE TABLE [dbo].[vVPGridColumnsc]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ColumnName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[DefaultOrder] [int] NOT NULL,
[VisibleOnGrid] [dbo].[bYN] NOT NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridColumnsc_IsStandard] DEFAULT ('N'),
[KeyID] [int] NOT NULL IDENTITY(2, 2),
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ExcludeFromAggregation] [dbo].[bYN] NULL CONSTRAINT [DF_vVPGridColumnsc_ExcludeFromAggregation] DEFAULT ('N'),
[ExcludeFromQuery] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridColumnsc_ExcludeFromQuery] DEFAULT ('N'),
[IsNotifierKeyField] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridColumnsc_IsNotifierKeyField] DEFAULT ('N')
) ON [PRIMARY]
GO
