SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***************************************/
CREATE proc [dbo].[vspPMInterfaceACOPost]
/*************************************
* Created By:	GF 05/20/2011 TK-05437
* Modified By:	GF 02/15/2012 TK-12748 #145870 do not try to update force phase item to JCJP if the phase is inactive. trigger error occurs
*
* USAGE:
*
* used by PMInterface to post an approved change order (ACO)
* from PM to JC. This post procedure just posts to Job Cost.
* PO, SL, MO, MS are handle in their individual post procedures.
*
*
* Pass in :
* PMCo, Mth, Project, ACO
*
* Output
* Status, errmsg
*
* Returns
* Error message and return code
*******************************/
(@PMCo bCompany = 0, @Project bJob = NULL, @Mth bMonth = NULL,
 @ACO VARCHAR(10) = NULL,
 @errmsg varchar(255) output)
AS
SET NOCOUNT ON

declare @rcode int, @DatePosted bDate, @Contract bContract,
   		@totalcount int, @updatecount int, @insertcount int, @forcephase bYN,
   		@phasegroup bGroup, @phase bPhase, @costtype bJCCType,
   		@pmoh_jcoh_ud_flag bYN, @pmoi_jcoi_ud_flag bYN, @columnname varchar(120),
		@joins VARCHAR(MAX), @where VARCHAR(MAX), @msg varchar(255)
		 
SET @rcode = 0
SET @pmoh_jcoh_ud_flag = 'N'
SET @pmoi_jcoi_ud_flag = 'N'
SET @DatePosted = dbo.vfDateOnly() 

---- validate parameters
If isnull(@PMCo,0) = 0 or isnull(@Mth,'') = '' or isnull(@Project,'') = ''
	BEGIN
	select @errmsg = 'Missing Company, Project, or Month', @rcode = 1
	goto vspexit
	END
	
IF ISNULL(@ACO,'') = ''
	BEGIN
	SELECT @errmsg = 'Missing ACO to interface', @rcode = 1
	GOTO vspexit
	END

---- pseudo cursor to check for like named user memos in PMOH and JCOH to be updated
select @columnname = min(name) from syscolumns where name like 'ud%' and id = object_id('dbo.bPMOH')
while @columnname is not null
begin
	if exists(select * from syscolumns where name = @columnname and id = object_id('dbo.bJCOH'))
	begin
		select @pmoh_jcoh_ud_flag = 'Y'
		goto JCOHUDCHECK_DONE
	end

	select @columnname = min(name)
	from syscolumns
	where name like 'ud%' and id = object_id('dbo.PMOH') and name > @columnname
	if @@rowcount = 0 
	begin
		select @columnname = null
	end
end
JCOHUDCHECK_DONE:


-- pseudo cursor to check for like named user memos in PMOI and JCOI to be updated
select @columnname = min(name)
from syscolumns 
where name like 'ud%' and id = object_id('dbo.bPMOI')
while @columnname is not null
begin
	if exists(select * from syscolumns where name = @columnname and id = object_id('dbo.bJCOI'))
	begin
		select @pmoi_jcoi_ud_flag = 'Y'
		goto JCOIUDCHECK_DONE
	end

	select @columnname = min(name)
	from syscolumns
	where name like 'ud%' and id = object_id('dbo.PMOi') and name > @columnname
	if @@rowcount = 0 
	begin
		select @columnname = null
	end
end
JCOIUDCHECK_DONE:


---- get contract for the project
Select @Contract = [Contract]
from dbo.bJCJM WITH (NOLOCK)
where JCCo=@PMCo and Job=@Project

---- update the contract status to open if pending
Update dbo.bJCCM SET ContractStatus = 1
where JCCo=@PMCo and [Contract]=@Contract
and ContractStatus = 0

---- Need to update the Job Status to open if still set to pending
Update dbo.bJCJM SET JobStatus=1
where JCCo=@PMCo and Job=@Project
and JobStatus = 0



---- Approved Change Order, update JCCH/JCJP

-- update JCCH
UPDATE dbo.bJCCH SET SourceStatus='I',
					ActiveYN='Y',
					InterfaceDate = dbo.vfDateOnly()
FROM dbo.bJCCH jcch
INNER JOIN dbo.bPMOL pmol on jcch.JCCo=pmol.PMCo AND jcch.Job=pmol.Project
	AND jcch.PhaseGroup=pmol.PhaseGroup AND jcch.Phase=pmol.Phase
	AND jcch.CostType=pmol.CostType
WHERE jcch.JCCo=@PMCo AND jcch.Job=@Project
AND pmol.ACO=@ACO AND jcch.SourceStatus = 'Y'
AND pmol.SendYN = 'Y'

---- update JCJP with contract item if force phase flag is yes
UPDATE dbo.bJCJP SET Item=pmoi.ContractItem
from dbo.bJCJP jcjp 
INNER JOIN dbo.bPMOL pmol on jcjp.JCCo=pmol.PMCo AND jcjp.Job=pmol.Project 
		AND jcjp.PhaseGroup=pmol.PhaseGroup AND jcjp.Phase=pmol.Phase
INNER JOIN dbo.bPMOI pmoi on pmoi.PMCo=pmol.PMCo AND pmoi.Project=pmol.Project
		AND pmoi.ACO=pmol.ACO AND pmoi.ACOItem=pmol.ACOItem
WHERE jcjp.JCCo=@PMCo AND jcjp.Job=@Project
	AND pmol.ACO=@ACO
	AND pmol.SendYN='Y'
	----TK-12748
	AND pmoi.ForcePhaseYN='Y'
	AND jcjp.ActiveYN = 'Y'
	AND jcjp.Item <> pmoi.ContractItem



---- begin transaction for JC update
BEGIN TRANSACTION

---- insert Approved Change Order into JCOH, JCOI and JCOD if needed
---- First try to update the change order JCOH
UPDATE dbo.bJCOH SET [Description]=p.[Description],
					 NewCmplDate=p.NewCmplDate,
					 BillGroup=p.BillGroup,
					 IntExt=isnull(p.IntExt,'E'),
					 Notes = p.Notes
FROM dbo.bPMOH p
INNER JOIN dbo.bJCOH j ON j.JCCo=p.PMCo AND j.Job=p.Project AND j.ACO=p.ACO
WHERE p.PMCo=@PMCo AND p.Project=@Project AND p.ACO=@ACO
if @@rowcount = 0
	BEGIN
	---- Insert Change Order Header
	INSERT INTO dbo.bJCOH (JCCo, Job, ACO, ACOSequence, Contract, Description, ApprovedBy,
				ApprovalDate, ChangeDays, NewCmplDate, BillGroup, IntExt, Notes)
	SELECT @PMCo, @Project, @ACO, h.ACOSequence, @Contract, h.Description, h.ApprovedBy,
				h.ApprovalDate, 0, h.NewCmplDate, h.BillGroup, isnull(h.IntExt,'E'),
				h.Notes
	from dbo.bPMOH h
	where h.PMCo=@PMCo AND h.Project=@Project AND h.ACO=@ACO
	AND NOT EXISTS(SELECT 1 FROM dbo.JCOH j WHERE j.JCCo=h.PMCo
					AND j.Job=h.Project AND j.ACO=h.ACO)

	-- copy user memos if any
	if @pmoh_jcoh_ud_flag = 'Y'
		BEGIN
		-- build joins and where clause
		SELECT @joins = ' from PMOH INNER JOIN JCOH z ON z.JCCo= ' + convert(varchar(3),@PMCo) +
						' and z.Job= ' + CHAR(39) + @Project + CHAR(39) +
						' and z.ACO= ' + CHAR(39) + @ACO + CHAR(39)
		SELECT @where = ' where PMOH.PMCo = ' + convert(varchar(3),@PMCo) + +
						' and PMOH.Project = ' + CHAR(39) + @Project + CHAR(39) +
						' and PMOH.ACO = ' + CHAR(39) + @ACO + CHAR(39)
		-- execute user memo update
		EXEC @rcode = dbo.bspPMPCOApproveUserMemoCopy 'PMOH', 'JCOH', @joins, @where, @msg output
		END		
	END


---- now update - insert the change order items JCOH
---- update interfaced date, interfaced by in bPMOI for ACO Items
---- that exist in bJCOI and will be updated
UPDATE dbo.bPMOI SET InterfacedBy = SUSER_SNAME(),
					 InterfacedDate = dbo.vfDateOnly()
from dbo.bPMOI p 
INNER JOIN dbo.bJCOI j on j.JCCo=p.PMCo and j.Job=p.Project and j.ACO=p.ACO and j.ACOItem=p.ACOItem
WHERE p.PMCo=@PMCo AND p.Project=@Project AND p.ACO=@ACO
AND (j.[Description] <> p.[Description]
	 OR j.Item<>p.ContractItem
	 OR j.ContractUnits <> p.Units 
	 OR j.ContUnitPrice <> p.UnitPrice
	 OR j.ContractAmt <> p.ApprovedAmt
	 OR j.BillGroup <> p.BillGroup 
	 OR j.ChangeDays <> p.ChangeDays)

---- update interfaced date, interfaced by in bPMOI for ACO Items that do not exist in bJCOI
UPDATE dbo.bPMOI SET InterfacedBy = SUSER_SNAME(),
					 InterfacedDate = dbo.vfDateOnly()
from dbo.bPMOI p 
where p.PMCo=@PMCo and p.Project=@Project and p.ACO=@ACO 
AND NOT EXISTS(select 1 from dbo.bJCOI j WHERE j.JCCo = p.PMCo AND j.Job = p.Project
					AND j.ACO = p.ACO AND j.ACOItem = p.ACOItem)

---- get count of PM ACO Items
SELECT @totalcount = (select count(*) from dbo.bPMOI where PMCo=@PMCo and Project=@Project and ACO=@ACO)

---- Update Change Order Items (bJCOI)	
UPDATE dbo.bJCOI SET [Description] = p.[Description],
					 Item = p.ContractItem,
					 ContractUnits = isnull(p.Units,0),
					 ContUnitPrice = isnull(p.UnitPrice,0),
					 ContractAmt = isnull(p.ApprovedAmt,0),
					 BillGroup = p.BillGroup,
					 ChangeDays = p.ChangeDays 
FROM dbo.bPMOI p 
INNER JOIN dbo.bJCOI j on j.JCCo=p.PMCo and j.Job=p.Project and j.ACO=p.ACO and j.ACOItem=p.ACOItem 
where p.PMCo=@PMCo and p.Project=@Project and p.ACO=@ACO
SELECT @updatecount = @@ROWCOUNT

---- insert Change Order Items if update does not work
insert into dbo.bJCOI (JCCo, Job, ACO, ACOItem, [Contract], Item, [Description], ApprovedMonth,
				ContractUnits, ContUnitPrice, ContractAmt, BillGroup, ChangeDays, Notes)
SELECT p.PMCo, p.Project, p.ACO, p.ACOItem, p.[Contract], p.ContractItem, p.[Description], @Mth,
				isnull(p.Units,0), isnull(p.UnitPrice,0), isnull(p.ApprovedAmt,0), p.BillGroup,
				p.ChangeDays, p.Notes
from dbo.bPMOI p
WHERE p.PMCo = @PMCo AND p.Project = @Project AND p.ACO = @ACO
AND NOT EXISTS(SELECT 1 FROM dbo.bJCOI j WHERE j.JCCo = p.PMCo AND j.Job = p.Project
			AND j.ACO = p.ACO AND j.ACOItem = p.ACOItem)
SELECT @insertcount = @@ROWCOUNT

---- check counts
if @updatecount + @insertcount <> @totalcount
	BEGIN
	ROLLBACK TRANSACTION
	select @errmsg = 'Error inserting JC Change Order Items.', @rcode=1
	goto vspexit
	END



---- update change order item detail (bJCOD)
SET @insertcount = 0
SET @totalcount = 0
SET @updatecount = 0

---- get count of PM change order detail lines
SELECT @totalcount =
	(select count(*)
		FROM dbo.bPMOL l INNER JOIN dbo.bPMOI i
		ON i.PMCo=l.PMCo AND i.Project=l.Project AND i.ACO=l.ACO AND i.ACOItem=l.ACOItem
		WHERE l.PMCo = @PMCo AND l.Project = @Project AND l.ACO = @ACO
		AND l.SendYN = 'Y' AND l.InterfacedDate is null)


---- update existing detail in JCOD
UPDATE dbo.bJCOD SET UnitCost   = isnull(p.UnitCost,0),
					 EstHours   = isnull(p.EstHours,0),
					 EstUnits   = isnull(p.EstUnits,0),
					 EstCost    = isnull(p.EstCost,0),
					 MonthAdded = @Mth
FROM dbo.bPMOL p 
INNER JOIN dbo.bJCOD j ON j.JCCo=p.PMCo AND j.Job=p.Project AND j.ACO=p.ACO
		AND j.ACOItem=p.ACOItem AND p.PhaseGroup=j.PhaseGroup AND p.Phase=j.Phase
		AND p.CostType=j.CostType
WHERE p.PMCo=@PMCo AND p.Project=@Project
		AND p.ACO=@ACO
		AND p.SendYN = 'Y'
		AND p.InterfacedDate IS NULL
SELECT @updatecount = @@ROWCOUNT

---- insert Change Order Items Detail
INSERT INTO dbo.bJCOD (JCCo, Job, ACO, ACOItem, PhaseGroup, Phase, CostType, MonthAdded,
				UM, UnitCost, EstHours, EstUnits, EstCost)
SELECT p.PMCo, p.Project, p.ACO, p.ACOItem, p.PhaseGroup, p.Phase, p.CostType, @Mth,
				p.UM, isnull(p.UnitCost,0), isnull(p.EstHours,0), isnull(p.EstUnits,0),
				isnull(p.EstCost,0)
from dbo.bPMOL p  
INNER JOIN dbo.bPMOI i ON i.PMCo=p.PMCo AND i.Project=p.Project AND i.ACO=p.ACO AND i.ACOItem=p.ACOItem
WHERE p.PMCo = @PMCo 
		AND p.Project = @Project 
		AND p.ACO = @ACO
		AND p.SendYN='Y'
		AND p.InterfacedDate IS NULL
AND NOT EXISTS(SELECT 1 FROM dbo.bJCOD d WHERE d.JCCo=p.PMCo AND d.Job=p.Project
				AND d.ACO=p.ACO AND d.ACOItem=p.ACOItem AND d.PhaseGroup=p.PhaseGroup
				AND d.Phase=p.Phase AND d.CostType=p.CostType)
SELECT @insertcount = @@ROWCOUNT

---- check counts
if @updatecount + @insertcount <> @totalcount
	BEGIN
	ROLLBACK TRANSACTION
	SELECT @errmsg = 'Error inserting Change Order Detail.', @rcode=1
	GOTO vspexit
	END


----  update interface in bPMOL
UPDATE dbo.bPMOL SET InterfacedDate = dbo.vfDateOnly()
FROM dbo.bPMOL p 
INNER JOIN dbo.bPMOI i ON i.PMCo=p.PMCo and i.Project=p.Project and i.ACO=p.ACO and i.ACOItem=p.ACOItem
WHERE p.PMCo=@PMCo AND p.Project=@Project AND p.ACO=@ACO
	AND p.SendYN='Y'
	AND p.InterfacedDate IS NULL


---- WHEN ALL items and lines are interfaced
---- set the ready for accounting flag to 'N'
UPDATE dbo.bPMOH SET ReadyForAcctg = 'N'
FROM dbo.bPMOH h
WHERE h.PMCo = @PMCo
	AND h.Project = @Project
	AND h.ACO = @ACO
	AND NOT EXISTS(SELECT 1 FROM dbo.bPMOI i WHERE i.PMCo=h.PMCo AND i.Project=h.Project
					AND i.ACO=h.ACO AND i.InterfacedDate IS NULL)
	AND NOT EXISTS(SELECT 1 FROM dbo.bPMOL l WHERE l.PMCo=h.PMCo AND l.Project=h.Project
					AND l.ACO=h.ACO AND l.InterfacedDate IS NULL)


			
---- COMMIT
COMMIT TRANSACTION




select @errmsg = 'Interface completed successfully! ', @rcode = 0

	
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMInterfaceACOPost] TO [public]
GO
