CREATE TABLE [dbo].[bPREA_Archive]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[SubjectAmt] [dbo].[bDollar] NOT NULL,
[EligibleAmt] [dbo].[bDollar] NOT NULL,
[AuditYN] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NULL,
[ArchiveDate] [datetime] NULL CONSTRAINT [DF__bPREA_Arc__Archi__0706D32B] DEFAULT (getdate()),
[ArchiveID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
