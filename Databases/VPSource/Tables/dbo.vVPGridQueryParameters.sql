CREATE TABLE [dbo].[vVPGridQueryParameters]
(
[QueryName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NULL,
[ColumnName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ParameterName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Comparison] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Value] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Operator] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DataType] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[IsVisible] [dbo].[bYN] NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DefaultType] [tinyint] NULL,
[DefaultOrder] [int] NULL,
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryParameters_IsStandard] DEFAULT ('Y'),
[InputLength] [smallint] NULL,
[InputType] [tinyint] NULL,
[Prec] [tinyint] NULL,
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPGridQueryParameters] ADD CONSTRAINT [PK_vVPGridQueryParameters] PRIMARY KEY CLUSTERED  ([QueryName], [ParameterName]) ON [PRIMARY]
GO
