CREATE TABLE [dbo].[budxrefPhase]
(
[Company] [tinyint] NOT NULL,
[oldPhase] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[VPCo] [tinyint] NOT NULL,
[newPhase] [dbo].[bPhase] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ixrefPhase] ON [dbo].[budxrefPhase] ([Company], [oldPhase], [newPhase]) ON [PRIMARY]
GO
