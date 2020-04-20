CREATE TABLE [dbo].[bPMOB]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PCOType] [dbo].[bDocType] NOT NULL,
[PCO] [dbo].[bPCO] NOT NULL,
[PCOItem] [dbo].[bPCOItem] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[AmtToDistribute] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bPMOB_AmtToDistribute] DEFAULT ((0)),
[PMOIKeyID] [bigint] NOT NULL,
[AddOn] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMOB] ADD CONSTRAINT [PK_bPMOB] PRIMARY KEY CLUSTERED  ([PMCo], [Project], [PCOType], [PCO], [PCOItem], [PhaseGroup], [Phase], [CostType]) ON [PRIMARY]
GO
