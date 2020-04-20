CREATE TABLE [dbo].[vPMChangeOrderRequest]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[COR] [smallint] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Details] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Date] [dbo].[bDate] NULL,
[Status] [dbo].[bStatus] NULL,
[DateSent] [dbo].[bDate] NULL,
[DateDueBack] [dbo].[bDate] NULL,
[DateReceived] [dbo].[bDate] NULL,
[DateApproved] [dbo].[bDate] NULL,
[ChangeInDays] [smallint] NULL,
[ChangeInDaysOverride] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMChangeOrderRequest_ChangeInDaysOverride] DEFAULT ('N'),
[NewCompletionDate] [dbo].[bDate] NULL,
[OriginalContractAmount] [dbo].[bDollar] NULL,
[PrevApprovedCOAmount] [dbo].[bDollar] NULL,
[CurrentCOAmount] [dbo].[bDollar] NULL,
[CurrentContractAmount] [dbo].[bDollar] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[FromFirm] [dbo].[bFirm] NULL,
[FromContact] [dbo].[bEmployee] NULL,
[ToFirm] [dbo].[bFirm] NULL,
[ToContact] [dbo].[bEmployee] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vPMChangeOrderRequest] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequest_bPMCO] FOREIGN KEY ([PMCo]) REFERENCES [dbo].[bPMCO] ([PMCo])
ALTER TABLE [dbo].[vPMChangeOrderRequest] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequest_bJCCM] FOREIGN KEY ([PMCo], [Contract]) REFERENCES [dbo].[bJCCM] ([JCCo], [Contract])
ALTER TABLE [dbo].[vPMChangeOrderRequest] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequest_bPMSC] FOREIGN KEY ([Status]) REFERENCES [dbo].[bPMSC] ([Status])
ALTER TABLE [dbo].[vPMChangeOrderRequest] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequest_bPMFM_FromFirm] FOREIGN KEY ([VendorGroup], [FromFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
ALTER TABLE [dbo].[vPMChangeOrderRequest] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequest_bPMPM_FromContact] FOREIGN KEY ([VendorGroup], [FromFirm], [FromContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
ALTER TABLE [dbo].[vPMChangeOrderRequest] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequest_bPMPM_ToContact] FOREIGN KEY ([VendorGroup], [FromFirm], [ToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
ALTER TABLE [dbo].[vPMChangeOrderRequest] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequest_bPMFM_ToFirm] FOREIGN KEY ([VendorGroup], [ToFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMChangeOrderRequestd  ******/
CREATE trigger [dbo].[btPMChangeOrderRequestd] on [dbo].[vPMChangeOrderRequest] for DELETE as
/*--------------------------------------------------------------
 * Created By:	GF 03/29/2011 - TK-03298
 * Modified By: 
 *    JayR 3/16/2012 TK-00000 
 *        Removed deletes on tables vPMDistribution and vPMChangeOrderRequestPCO 
 *        that are already taken care of by delete cascades.
 *
 * Delete trigger for vPMChangeOrderRequest
 *
 * vPMDocumentHistory audit
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- delete distribution audit tables if any
delete bPMHA from bPMHA a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMChangeOrderRequest' and i.SourceKeyId=d.KeyID

delete bPMHF from bPMHF a join bPMHI i on i.KeyId=a.PMHIKeyId
join deleted d on i.SourceTableName='PMChangeOrderRequest' and i.SourceKeyId=d.KeyID

delete bPMHI from bPMHI i
join deleted d on i.SourceTableName='PMChangeOrderRequest' and i.SourceKeyId=d.KeyID

---- delete change order request association 
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.RecTableName='PMChangeOrderRequest' AND a.RECID=d.KeyID
WHERE d.KeyID IS NOT null
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord a ON a.LinkTableName='PMChangeOrderRequest' AND a.LINKID=d.KeyID
WHERE d.KeyID IS NOT NULL


RETURN

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**********************************************************/
CREATE trigger [dbo].[btPMChangeOrderRequestu] on [dbo].[vPMChangeOrderRequest] for UPDATE as
/*--------------------------------------------------------------
 * Created By:	GF 03/29/2011 TK-03298
 * Modified By:	
 *   JayR 03/16/2012 TK-00000  Removed parts of trigger that are
 *    better done with FK or Constraints.
 *
 *				
 * Validates columns and inserts document history records.
 *
 *--------------------------------------------------------------*/

IF @@rowcount = 0 RETURN
SET NOCOUNT ON

---- key fields cannot be changed
IF UPDATE(PMCo) OR UPDATE(Contract) OR UPDATE(COR)
	BEGIN
		RAISERROR('Cannot change key fields - cannot update PMChangeOrderRequest', 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	
RETURN



GO
ALTER TABLE [dbo].[vPMChangeOrderRequest] ADD CONSTRAINT [CK_vPMChangeOrderRequest_ChangeInDaysOverride] CHECK (([ChangeInDaysOverride]='Y' OR [ChangeInDaysOverride]='N'))
GO
ALTER TABLE [dbo].[vPMChangeOrderRequest] WITH NOCHECK ADD CONSTRAINT [CK_vPMChangeOrderRequest_FromContact] CHECK (([FromContact] IS NULL OR [FromFirm] IS NOT NULL))
GO
ALTER TABLE [dbo].[vPMChangeOrderRequest] WITH NOCHECK ADD CONSTRAINT [CK_vPMChangeOrderRequest_ToContact] CHECK (([ToContact] IS NULL OR [ToFirm] IS NOT NULL))
GO
ALTER TABLE [dbo].[vPMChangeOrderRequest] ADD CONSTRAINT [PK_vPMChangeOrderRequest] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMChangeOrderRequest_COR] ON [dbo].[vPMChangeOrderRequest] ([PMCo], [Contract], [COR]) ON [PRIMARY]
GO
