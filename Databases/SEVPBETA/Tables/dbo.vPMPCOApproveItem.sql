CREATE TABLE [dbo].[vPMPCOApproveItem]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[ApprovalID] [smallint] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[PCOType] [dbo].[bPCOType] NOT NULL,
[PCO] [dbo].[bPCO] NOT NULL,
[PCOItem] [dbo].[bPCOItem] NOT NULL,
[Approve] [dbo].[bYN] NULL,
[ACO] [dbo].[bACO] NULL,
[ACOItem] [dbo].[bACOItem] NULL,
[ACOItemDesc] [dbo].[bItemDesc] NULL,
[ApprovalDate] [dbo].[bDate] NULL,
[ContractItem] [dbo].[bContractItem] NULL,
[ApprovedAmount] [dbo].[bDollar] NULL,
[AdditionalDays] [int] NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnitCost] NULL,
[Error] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMPCOApproveItem] ADD CONSTRAINT [PK_vPMPCOApproveItem] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMPCOApproveItem_PCOItem] ON [dbo].[vPMPCOApproveItem] ([PMCo], [ApprovalID], [Project], [PCOType], [PCO], [PCOItem]) ON [PRIMARY]
GO
