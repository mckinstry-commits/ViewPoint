CREATE TABLE [dbo].[vWFProcessDetailStepHistory]
(
[Action] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[DateTime] [datetime] NOT NULL,
[ProcessDetailID] [bigint] NOT NULL,
[Step] [int] NOT NULL,
[FieldName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL,
[HistoryKeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFProcessDetailStepHistory] ADD CONSTRAINT [PK_vWFProcessDetailStepHistory] PRIMARY KEY NONCLUSTERED  ([HistoryKeyID]) ON [PRIMARY]
GO
