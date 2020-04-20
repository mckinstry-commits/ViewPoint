CREATE TABLE [dbo].[bHREI]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[PositionCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[Interviewer] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InterviewDate] [dbo].[bDate] NULL,
[InterviewTime] [smalldatetime] NULL,
[PrevEmpl] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PrevPosition] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PrevJobDate] [dbo].[bDate] NULL,
[PrevJobReason] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[JobAppStatus] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[JobAppDate] [dbo].[bDate] NULL,
[JobOfferDate] [dbo].[bDate] NULL,
[JobAcceptDate] [dbo].[bDate] NULL,
[JobRejectDate] [dbo].[bDate] NULL,
[InterviewComments] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHREI] ON [dbo].[bHREI] ([HRCo], [HRRef], [PositionCode], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHREI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
