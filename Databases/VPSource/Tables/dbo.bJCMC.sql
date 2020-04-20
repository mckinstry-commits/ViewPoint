CREATE TABLE [dbo].[bJCMC]
(
[UM] [dbo].[bUM] NOT NULL,
[MUM] [dbo].[bUM] NOT NULL,
[IMFactor] [decimal] (16, 6) NOT NULL CONSTRAINT [DF_bJCMC_IMFactor] DEFAULT ((0)),
[MIFactor] [decimal] (16, 6) NOT NULL CONSTRAINT [DF_bJCMC_MIFactor] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCMC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCMC] ON [dbo].[bJCMC] ([UM], [MUM]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCMC].[IMFactor]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCMC].[MIFactor]'
GO
