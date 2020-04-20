CREATE TABLE [dbo].[bPMUR]
(
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ContractItem] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUR_ContractItem] DEFAULT ('Y'),
[Phase] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUR_Phase] DEFAULT ('Y'),
[CostType] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUR_CostType] DEFAULT ('Y'),
[SubcontractDetail] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUR_SubcontractDetail] DEFAULT ('Y'),
[MaterialDetail] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUR_MaterialDetail] DEFAULT ('Y'),
[EstimateInfo] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUR_EstimateInfo] DEFAULT ('Y'),
[ResourceDetail] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMUR_ResourceDetail] DEFAULT ('N'),
[ContractItemID] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PhaseID] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CostTypeID] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SubcontractDetailID] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[MaterialDetailID] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[EstimateInfoID] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ResourceDetailID] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bPMUR] WITH NOCHECK ADD
CONSTRAINT [FK_bPMUR_bPMUT] FOREIGN KEY ([Template]) REFERENCES [dbo].[bPMUT] ([Template]) ON DELETE CASCADE
GO
CREATE NONCLUSTERED INDEX [PK_bPMUR] ON [dbo].[bPMUR] ([Template]) ON [PRIMARY]
GO
