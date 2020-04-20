CREATE TABLE [dbo].[bEMTF]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[RevTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[RevBdownCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Rate] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMTF] ADD
CONSTRAINT [FK_bEMTF_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMTF] ADD
CONSTRAINT [FK_bEMTF_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
ALTER TABLE [dbo].[bEMTF] ADD
CONSTRAINT [FK_bEMTF_bEMTH_RevTemplate] FOREIGN KEY ([EMCo], [RevTemplate]) REFERENCES [dbo].[bEMTH] ([EMCo], [RevTemplate])
ALTER TABLE [dbo].[bEMTF] ADD
CONSTRAINT [FK_bEMTF_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
ALTER TABLE [dbo].[bEMTF] ADD
CONSTRAINT [FK_bEMTF_bEMRT_RevBdownCode] FOREIGN KEY ([EMGroup], [RevBdownCode]) REFERENCES [dbo].[bEMRT] ([EMGroup], [RevBdownCode])
ALTER TABLE [dbo].[bEMTF] ADD
CONSTRAINT [FK_bEMTF_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO
CREATE UNIQUE CLUSTERED INDEX [biEMTF] ON [dbo].[bEMTF] ([EMCo], [EMGroup], [RevTemplate], [Equipment], [RevCode], [RevBdownCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMTF] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
