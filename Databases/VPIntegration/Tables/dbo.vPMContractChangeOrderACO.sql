CREATE TABLE [dbo].[vPMContractChangeOrderACO]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[ID] [smallint] NOT NULL,
[Seq] [smallint] NOT NULL,
[Project] [dbo].[bProject] NOT NULL,
[ACO] [dbo].[bACO] NOT NULL,
[Status] [dbo].[bStatus] NULL,
[EstimateChange] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPMContractChangeOrderACO_EstimateChange] DEFAULT ((0)),
[PurchaseChange] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPMContractChangeOrderACO_PurchaseChange] DEFAULT ((0)),
[ContractChange] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPMContractChangeOrderACO_ContractChange] DEFAULT ((0)),
[COR] [smallint] NULL,
[PCOType] [dbo].[bPCOType] NULL,
[PCO] [dbo].[bPCO] NULL,
[RecordAdded] [dbo].[bDate] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CCOID] [bigint] NULL,
[ACOID] [bigint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPMContractChangeOrderACOd] on [dbo].[vPMContractChangeOrderACO] for DELETE as
/*--------------------------------------------------------------
 * Created By:		GP 04/13/2011
 * Modified By:		GF 05/02/2011 TK-04796
 *					DAN SO 05/23/2011 - TK-05322 - Set ReadyForAcctg flag
 *					GP 08/12/2011 - TK-07582 Set PMOI Approved flag to 'Y'
 *                  JayR 3/19/2012 - TK-00000 Remove unneeded variables.
 *
 * Delete trigger for vPMContractChangeOrder
 *
 * vPMDocumentHistory audit
 *--------------------------------------------------------------*/
declare @PMCo bCompany, @Contract bContract, @ID smallint, @Project bProject, @ACO bACO, @KeyID bigint

IF @@rowcount = 0 RETURN 
SET NOCOUNT ON 


---- Get deleted key fields
select @PMCo = PMCo, @Contract = [Contract], @ID = ID, @Project = Project, @ACO = ACO, @KeyID = KeyID from deleted
---- Delete related records in commitments table once all related ACOs are deleted
delete dbo.vPMContractChangeOrderCommit
where PMCo = @PMCo and [Contract] = @Contract and ID = @ID and Project = @Project and ACO = @ACO
	and not exists (select top 1 1 from dbo.vPMContractChangeOrderACO where PMCo=@PMCo and [Contract]=@Contract and ID=@ID
		and Project=@Project and ACO=@ACO and KeyID<>@KeyID)


-- TK-05322 --
-- UPDATE ReadyForAcctg FLAG --
	UPDATE	dbo.bPMOH SET ReadyForAcctg = 'Y'
	  FROM	deleted d	
INNER JOIN	dbo.bPMOH p ON p.KeyID = d.ACOID

update dbo.bPMOI
set Approved = 'Y'
from deleted d
inner join dbo.bPMOI i on i.PMCo=d.PMCo and i.Project=d.Project and i.ACO=d.ACO

---- TK-04796
---- delete contract change order aco association
---- we need to remove links between the ACO and the CCO
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord b ON b.RecTableName='PMContractChangeOrder' AND b.RECID=d.CCOID AND b.LinkTableName = 'PMOH' AND b.LINKID = d.ACOID
WHERE d.KeyID IS NOT NULL AND d.ACOID IS NOT NULL AND d.CCOID IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM dbo.vPMContractChangeOrderACO c WHERE c.CCOID=d.CCOID AND c.ACOID=d.ACOID) 
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.vPMRelateRecord b ON b.RecTableName='PMOH' AND b.RECID=d.ACOID AND b.LinkTableName='PMContractChangeOrder' AND b.LINKID=d.CCOID
WHERE d.KeyID IS NOT NULL AND d.ACOID IS NOT NULL AND d.CCOID IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM dbo.vPMContractChangeOrderACO c WHERE c.CCOID=d.CCOID AND c.ACOID=d.ACOID) 

---- TK-04796
---- delete contract change order aco association
---- we need to remove links between the PCO and the CCO
---- record side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bPMOP p ON p.PMCo=d.PMCo AND p.Project=d.Project AND p.PCOType=d.PCOType AND p.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord b ON b.RecTableName='PMContractChangeOrder' AND b.RECID=d.CCOID AND b.LinkTableName = 'PMOP' AND b.LINKID = p.KeyID
WHERE d.KeyID IS NOT NULL AND d.CCOID IS NOT NULL AND d.PCO IS NOT NULL
----AND (SELECT COUNT(*) FROM dbo.vPMContractChangeOrderACO c WHERE c.CCOID=d.CCOID AND c.ACOID=d.ACOID) = 0
---- link side
DELETE FROM dbo.vPMRelateRecord
FROM deleted d
INNER JOIN dbo.bPMOP p ON p.PMCo=d.PMCo AND p.Project=d.Project AND p.PCOType=d.PCOType AND p.PCO=d.PCO
INNER JOIN dbo.vPMRelateRecord b ON b.RecTableName='PMOP' AND b.RECID=p.KeyID AND b.LinkTableName='PMContractChangeOrder' AND b.LINKID=d.CCOID
WHERE d.KeyID IS NOT NULL AND d.CCOID IS NOT NULL AND d.PCO IS NOT NULL
--AND (SELECT COUNT(*) FROM dbo.vPMContractChangeOrderACO c WHERE c.CCOID=d.CCOID AND c.ACOID=d.ACOID) = 0


---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vPMContractChangeOrder', ' Key: ' + convert(char(3), i.PMCo) + '/' + ISNULL(i.Contract,'') + '/' + ISNULL(i.Project,'') + '/' + ISNULL(i.PCO,''),
       i.PMCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted i


RETURN

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btPMContractChangeOrderACOi] on [dbo].[vPMContractChangeOrderACO] for INSERT as
/*--------------------------------------------------------------
 * Created By:		GP 04/13/2011
 * Modified By:		GF 05/02/2011 TK-04796
 *					DAN SO 05/23/2011 - TK-05322 - Set ReadyForAcctg flag
 *					GP/GPT 06/06/2011 - TK-05795 Fixed Seq index error on commit table insert
 *					GP 08/12/2011 - TK-07582 Set PMOI Approved flag to 'N'
 *                  JayR 3/19/2012 - TK-00000  Remove validation that is now handled by constraints.
 *
 *
 *--------------------------------------------------------------*/
declare @validcnt int

if @@rowcount = 0 return
set nocount on

----Insert related commitment change order records
----SL
select @validcnt = count(*) from dbo.vPMContractChangeOrderCommit c join inserted i on c.PMCo=i.PMCo and c.[Contract]=i.[Contract] and c.ID=i.ID
if @validcnt > 0
begin
	insert dbo.vPMContractChangeOrderCommit (PMCo, [Contract], ID, Seq, Project, VendorGroup, Vendor,
		[Type], SLPO, ChangeOrder, [Status], Amount, DateSent, DateDueBack, DateReceived, DateApproved, ACO)
	select SL.PMCo, SL.[Contract], SL.ID, isnull(max(c.Seq),0) + row_number() over(order by c.PMCo, c.[Contract], c.ID),
		SL.Project, SL.VendorGroup, SL.Vendor, 'SL', SL.SL, null, null, SL.Amount, null, null, null, null, SL.ACO
	from
	(
		select i.PMCo, i.[Contract], i.ID, i.Project, sl.VendorGroup, sl.Vendor, sl.SL, isnull(sum(sl.Amount), 0) as [Amount], sl.ACO
		from inserted i
		join dbo.bPMSL sl on sl.PMCo=i.PMCo and sl.Project=i.Project and sl.ACO=i.ACO and sl.SL is not null
		where not exists (select top 1 1 from dbo.PMContractChangeOrderCommit co where co.PMCo=i.PMCo and
			co.[Contract]=i.Contract and co.ID=i.ID and co.ACO=i.ACO)
		group by i.PMCo, i.[Contract], i.ID, i.Project, sl.VendorGroup, sl.Vendor, sl.SL, sl.ACO
	)
	SL
	join dbo.vPMContractChangeOrderCommit c on c.PMCo=SL.PMCo and c.[Contract]=SL.[Contract] and c.ID=SL.ID
	group by SL.PMCo, SL.[Contract], SL.ID, c.PMCo, c.[Contract], c.ID, SL.Project, SL.VendorGroup, SL.Vendor, SL.SL, SL.Amount, SL.ACO

	--insert dbo.vPMContractChangeOrderCommit (PMCo, [Contract], ID, Seq, Project, VendorGroup, Vendor,
	--	[Type], SLPO, ChangeOrder, [Status], Amount, DateSent, DateDueBack, DateReceived, DateApproved, ACO)
	--select i.PMCo, i.[Contract], i.ID, isnull(max(c.Seq),0) + row_number() over(order by c.PMCo, c.[Contract], c.ID), i.Project, sl.VendorGroup, sl.Vendor,
	--	'SL', sl.SL, null, null, isnull(sum(sl.Amount), 0), null, null, null, null, sl.ACO
	--from inserted i
	--join dbo.bPMSL sl on sl.PMCo=i.PMCo and sl.Project=i.Project and sl.ACO=i.ACO and sl.SL is not null
	--join dbo.vPMContractChangeOrderCommit c on c.PMCo=i.PMCo and c.[Contract]=i.[Contract] and c.ID=i.ID
	--where not exists (select top 1 1 from dbo.PMContractChangeOrderCommit co where co.PMCo=i.PMCo and
	--	co.[Contract]=i.[Contract] and co.ID=i.ID and co.ACO=i.ACO)
	--group by i.PMCo, i.[Contract], i.ID, c.PMCo, c.[Contract], c.ID, i.Project, sl.VendorGroup, sl.Vendor, sl.SL, sl.ACO
end
else
begin
	insert dbo.vPMContractChangeOrderCommit (PMCo, [Contract], ID, Seq, Project, VendorGroup, Vendor,
		[Type], SLPO, ChangeOrder, [Status], Amount, DateSent, DateDueBack, DateReceived, DateApproved, ACO)
	select i.PMCo, i.[Contract], i.ID, row_number() over (order by i.PMCo, i.[Contract], i.ID), 
		i.Project, sl.VendorGroup, sl.Vendor,
		'SL', sl.SL, null, null, isnull(sum(sl.Amount), 0), null, null, null, null, sl.ACO
	from inserted i
	join dbo.bPMSL sl on sl.PMCo=i.PMCo and sl.Project=i.Project and sl.ACO=i.ACO and sl.SL is not null
	group by i.PMCo, i.[Contract], i.ID, i.Project, sl.VendorGroup, sl.Vendor, sl.SL, sl.ACO
end

----PO
select @validcnt = count(*) from dbo.PMContractChangeOrderCommit c join inserted i on c.PMCo=i.PMCo and c.[Contract]=i.[Contract] and c.ID=i.ID
if @validcnt > 0
begin
	insert dbo.vPMContractChangeOrderCommit (PMCo, [Contract], ID, Seq, Project, VendorGroup, Vendor,
		[Type], SLPO, ChangeOrder, [Status], Amount, DateSent, DateDueBack, DateReceived, DateApproved, ACO)
	select PO.PMCo, PO.[Contract], PO.ID, isnull(max(c.Seq),0) + row_number() over(order by c.PMCo, c.[Contract], c.ID),
		PO.Project, PO.VendorGroup, PO.Vendor, 'PO', PO.PO, null, null, PO.Amount, null, null, null, null, PO.ACO
	from
	(
		select i.PMCo, i.[Contract], i.ID, i.Project, po.VendorGroup, po.Vendor, po.PO, isnull(sum(po.Amount), 0) as [Amount], po.ACO
		from inserted i
		join dbo.bPMMF po on po.PMCo=i.PMCo and po.Project=i.Project and po.ACO=i.ACO and po.PO is not null
		where not exists (select top 1 1 from dbo.PMContractChangeOrderCommit co where co.PMCo=i.PMCo and
			co.[Contract]=i.Contract and co.ID=i.ID and co.ACO=i.ACO)
		group by i.PMCo, i.[Contract], i.ID, i.Project, po.VendorGroup, po.Vendor, po.PO, po.ACO
	)
	PO
	join dbo.vPMContractChangeOrderCommit c on c.PMCo=PO.PMCo and c.[Contract]=PO.[Contract] and c.ID=PO.ID
	group by PO.PMCo, PO.[Contract], PO.ID, c.PMCo, c.[Contract], c.ID, PO.Project, PO.VendorGroup, PO.Vendor, PO.PO, PO.Amount, PO.ACO
	
	--select distinct i.PMCo, i.[Contract], i.ID, isnull(max(c.Seq),0) + row_number() over(order by c.PMCo, c.[Contract], c.ID), i.Project, po.VendorGroup, po.Vendor,
	--	'PO', po.PO, null, null, isnull(sum(po.Amount), 0), null, null, null, null, po.ACO
	--from inserted i
	--join dbo.bPMMF po on po.PMCo=i.PMCo and po.Project=i.Project and po.ACO=i.ACO and po.PO is not null
	--join dbo.vPMContractChangeOrderCommit c on c.PMCo=i.PMCo and c.[Contract]=i.[Contract] and c.ID=i.ID
	--where not exists (select top 1 1 from dbo.PMContractChangeOrderCommit co where co.PMCo=i.PMCo and
	--	co.[Contract]=i.[Contract] and co.ID=i.ID and co.ACO=i.ACO)
	--group by i.PMCo, i.[Contract], i.ID, c.PMCo, c.[Contract], c.ID, i.Project, po.VendorGroup, po.Vendor, po.PO, po.ACO
end
else
begin
	insert dbo.vPMContractChangeOrderCommit (PMCo, [Contract], ID, Seq, Project, VendorGroup, Vendor,
		[Type], SLPO, ChangeOrder, [Status], Amount, DateSent, DateDueBack, DateReceived, DateApproved, ACO)
	select i.PMCo, i.[Contract], i.ID, row_number() over (order by i.PMCo, i.[Contract], i.ID), 
		i.Project, po.VendorGroup, po.Vendor,
		'PO', po.PO, null, null, isnull(sum(po.Amount), 0), null, null, null, null, po.ACO
	from inserted i
	join dbo.bPMMF po on po.PMCo=i.PMCo and po.Project=i.Project and po.ACO=i.ACO and po.PO is not null
	group by i.PMCo, i.[Contract], i.ID, i.Project, po.VendorGroup, po.Vendor, po.PO, po.ACO
end




----TK-04796
---- update record and insert ACOID if missing
--SELECT p.KeyID
UPDATE dbo.vPMContractChangeOrderACO SET ACOID = p.KeyID
FROM inserted i
INNER JOIN dbo.vPMContractChangeOrderACO a ON a.KeyID=i.KeyID
INNER JOIN dbo.bPMOH p ON p.PMCo=i.PMCo AND p.Project=i.Project AND p.ACO=i.ACO

---- update record and insert CCOID if missing
----SELECT p.KeyID
UPDATE dbo.vPMContractChangeOrderACO SET CCOID = p.KeyID
FROM inserted i
INNER JOIN dbo.vPMContractChangeOrderACO a ON a.KeyID=i.KeyID
INNER JOIN dbo.vPMContractChangeOrder p ON p.PMCo=i.PMCo AND p.Contract=i.Contract AND p.ID=i.ID

-- TK-05322 --
-- UPDATE ReadyForAcctg FLAG --
	UPDATE	dbo.bPMOH SET ReadyForAcctg = 'N'
	  FROM	dbo.vPMContractChangeOrderACO i		-- ACOID value is not in the inserted values, but set in the table from above update statement
INNER JOIN	dbo.bPMOH p ON p.KeyID = i.ACOID

update dbo.bPMOI
set Approved = 'N'
from inserted i
inner join dbo.bPMOI p on p.PMCo=i.PMCo and p.Project=i.Project and p.ACO=i.ACO


---- create record relate for CCO and ACO
INSERT dbo.vPMRelateRecord (RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMContractChangeOrder', a.KeyID, 'PMOH', b.KeyID
FROM inserted i
INNER JOIN dbo.vPMContractChangeOrder a ON a.PMCo=i.PMCo AND a.Contract=i.Contract AND a.ID=i.ID
INNER JOIN dbo.bPMOH b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.ACO=i.ACO
WHERE i.ACO IS NOT NULL AND i.ID IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMContractChangeOrder'
				AND c.RECID=a.KeyID AND c.LinkTableName='PMOH' AND c.LINKID=b.KeyID)

---- create record relate for CCO and PCO
INSERT dbo.vPMRelateRecord (RecTableName, RECID, LinkTableName, LINKID)
SELECT DISTINCT 'PMContractChangeOrder', a.KeyID, 'PMOP', b.KeyID
FROM inserted i
INNER JOIN dbo.vPMContractChangeOrder a ON a.PMCo=i.PMCo AND a.Contract=i.Contract AND a.ID=i.ID
INNER JOIN dbo.bPMOP b ON b.PMCo=i.PMCo AND b.Project=i.Project AND b.PCOType=i.PCOType AND b.PCO=i.PCO
WHERE i.ACO IS NOT NULL AND i.ID IS NOT NULL
AND NOT EXISTS(SELECT 1 FROM dbo.vPMRelateRecord c WHERE c.RecTableName='PMContractChangeOrder'
				AND c.RECID=a.KeyID AND c.LinkTableName='PMOP' AND c.LINKID=b.KeyID)


---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vPMContractChangeOrder', ' Key: ' + convert(char(3), i.PMCo) + '/' + ISNULL(i.Contract,'') + '/' + ISNULL(i.Project,'') + '/'  + ISNULL(i.PCO,''),
       i.PMCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i



RETURN


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btPMContractChangeOrderACOu] on [dbo].[vPMContractChangeOrderACO] for UPDATE as
/*--------------------------------------------------------------
 * Created By:		GP 04/13/2011
 * Modified By:	    JayR 3/19/2012 TK-00000 Remove unneeded check this is now handled by constaints.  Remove unused variables.
 *
 *				
 * Validates columns.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- key fields cannot be changed
IF UPDATE(PMCo) OR UPDATE(Contract) OR UPDATE(ID) OR UPDATE(Seq)
BEGIN
    RAISERROR('Cannot change key fields - cannot update PMContractChangeOrderACO', 11, -1)
	ROLLBACK TRANSACTION
	RETURN
END

RETURN

	

GO
ALTER TABLE [dbo].[vPMContractChangeOrderACO] ADD CONSTRAINT [PK_vPMContractChangeOrderACO] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMContractChangeOrderACOSeq] ON [dbo].[vPMContractChangeOrderACO] ([PMCo], [Contract], [ID], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMContractChangeOrderACO] WITH NOCHECK ADD CONSTRAINT [FK_bPMOH_vPMContractChangeOrderACO_ACOID] FOREIGN KEY ([ACOID]) REFERENCES [dbo].[bPMOH] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMContractChangeOrderACO] WITH NOCHECK ADD CONSTRAINT [FK_vPMContractChangeOrder_vPMContractChangeOrderACO_CCOID] FOREIGN KEY ([CCOID]) REFERENCES [dbo].[vPMContractChangeOrder] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMContractChangeOrderACO] WITH NOCHECK ADD CONSTRAINT [FK_vPMContractChangeOrderACO_bJCCM] FOREIGN KEY ([PMCo], [Contract]) REFERENCES [dbo].[bJCCM] ([JCCo], [Contract])
GO
