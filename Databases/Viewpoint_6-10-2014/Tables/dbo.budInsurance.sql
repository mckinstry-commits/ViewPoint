CREATE TABLE [dbo].[budInsurance]
(
[CoverageLev] [dbo].[bItemDesc] NULL,
[Seq] [smallint] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biudInsurance] ON [dbo].[budInsurance] ([Seq]) ON [PRIMARY]
GO
