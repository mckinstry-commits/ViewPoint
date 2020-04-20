CREATE TABLE [dbo].[bEMTH]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[RevTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NOT NULL,
[TypeFlag] [char] (1) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CopyFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMTH_CopyFlag] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bEMTH] ADD
CONSTRAINT [CK_bEMTH_TypeFlag] CHECK (([TypeFlag]='O' OR [TypeFlag]='P' OR [TypeFlag] IS NULL))
ALTER TABLE [dbo].[bEMTH] ADD
CONSTRAINT [FK_bEMTH_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
GO

CREATE UNIQUE CLUSTERED INDEX [biEMTH] ON [dbo].[bEMTH] ([EMCo], [RevTemplate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMTH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO