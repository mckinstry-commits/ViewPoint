CREATE TABLE [dbo].[vPMChangeOrderRequestPCO]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[COR] [smallint] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[PCOType] [dbo].[bDocType] NOT NULL,
[PCO] [dbo].[bPCO] NOT NULL,
[Date] [dbo].[bDate] NULL,
[Status] [dbo].[bStatus] NULL,
[TotalCost] [dbo].[bDollar] NULL,
[PurchaseAmount] [dbo].[bDollar] NULL,
[TotalRevenue] [dbo].[bDollar] NULL,
[ROMAmount] [dbo].[bDollar] NULL,
[Date1] [dbo].[bDate] NULL,
[Date2] [dbo].[bDate] NULL,
[Date3] [dbo].[bDate] NULL,
[RecordAdded] [dbo].[bDate] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CORID] [bigint] NULL,
[PCOID] [bigint] NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[vPMChangeOrderRequestPCO] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequestPCO_vPMChangeOrderRequestPCO_PCOID] FOREIGN KEY ([PCOID]) REFERENCES [dbo].[bPMOP] ([KeyID]) ON DELETE CASCADE
ALTER TABLE [dbo].[vPMChangeOrderRequestPCO] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequestPCO_bPMCO] FOREIGN KEY ([PMCo]) REFERENCES [dbo].[bPMCO] ([PMCo])
ALTER TABLE [dbo].[vPMChangeOrderRequestPCO] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequestPCO_bJCCM] FOREIGN KEY ([PMCo], [Contract]) REFERENCES [dbo].[bJCCM] ([JCCo], [Contract])
ALTER TABLE [dbo].[vPMChangeOrderRequestPCO] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequestPCO_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
ALTER TABLE [dbo].[vPMChangeOrderRequestPCO] WITH NOCHECK ADD
CONSTRAINT [FK_vPMChangeOrderRequestPCO_bPMOP] FOREIGN KEY ([PMCo], [Project], [PCOType], [PCO]) REFERENCES [dbo].[bPMOP] ([PMCo], [Project], [PCOType], [PCO])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMChangeOrderRequestPCOd  ******/
CREATE trigger [dbo].[btPMChangeOrderRequestPCOd] on [dbo].[vPMChangeOrderRequestPCO] for DELETE as
/*--------------------------------------------------------------
 * Created By:	GF 03/29/2011 - TK-03298
 * Modified By:  JayR 03/20/2012 TK-00000  Remove unneeded variables
 *
 *
 * Delete trigger for vPMChangeOrderRequestPCO
 *
 * 
 *--------------------------------------------------------------*/
if @@rowcount = 0 return
set nocount on


---- delete change order request pco association
---- we need to remove links between the PCO and the COR
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord b ON b.RecTableName='PMChangeOrderRequest' AND b.RECID=d.CORID AND b.LinkTableName = 'PMOP' AND b.LINKID = d.PCOID
WHERE d.KeyID IS NOT NULL AND d.PCOID IS NOT NULL AND d.CORID IS NOT NULL
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord b ON b.RecTableName='PMOP' AND b.RECID=d.PCOID AND b.LinkTableName='PMChangeOrderRequest' AND b.LINKID=d.CORID
WHERE d.KeyID IS NOT NULL AND d.PCOID IS NOT NULL AND d.CORID IS NOT NULL

---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vPMChangeOrderRequestPCO', ' Key: ' + convert(char(3), i.PMCo) + '/' + ISNULL(i.Contract,'') + '/' + ISNULL(i.Project,'') + '/' + ISNULL(i.PCOType,'') + '/' + ISNULL(i.PCO,''),
       i.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted i
--join dbo.bPMCO c on c.PMCo = i.PMCo
--where i.PMCo = c.PMCo and c.AuditPMCA = 'Y'


RETURN

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMChangeOrderRequestPCOi  ******/
CREATE trigger [dbo].[btPMChangeOrderRequestPCOi] on [dbo].[vPMChangeOrderRequestPCO] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for vPMChangeOrderRequestPCO
* Created By:	GF 03/29/2011 TK-03298
* Modified By:	JayR 03/20/2012 TK-00000 Change to use FK for validation
*				
*
* Validate key fields and insert HQMA audit record
* Update PCOID and CORID when null
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- update record and insert PCOID if missing
--SELECT p.KeyID
UPDATE dbo.vPMChangeOrderRequestPCO SET PCOID = p.KeyID
FROM inserted i
INNER JOIN dbo.vPMChangeOrderRequestPCO a ON a.KeyID=i.KeyID
INNER JOIN dbo.bPMOP p ON p.PMCo=i.PMCo AND p.Project=i.Project AND p.PCOType=i.PCOType AND p.PCO=i.PCO

---- update record and insert CORID if missing
----SELECT p.KeyID
UPDATE dbo.vPMChangeOrderRequestPCO SET CORID = p.KeyID
FROM inserted i
INNER JOIN dbo.vPMChangeOrderRequestPCO a ON a.KeyID=i.KeyID
INNER JOIN dbo.vPMChangeOrderRequest p ON p.PMCo=i.PMCo AND p.Contract=i.Contract AND p.COR=i.COR


---- create record relate for COR and PCO
INSERT dbo.vPMRelateRecord (RecTableName, RECID, LinkTableName, LINKID)
SELECT 'PMChangeOrderRequest', a.KeyID, 'PMOP', b.KeyID
FROM inserted i
INNER JOIN dbo.vPMChangeOrderRequest a ON a.PMCo=i.PMCo AND a.Contract=i.Contract AND a.COR=i.COR
INNER JOIN dbo.bPMOP b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.PCOType=i.PCOType AND b.PCO=i.PCO
WHERE i.PCO IS NOT NULL AND i.COR IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMChangeOrderRequest'
				AND c.RECID=a.KeyID AND c.LinkTableName='PMOP' AND c.LINKID=b.KeyID)



---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vPMChangeOrderRequestPCO', ' Key: ' + convert(char(3), i.PMCo) + '/' + ISNULL(i.Contract,'') + '/' + ISNULL(i.Project,'') + '/' + ISNULL(i.PCOType,'') + '/' + ISNULL(i.PCO,''),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i
--join dbo.bPMCO c on c.PMCo = i.PMCo
--where i.PMCo = c.PMCo and c.AuditPMCA = 'Y'



RETURN

GO
ALTER TABLE [dbo].[vPMChangeOrderRequestPCO] ADD CONSTRAINT [PK_vPMChangeOrderRequestPCO] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMChangeOrderRequestPCO_PCO] ON [dbo].[vPMChangeOrderRequestPCO] ([PMCo], [Contract], [COR], [Project], [PCOType], [PCO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMChangeOrderRequestPCO] WITH NOCHECK ADD CONSTRAINT [FK_vPMChangeOrderRequestPCO_vPMChangeOrderRequestPCO_KeyID] FOREIGN KEY ([CORID]) REFERENCES [dbo].[vPMChangeOrderRequest] ([KeyID]) ON DELETE CASCADE
GO
