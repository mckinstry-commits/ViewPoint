CREATE TABLE [dbo].[bPROT]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[OTSched] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[MonHrs] [dbo].[bHrs] NOT NULL,
[MonEarnCode] [dbo].[bEDLCode] NULL,
[TuesHrs] [dbo].[bHrs] NOT NULL,
[TuesEarnCode] [dbo].[bEDLCode] NULL,
[WedHrs] [dbo].[bHrs] NOT NULL,
[WedEarnCode] [dbo].[bEDLCode] NULL,
[ThursHrs] [dbo].[bHrs] NOT NULL,
[ThursEarnCode] [dbo].[bEDLCode] NULL,
[FriHrs] [dbo].[bHrs] NOT NULL,
[FriEarnCode] [dbo].[bEDLCode] NULL,
[SatHrs] [dbo].[bHrs] NOT NULL,
[SatEarnCode] [dbo].[bEDLCode] NULL,
[SunHrs] [dbo].[bHrs] NOT NULL,
[SunEarnCode] [dbo].[bEDLCode] NULL,
[HolHrs] [dbo].[bHrs] NOT NULL,
[HolEarnCode] [dbo].[bEDLCode] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Lvl2MonHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl2MonHrs] DEFAULT ((0)),
[Lvl2MonEarnCode] [dbo].[bEDLCode] NULL,
[Lvl2TuesHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl2TuesHrs] DEFAULT ((0)),
[Lvl2TuesEarnCode] [dbo].[bEDLCode] NULL,
[Lvl2WedHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl2WedHrs] DEFAULT ((0)),
[Lvl2WedEarnCode] [dbo].[bEDLCode] NULL,
[Lvl2ThursHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl2ThursHrs] DEFAULT ((0)),
[Lvl2ThursEarnCode] [dbo].[bEDLCode] NULL,
[Lvl2FriHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl2FriHrs] DEFAULT ((0)),
[Lvl2FriEarnCode] [dbo].[bEDLCode] NULL,
[Lvl2SatHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl2SatHrs] DEFAULT ((0)),
[Lvl2SatEarnCode] [dbo].[bEDLCode] NULL,
[Lvl2SunHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl2SunHrs] DEFAULT ((0)),
[Lvl2SunEarnCode] [dbo].[bEDLCode] NULL,
[Lvl2HolHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl2HolHrs] DEFAULT ((0)),
[Lvl2HolEarnCode] [dbo].[bEDLCode] NULL,
[Lvl3MonHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl3MonHrs] DEFAULT ((0)),
[Lvl3MonEarnCode] [dbo].[bEDLCode] NULL,
[Lvl3TuesHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl3TuesHrs] DEFAULT ((0)),
[Lvl3TuesEarnCode] [dbo].[bEDLCode] NULL,
[Lvl3WedHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl3WedHrs] DEFAULT ((0)),
[Lvl3WedEarnCode] [dbo].[bEDLCode] NULL,
[Lvl3ThursHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl3ThursHrs] DEFAULT ((0)),
[Lvl3ThursEarnCode] [dbo].[bEDLCode] NULL,
[Lvl3FriHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl3FriHrs] DEFAULT ((0)),
[Lvl3FriEarnCode] [dbo].[bEDLCode] NULL,
[Lvl3SatHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl3SatHrs] DEFAULT ((0)),
[Lvl3SatEarnCode] [dbo].[bEDLCode] NULL,
[Lvl3SunHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl3SunHrs] DEFAULT ((0)),
[Lvl3SunEarnCode] [dbo].[bEDLCode] NULL,
[Lvl3HolHrs] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bPROT_Lvl3HolHrs] DEFAULT ((0)),
[Lvl3HolEarnCode] [dbo].[bEDLCode] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bPROT_KeyID] ON [dbo].[bPROT] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_bPROT_OTSched] ON [dbo].[bPROT] ([PRCo], [OTSched]) ON [PRIMARY]
GO