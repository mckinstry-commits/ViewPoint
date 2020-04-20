CREATE TABLE [dbo].[boldxrefEMCostType]
(
[Company] [tinyint] NOT NULL,
[CMSCostType] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL,
[VPCo] [tinyint] NOT NULL,
[VPCostType] [tinyint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
