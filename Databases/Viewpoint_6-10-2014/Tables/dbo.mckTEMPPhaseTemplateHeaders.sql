CREATE TABLE [dbo].[mckTEMPPhaseTemplateHeaders]
(
[ImportColumn] [nchar] (10) COLLATE Latin1_General_BIN NULL,
[PhaseTemplateName] [nvarchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Use to identify C1 - C24 in mckTEMPPhaseTemplateLoad', 'SCHEMA', N'dbo', 'TABLE', N'mckTEMPPhaseTemplateHeaders', 'COLUMN', N'ImportColumn'
GO
