CREATE TABLE [dbo].[boldxrefEMCostCodes]
(
[CMSComponent] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[CostCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
