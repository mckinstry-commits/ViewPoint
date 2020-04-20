CREATE TABLE [dbo].[vWFProcessDetailHistory]
(
[Action] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[DateTime] [datetime] NOT NULL,
[HeaderID] [bigint] NOT NULL,
[ProcessID] [bigint] NOT NULL,
[SourceView] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[SourceKeyID] [bigint] NOT NULL,
[CurrentStepID] [bigint] NULL,
[InitiatedBy] [dbo].[bVPUserName] NOT NULL,
[CreatedOn] [dbo].[bDate] NOT NULL,
[SourceDescription] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[FieldName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL,
[HistoryKeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFProcessDetailHistory] ADD CONSTRAINT [PK_vWFDetailHistory] PRIMARY KEY NONCLUSTERED  ([HistoryKeyID]) ON [PRIMARY]
GO
