CREATE TABLE [dbo].[boldudJobRequest10292013]
(
[Co] [dbo].[bCompany] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[RequestNum] [int] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CertifiedPRYN] [dbo].[bYN] NOT NULL,
[Contract] [dbo].[bContract] NULL,
[Customer] [dbo].[bCustomer] NULL,
[Department] [dbo].[bDept] NULL,
[NTPYN] [dbo].[bYN] NOT NULL,
[POC] [dbo].[bProjectMgr] NULL,
[PublicYN] [dbo].[bYN] NOT NULL,
[WMBEYN] [dbo].[bYN] NOT NULL,
[Workstream] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[QueueDate] [dbo].[bDate] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
