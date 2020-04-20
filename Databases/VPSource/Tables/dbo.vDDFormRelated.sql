CREATE TABLE [dbo].[vDDFormRelated]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[RelatedForm] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDFormRelated] ADD CONSTRAINT [PK_vDDFormRelated_1] PRIMARY KEY CLUSTERED  ([Form], [RelatedForm]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDFormRelated] WITH NOCHECK ADD CONSTRAINT [FK_vDDFormRelated_vDDFH_Form] FOREIGN KEY ([Form]) REFERENCES [dbo].[vDDFH] ([Form]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vDDFormRelated] WITH NOCHECK ADD CONSTRAINT [FK_vDDFormRelated_vDDFH_RelatedForm] FOREIGN KEY ([RelatedForm]) REFERENCES [dbo].[vDDFH] ([Form])
GO
