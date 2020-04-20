CREATE TABLE [dbo].[bHRAW]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[Accident] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ClaimContact] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[HRRef] [dbo].[bHRRef] NULL,
[Name] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Phone] [dbo].[bPhone] NULL,
[EMail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHRAW] ON [dbo].[bHRAW] ([HRCo], [Accident], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
