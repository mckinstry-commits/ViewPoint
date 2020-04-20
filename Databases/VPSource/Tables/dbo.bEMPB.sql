CREATE TABLE [dbo].[bEMPB]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[LiabType] [dbo].[bLiabilityType] NOT NULL,
[BurdenType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[BurdenRate] [dbo].[bRate] NOT NULL,
[AddonRate] [dbo].[bRate] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMPB] ADD
CONSTRAINT [FK_bEMPB_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
CREATE UNIQUE CLUSTERED INDEX [biEMPB] ON [dbo].[bEMPB] ([EMCo], [LiabType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMPB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO