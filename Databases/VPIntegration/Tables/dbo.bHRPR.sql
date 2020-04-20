CREATE TABLE [dbo].[bHRPR]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[PositionCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[Code] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHRPR] ON [dbo].[bHRPR] ([HRCo], [PositionCode], [Seq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRPR] ([KeyID]) ON [PRIMARY]
GO
