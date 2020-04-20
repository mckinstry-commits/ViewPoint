CREATE TABLE [dbo].[vWFProcessDetailApproverHistory]
(
[Action] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[DateTime] [datetime] NOT NULL,
[DetailStepID] [bigint] NOT NULL,
[Approver] [dbo].[bVPUserName] NOT NULL,
[Status] [tinyint] NULL,
[ApprovalLimit] [dbo].[bDollar] NULL,
[ApproverOptional] [dbo].[bYN] NOT NULL,
[WFProcessStepID] [bigint] NULL,
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Comments] [dbo].[bNotes] NULL,
[ReturnTo] [varchar] (140) COLLATE Latin1_General_BIN NULL,
[FieldName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL,
[HistoryKeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWFProcessDetailApproverHistory] ADD CONSTRAINT [PK_vWFProcessDetailApproverHistory] PRIMARY KEY NONCLUSTERED  ([HistoryKeyID]) ON [PRIMARY]
GO
