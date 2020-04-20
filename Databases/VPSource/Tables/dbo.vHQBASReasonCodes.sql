CREATE TABLE [dbo].[vHQBASReasonCodes]
(
[ReasonCode] [tinyint] NOT NULL,
[Reason] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQBASReasonCodes] ADD CONSTRAINT [PK_vHQBASReasonCodes] PRIMARY KEY CLUSTERED  ([ReasonCode]) ON [PRIMARY]
GO
