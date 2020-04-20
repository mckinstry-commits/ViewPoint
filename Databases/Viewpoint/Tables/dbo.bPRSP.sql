CREATE TABLE [dbo].[bPRSP]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[PaySeq] [tinyint] NOT NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMRef] [dbo].[bCMRef] NOT NULL,
[PaidDate] [dbo].[bDate] NOT NULL,
[LastName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[FirstName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MidName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[SSN] [char] (11) COLLATE Latin1_General_BIN NOT NULL,
[FileStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[Exempts] [tinyint] NULL,
[SortName] [dbo].[bSortName] NOT NULL,
[ChkSort] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[SortOrder] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRSP] ON [dbo].[bPRSP] ([PRCo], [PRGroup], [PREndDate], [Employee], [PaySeq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
