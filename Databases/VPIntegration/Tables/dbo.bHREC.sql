CREATE TABLE [dbo].[bHREC]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[Seq] [smallint] NOT NULL,
[Contact] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Relationship] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[HomePhone] [dbo].[bPhone] NULL,
[WorkPhone] [dbo].[bPhone] NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[CellPhone] [dbo].[bPhone] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHREC] ON [dbo].[bHREC] ([HRCo], [HRRef], [Seq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHREC] ([KeyID]) ON [PRIMARY]
GO
