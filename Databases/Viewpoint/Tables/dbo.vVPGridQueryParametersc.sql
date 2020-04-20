CREATE TABLE [dbo].[vVPGridQueryParametersc]
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
[IsStandard] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vVPGridQueryParametersc_IsStandard] DEFAULT ('N'),
[InputLength] [smallint] NULL,
[InputType] [tinyint] NULL,
[Prec] [tinyint] NULL,
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
