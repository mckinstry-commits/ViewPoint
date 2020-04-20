CREATE TABLE [dbo].[vDDFIc]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[ViewName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ColumnName] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputType] [tinyint] NULL,
[InputMask] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InputLength] [smallint] NULL,
[Prec] [tinyint] NULL,
[ActiveLookup] [dbo].[bYN] NULL,
[LookupParams] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[LookupLoadSeq] [tinyint] NULL,
[SetupForm] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SetupParams] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[StatusText] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[Tab] [tinyint] NULL,
[TabIndex] [smallint] NULL,
[Req] [dbo].[bYN] NULL,
[ValProc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ValParams] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[ValLevel] [tinyint] NULL,
[UpdateGroup] [tinyint] NULL,
[ControlType] [tinyint] NULL,
[ControlPosition] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[FieldType] [tinyint] NULL,
[DefaultType] [tinyint] NULL,
[DefaultValue] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[InputSkip] [dbo].[bYN] NULL,
[Label] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ShowGrid] [dbo].[bYN] NULL,
[ShowForm] [dbo].[bYN] NULL,
[GridCol] [smallint] NULL,
[AutoSeqType] [tinyint] NULL,
[MinValue] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[MaxValue] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ValExpression] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[ValExpError] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[ComboType] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[GridColHeading] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[HeaderLinkSeq] [smallint] NULL,
[CustomControlSize] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Computed] [dbo].[bYN] NULL,
[ShowDesc] [tinyint] NULL,
[ColWidth] [smallint] NULL,
[DescriptionColWidth] [smallint] NULL,
[IsFormFilter] [dbo].[bYN] NULL,
[ExcludeFromAggregation] [dbo].[bYN] NULL CONSTRAINT [DF_vDDFIc_ExcludeFromAggregation] DEFAULT ('N')
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [viDDFIc] ON [dbo].[vDDFIc] ([Form], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO

CREATE NONCLUSTERED INDEX [viDDFIcLookups] ON [dbo].[vDDFIc] ([Form], [Seq], [LookupLoadSeq]) INCLUDE ([ActiveLookup], [Datatype], [LookupParams]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFIc].[ActiveLookup]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFIc].[Req]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFIc].[InputSkip]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFIc].[ShowGrid]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFIc].[ShowForm]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFIc].[Computed]'
GO
