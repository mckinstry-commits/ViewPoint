CREATE TABLE [dbo].[bHRTS]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[TrainCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ClassSeq] [int] NOT NULL,
[SkillCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHRTS] ON [dbo].[bHRTS] ([HRCo], [TrainCode], [Type], [ClassSeq], [SkillCode]) ON [PRIMARY]
GO
