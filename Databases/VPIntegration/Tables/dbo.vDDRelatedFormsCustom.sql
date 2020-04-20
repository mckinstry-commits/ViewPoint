CREATE TABLE [dbo].[vDDRelatedFormsCustom]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Tab] [tinyint] NOT NULL,
[GridKeySeq] [int] NOT NULL,
[ParentFieldSeq] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDRelatedFormsCustom] ADD CONSTRAINT [PK_vDDRelatedFormsCustom] PRIMARY KEY CLUSTERED  ([Form], [Tab], [GridKeySeq]) ON [PRIMARY]
GO
