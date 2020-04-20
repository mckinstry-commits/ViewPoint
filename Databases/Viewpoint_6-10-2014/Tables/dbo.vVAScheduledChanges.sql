CREATE TABLE [dbo].[vVAScheduledChanges]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[FormName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[FieldSequence] [smallint] NOT NULL,
[EffectiveOn] [datetime] NOT NULL,
[KeyIDToUpdate] [bigint] NOT NULL,
[NewValue] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CreatedBy] [dbo].[bVPUserName] NOT NULL,
[CreatedOn] [datetime] NOT NULL,
[AppliedOn] [datetime] NULL,
[UpdateStatus] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[UpdateMessage] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyFields] [varchar] (500) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVAScheduledChanges] ADD CONSTRAINT [PK_vVAScheduledChanges] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vVAScheduledChanges] ON [dbo].[vVAScheduledChanges] ([FormName], [FieldSequence], [EffectiveOn], [KeyIDToUpdate]) INCLUDE ([NewValue]) ON [PRIMARY]
GO
