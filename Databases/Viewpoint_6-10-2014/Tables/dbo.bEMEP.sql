CREATE TABLE [dbo].[bEMEP]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[PartNo] [char] (30) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[HQMatl] [dbo].[bMatl] NULL,
[Qty] [dbo].[bUnits] NULL,
[UM] [dbo].[bUM] NULL,
[Notes] [char] (30) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biEMEP] ON [dbo].[bEMEP] ([EMCo], [Equipment], [PartNo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMEP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMEP] WITH NOCHECK ADD CONSTRAINT [FK_bEMEP_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO
ALTER TABLE [dbo].[bEMEP] WITH NOCHECK ADD CONSTRAINT [FK_bEMEP_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[bEMEP] NOCHECK CONSTRAINT [FK_bEMEP_bEMCO_EMCo]
GO
ALTER TABLE [dbo].[bEMEP] NOCHECK CONSTRAINT [FK_bEMEP_bEMEM_Equipment]
GO
