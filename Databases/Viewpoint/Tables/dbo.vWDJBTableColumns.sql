CREATE TABLE [dbo].[vWDJBTableColumns]
(
[JobName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[ColumnName] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[Seq] [int] NULL,
[Include] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWDJBTableColumns_Include] DEFAULT ('Y'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_vWDJBTableColumns_JobName_ColumnName] ON [dbo].[vWDJBTableColumns] ([JobName], [ColumnName]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
ALTER TABLE [dbo].[vWDJBTableColumns] ADD CONSTRAINT [PK_vWDJBTableColumns] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
