CREATE TABLE [dbo].[vHQDocTemplateResponseField]
(
[TemplateName] [dbo].[bReportTitle] NOT NULL,
[Seq] [int] NOT NULL,
[DocObject] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ColumnName] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[ResponseFieldName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Caption] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[ControlType] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ResponseValues] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Bookmark] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ResponseOrder] [smallint] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Visible] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPMDocTemplateResponseField_Visible] DEFAULT ('Y'),
[ReadOnly] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vPMDocTemplateResponseField_ReadOnly] DEFAULT ('N')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQDocTemplateResponseField] ADD CONSTRAINT [PK_vHQDocTemplateResponseField] PRIMARY KEY CLUSTERED  ([TemplateName], [Seq]) ON [PRIMARY]
GO
