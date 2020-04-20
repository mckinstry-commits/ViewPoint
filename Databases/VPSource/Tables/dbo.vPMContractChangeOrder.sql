CREATE TABLE [dbo].[vPMContractChangeOrder]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[ID] [smallint] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Details] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Date] [dbo].[bDate] NULL,
[DateSent] [dbo].[bDate] NULL,
[DateDueBack] [dbo].[bDate] NULL,
[DateReceived] [dbo].[bDate] NULL,
[DateApproved] [dbo].[bDate] NULL,
[ChangeInDays] [smallint] NULL,
[ChangeInDaysOverride] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMContractChangeOrder_ChangeInDaysOverride] DEFAULT ('N'),
[NewCompletionDate] [dbo].[bDate] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[FromFirm] [dbo].[bFirm] NULL,
[FromContact] [dbo].[bEmployee] NULL,
[ToFirm] [dbo].[bFirm] NULL,
[ToContact] [dbo].[bEmployee] NULL,
[OriginalContractAmount] [dbo].[bDollar] NULL,
[PrevApprovedCOAmount] [dbo].[bDollar] NULL,
[CurrentCOAmount] [dbo].[bDollar] NULL,
[CurrentContractAmount] [dbo].[bDollar] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[DocType] [dbo].[bDocType] NOT NULL CONSTRAINT [DF_vPMContractChangeOrder_DocType] DEFAULT ('CCO')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vPMContractChangeOrder] ADD
CONSTRAINT [FK_vPMContractChangeOrder_bPMDT] FOREIGN KEY ([DocType]) REFERENCES [dbo].[bPMDT] ([DocType])
ALTER TABLE [dbo].[vPMContractChangeOrder] ADD
CONSTRAINT [FK_vPMContractChangeOrder_bJCCM] FOREIGN KEY ([PMCo], [Contract]) REFERENCES [dbo].[bJCCM] ([JCCo], [Contract])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPMContractChangeOrderd] on [dbo].[vPMContractChangeOrder] for DELETE as
/*--------------------------------------------------------------
 * Created By:		GP 04/13/2011
 * Modified By:		GF 05/17/2011 delete related tables
 *				    JayR 03/20/2012 Change to using FK constaints, cleanup
 *
 * Delete trigger for vPMContractChangeOrder
 *
 * vPMDocumentHistory audit
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- delete distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMContractChangeOrder' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMContractChangeOrder' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMContractChangeOrder' and i.SourceKeyId=d.KeyID

---- delete change order request association 
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMContractChangeOrder' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT null
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMContractChangeOrder' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


RETURN

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPMContractChangeOrderu] on [dbo].[vPMContractChangeOrder] for UPDATE as
/*--------------------------------------------------------------
 * Created By:		GP 04/13/2011
 * Modified By:	
 *    JayR  3/16/2012  TK-00000 Replaced some checking with FK.
 *				
 * Validates columns.
 *
 *--------------------------------------------------------------*/

IF @@rowcount = 0 RETURN
SET NOCOUNT ON


---- key fields cannot be changed
IF UPDATE(PMCo) OR UPDATE(Contract) OR UPDATE(ID)
BEGIN
	RAISERROR('Cannot change key fields - cannot update PMContractChangeOrder', 11, -1)
	ROLLBACK TRANSACTION
	RETURN 
END

RETURN



GO
ALTER TABLE [dbo].[vPMContractChangeOrder] ADD CONSTRAINT [CK_vPMContractChangeOrder_ChangeInDaysOverride] CHECK (([ChangeInDaysOverride]='N' OR [ChangeInDaysOverride]='Y'))
GO
ALTER TABLE [dbo].[vPMContractChangeOrder] WITH NOCHECK ADD CONSTRAINT [CK_vPMContractChangeOrder_FromContact] CHECK (([FromContact] IS NULL OR [FromFirm] IS NOT NULL))
GO
ALTER TABLE [dbo].[vPMContractChangeOrder] WITH NOCHECK ADD CONSTRAINT [CK_vPMContractChangeOrder_ToContact] CHECK (([ToContact] IS NULL OR [ToFirm] IS NOT NULL))
GO
ALTER TABLE [dbo].[vPMContractChangeOrder] ADD CONSTRAINT [PK_vPMContractChangeOrder] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMContractChangeOrderID] ON [dbo].[vPMContractChangeOrder] ([PMCo], [Contract], [ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMContractChangeOrder] WITH NOCHECK ADD CONSTRAINT [FK_vPMContractChangeOrder_bPMCO] FOREIGN KEY ([PMCo]) REFERENCES [dbo].[bPMCO] ([PMCo])
GO

ALTER TABLE [dbo].[vPMContractChangeOrder] WITH NOCHECK ADD CONSTRAINT [FK_vPMContractChangeOrder_bPMFM_FromFirm] FOREIGN KEY ([VendorGroup], [FromFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[vPMContractChangeOrder] WITH NOCHECK ADD CONSTRAINT [FK_vPMContractChangeOrder_bPMPM_FromContact] FOREIGN KEY ([VendorGroup], [FromFirm], [FromContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[vPMContractChangeOrder] WITH NOCHECK ADD CONSTRAINT [FK_vPMContractChangeOrder_bPMPM_ToContact] FOREIGN KEY ([VendorGroup], [FromFirm], [ToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
ALTER TABLE [dbo].[vPMContractChangeOrder] WITH NOCHECK ADD CONSTRAINT [FK_vPMContractChangeOrder_bPMFM_ToFirm] FOREIGN KEY ([VendorGroup], [ToFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
