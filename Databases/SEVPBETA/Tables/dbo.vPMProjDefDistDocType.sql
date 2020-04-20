CREATE TABLE [dbo].[vPMProjDefDistDocType]
(
[DefaultKeyID] [bigint] NOT NULL,
[DocType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMProjDefDistDocType] ADD CONSTRAINT [PK_vPMProjDefDistDocType] PRIMARY KEY CLUSTERED  ([DefaultKeyID], [DocType]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMProjDefDistDocType] WITH NOCHECK ADD CONSTRAINT [FK_vPMProjDefDistDocType_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
