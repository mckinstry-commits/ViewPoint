CREATE TABLE [dbo].[bEMAG]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMAG] ADD
CONSTRAINT [FK_bEMAG_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMAG] ADD
CONSTRAINT [FK_bEMAG_bEMAH_AllocCode] FOREIGN KEY ([EMCo], [AllocCode]) REFERENCES [dbo].[bEMAH] ([EMCo], [AllocCode]) ON DELETE CASCADE
ALTER TABLE [dbo].[bEMAG] ADD
CONSTRAINT [FK_bEMAG_bEMCM_Category] FOREIGN KEY ([EMCo], [Category]) REFERENCES [dbo].[bEMCM] ([EMCo], [Category])
GO
CREATE UNIQUE CLUSTERED INDEX [biEMAG] ON [dbo].[bEMAG] ([EMCo], [AllocCode], [Category]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
