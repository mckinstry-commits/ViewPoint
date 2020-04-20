CREATE TABLE [dbo].[vDDFIc]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[ViewName] [varchar] (257) COLLATE Latin1_General_BIN NULL,
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
GO
ALTER TABLE [dbo].[vDDFIc] WITH NOCHECK ADD CONSTRAINT [CK_vDDFIc_ActiveLookup] CHECK (([ActiveLookup]='Y' OR [ActiveLookup]='N' OR [ActiveLookup] IS NULL))
GO
ALTER TABLE [dbo].[vDDFIc] WITH NOCHECK ADD CONSTRAINT [CK_vDDFIc_Computed] CHECK (([Computed]='Y' OR [Computed]='N' OR [Computed] IS NULL))
GO
ALTER TABLE [dbo].[vDDFIc] WITH NOCHECK ADD CONSTRAINT [CK_vDDFIc_InputSkip] CHECK (([InputSkip]='Y' OR [InputSkip]='N' OR [InputSkip] IS NULL))
GO
ALTER TABLE [dbo].[vDDFIc] WITH NOCHECK ADD CONSTRAINT [CK_vDDFIc_Req] CHECK (([Req]='Y' OR [Req]='N' OR [Req] IS NULL))
GO
ALTER TABLE [dbo].[vDDFIc] WITH NOCHECK ADD CONSTRAINT [CK_vDDFIc_ShowForm] CHECK (([ShowForm]='Y' OR [ShowForm]='N' OR [ShowForm] IS NULL))
GO
ALTER TABLE [dbo].[vDDFIc] WITH NOCHECK ADD CONSTRAINT [CK_vDDFIc_ShowGrid] CHECK (([ShowGrid]='Y' OR [ShowGrid]='N' OR [ShowGrid] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [viDDFIc] ON [dbo].[vDDFIc] ([Form], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [viDDFIcLookups] ON [dbo].[vDDFIc] ([Form], [Seq], [LookupLoadSeq]) INCLUDE ([ActiveLookup], [Datatype], [LookupParams]) ON [PRIMARY]
GO
