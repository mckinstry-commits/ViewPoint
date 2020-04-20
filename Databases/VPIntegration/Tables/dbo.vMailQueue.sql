CREATE TABLE [dbo].[vMailQueue]
(
[MailQueueID] [int] NOT NULL IDENTITY(1, 1),
[To] [varchar] (3000) COLLATE Latin1_General_BIN NOT NULL,
[CC] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[BCC] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[From] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[Subject] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[Body] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Attempts] [int] NULL,
[FailureDate] [datetime] NULL,
[FailureReason] [varchar] (3000) COLLATE Latin1_General_BIN NULL,
[Source] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[AttachIDs] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[AttachFiles] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CacheFolder] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[TokenID] [int] NULL,
[VPUserName] [dbo].[bVPUserName] NULL,
[IsHTML] [dbo].[bYN] NULL CONSTRAINT [DF_vMailQueue_IsHTML] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vMailQueue] ADD CONSTRAINT [PK_vMailQueue] PRIMARY KEY CLUSTERED  ([MailQueueID]) ON [PRIMARY]
GO
