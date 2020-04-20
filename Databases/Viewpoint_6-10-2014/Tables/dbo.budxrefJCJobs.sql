CREATE TABLE [dbo].[budxrefJCJobs]
(
[COMPANYNUMBER] [int] NULL,
[DIVISIONNUMBER] [int] NULL,
[JOBNUMBER] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SUBJOBNUMBER] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ConvertingYN] [char] (1) COLLATE Latin1_General_BIN NULL,
[VPCo] [int] NULL,
[VPJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[VPJobExt] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[JobSeq] [int] NULL
) ON [PRIMARY]
GO
