CREATE TABLE [dbo].[bEMAD]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AllocCode] [tinyint] NOT NULL,
[Department] [dbo].[bDept] NOT NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMAD] ADD
CONSTRAINT [FK_bEMAD_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMAD] ADD
CONSTRAINT [FK_bEMAD_bEMAH_AllocCode] FOREIGN KEY ([EMCo], [AllocCode]) REFERENCES [dbo].[bEMAH] ([EMCo], [AllocCode]) ON DELETE CASCADE
ALTER TABLE [dbo].[bEMAD] ADD
CONSTRAINT [FK_bEMAD_bEMDM_Department] FOREIGN KEY ([EMCo], [Department]) REFERENCES [dbo].[bEMDM] ([EMCo], [Department])
GO
CREATE UNIQUE CLUSTERED INDEX [biEMAD] ON [dbo].[bEMAD] ([EMCo], [AllocCode], [Department]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
