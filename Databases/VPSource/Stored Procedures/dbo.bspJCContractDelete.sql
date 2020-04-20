SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCContractDelete    Script Date: 8/28/99 9:35:02 AM ******/
CREATE           proc [dbo].[bspJCContractDelete]
/***********************************************************
* CREATED BY:	CJW 3/25/1997
* MODIFIED By:	CJW 3/25/1997
*				GR 10/19/1999	- additional checks before purging
*									check in all the batch tables of AP, AR, PO, SL, EM, JB
*									check in PM tables
*				GR 11/6/1999	- Removed the checks from batch tables
*									now the check is in PM, JB and JC tables before purging
*				GR 11/18/1999	- completely modified, now checks in JC tables
*									and deletes from JC, PM and EMJT tables
*				GR	12/4/1999	- Added more checks as per discussion with Carol and Gary
*									checks in all batch tables AP, PO, SL, JBIN, PMMF, PMSL, PMOH,
*									PRTH, EMBF, EMLB, EMJT and JC tables
*				GR	04/18/2000	- Commented the check on bJCAJ as per issue# 6139
*				GR	6/15/2000	- corrected the where clause on bPOIT
*				GR	09/29/2000	- Corrected the check on Missing Contract for is null and ''
*				GR	11/30/2000	- added deleltion of PMTM
*				GF	05/01/2001	- issue #13276 deleting job with PMMF/PMSL exists.
*				DANF 01/25/2002 - ISSUE #15992 remove EMJT error message.
*				DANF 01/25/2002 - ISSUE #15896 Added restriction to check the lenght of the table
*				DANF 10/25/2002 - ISSUE #16040 Changed insert to bJCHJ for cost information.
*				GF	01/28/2002	- ISSUE #16045 Changes to PM delete section. Redid again on 2/05.
*									NEW TABLE FOR 5.7 build (PMSS). if installed on customer rem out this table.
*				DANF 02/02/2002 - ISSUE #16193 Removed join from JCJP on the insert of detail into JCHJ.
*				DANF 02/07/2002 - ISSUE #16198 Added ClosePurgeFlag to JCJM to speed up the delete trigger on JCCD.
*				DANF 04/15/2002 - Fix contract only purge.
*				GF	04/17/2002	- Added more PM tables.
*				GF	07/15/2002	- Added additional columns to bJCHC table for BilledUnits, BilledAmt updated from bJCCI.
*				GF	05/12/2003	- issue #19184 - added check for INMI where remaining units are not zero.
*				DC	6/05/2003	- Issue #18384 / Add inputs to update Job History
*				DANF 08/14/2003 - issue #21071 - added Close Purge flag to JCCM for contract item delete trigger.
*				DC	3/3/2004	- Issue 18384  / Carol changed her mind. 
*				TV				- 23061 added isnulls
*				DC	7/22/2004	- Purge Updates Summary History tables when box unchecked
*				DANF 09/01/2004	- Issue 21925 Update Summary Contract History with selected Cost Types and Corrected Units.
*				GF	12/05/2007	- issue #126414 added bPMED and bPMEH tables (Project Budgets)
*				GP	06/02/2008	- Issue #25194 Clean up Contract Purge back end procedures. Remove dead code, add nolocks,
*									and remove checks for Contract delete types that no longer exist.
*				GF	01/10/2008	- issue #129669 distribute add-on proportionally
*				gf	08/31/2009	- issue #129897 added table vJCForecastMonth
*				CHS 10/26/2009	- issue #135986 added table bJCJR
*				CHS 01/14/2010	- issue #135527 
*				DC 6/29/10 - #135813 - expand subcontract number 
*				GF 03/24/2011 - TK-03291
*				GF 04/06/2011 - TK-03569
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*
* USAGE:
* Purges Contracts
* an error is returned if any of the following occurs
* 	???
*
* TYPE DEFINITION:
* INPUT PARAMETERS
*   JCCo to validate against
*   Contract  Contract to validate
*   TYPE	0 = Delete Job and do not add summary to history tables
*			1 = Delete Contract and do not add summary to history tables
*			2 = Delete Job and do add summary to history tables
*			3 = Delete Contract and do add summary to history tables
*
* OUTPUT PARAMETERS
*
*   @msg      error message if error occurs otherwise Description of Contract
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/   
(@Company bCompany = 0, @Contract bContract = null, @Job bJob = null, @Type int = null, 
	@HoursCostTypes varchar(60) =null, @msg varchar(255) output)

as

set nocount on
declare @rcode int, @UseJobBilling bYN, @Status tinyint, @cursoropen tinyint, @validcount tinyint,
	@opendelete int, @tablename varchar(30), @sqlstring varchar(255), @sql1 varchar(30), @openpoitem int,
	@po varchar(30), @poitem bItem, @openslitem int, @sl VARCHAR(30), -- bSL, DC #135813
	@slitem bItem, @slunits bUnits,
	@mo bMO, @moitem bItem, @mounits bUnits, @openmoitem int

select @rcode = 0, @opendelete =0, @openpoitem=0, @openslitem=0, @openmoitem=0

-- Some initial validation

if @Company is null
	begin
	select @msg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end
   
if (@Contract is null) or (@Contract = '')
	begin
	select @msg = 'Missing Contract!', @rcode = 1
	goto bspexit
	end
   
--ARBH
select @validcount=count(1) from bARBH with(nolock) where bARBH.Contract=@Contract and bARBH.JCCo=@Company
if @validcount>0
	begin
	select @msg = 'Contract in ARBH - Cannot purge', @rcode = 1					/*AR Batch*/
	goto bspexit
	end
   
--JBIN
select @validcount = Count(1) from bJBIN with(nolock)
where JBCo=@Company and Contract=@Contract and InvStatus in ('C','D','A')
if @validcount > 0
	begin
	select @msg = 'Contract in JBIN - Cannot purge', @rcode = 1	
	goto bspexit
	end
   
--JCIA
select @validcount=count(1) from bJCIA with(nolock) where Contract=@Contract and JCCo=@Company
if @validcount>0
	begin
	select @msg = 'Contract in JCIA - Cannot purge', @rcode = 1
	goto bspexit
	end

select @validcount=count(1) from bJCIB with(nolock) where Contract=@Contract and Co=@Company		/*Item Trans Batch*/
if @validcount>0
	begin
	select @msg = 'Contract in JCIB - Cannot purge', @rcode = 1
	goto bspexit
	end

select @validcount=count(1) from bJCCC with(nolock) where Contract=@Contract and Co=@Company		/*Item Trans Batch*/
if @validcount>0
	begin
	select @msg = 'Contract in JCCC - Cannot purge', @rcode = 1
	goto bspexit
	end

select @validcount=count(1) from bJCXB with(nolock) where Co=@Company and Contract=@Contract
if @validcount > 0
	begin
	select @msg='Contract in JCXB - Cannot Purge', @rcode = 1
	goto bspexit
	end
   
-- job delete
if @Type=0 or @Type = 2 --DC Issue #18384
	begin
   
	--APLB
	select @validcount=Count(1) from bAPLB with(nolock)
	where (Job = @Job and JCCo = @Company) or (OldJob = @Job and OldJCCo = @Company)
	if @validcount>0
		begin
		select @msg= 'Job in APLB - Cannot purge', @rcode=1
		goto bspexit
		end
   
	--APUL
	select @validcount=Count(1) from bAPUL with(nolock)
	where Job = @Job and JCCo=@Company
	if @validcount>0
		begin
		select @msg= 'Job in APUL - Cannot purge', @rcode=1
		goto bspexit
		end
   
	--APRL
	select @validcount=Count(1) from bAPRL with(nolock)
	where Job = @Job and JCCo=@Company
	if @validcount>0
		begin
		select @msg= 'Job in APRL - Cannot purge', @rcode=1
		goto bspexit
		end

	--ARBL
	select @validcount=Count(1) from bARBL with(nolock)
	where (JCCo = @Company and Job = @Job) or (oldJCCo = @Company and oldJob = @Job)
	if @validcount>0
		begin
		select @msg= 'Job in ARBL - Cannot purge', @rcode=1
		goto bspexit
		end

	--bEMBF
	select @validcount=Count(1) from bEMBF with(nolock)
	where (JCCo = @Company and Job = @Job) or (OldJCCo = @Company and OldJob = @Job)
	if @validcount>0
		begin
		select @msg= 'Job in EMBF - Cannot purge', @rcode=1
		goto bspexit
		end

	--bEMLB
	select @validcount=Count(1) from bEMLB with(nolock)
	where (FromJCCo = @Company and FromJob = @Job) or (ToJCCo = @Company and ToJob = @Job) or
	   (OldFromJCCo = @Company and OldFromJob = @Job) or
	   (OldToJCCo = @Company and OldToJob = @Job)
	if @validcount>0
		begin
		select @msg= 'Job in EMBF - Cannot purge', @rcode=1
		goto bspexit
		end
   
	--POCA
	select @validcount=Count(1) from bPOCA with(nolock)
	where JCCo = @Company and Job = @Job
	if @validcount>0
		begin
		select @msg = 'Job in POCA - Cannot purge', @rcode = 1
		goto bspexit
		end

	--PORA
	select @validcount=Count(1) from bPORA with(nolock)
	where JCCo = @Company and Job = @Job
	if @validcount>0
		begin
		select @msg = 'Job in PORA - Cannot purge', @rcode = 1
		goto bspexit
		end
   
	--POXA
	select @validcount=Count(1) from bPOXA with(nolock)
	where JCCo = @Company and Job = @Job
	if @validcount>0
		begin
		select @msg = 'Job in POXA - Cannot purge', @rcode = 1
		goto bspexit
		end

	--POIB
	select @validcount=Count(1) from bPOIB with(nolock)
	where (PostToCo = @Company and Job = @Job) or (OldPostToCo = @Company and OldJob = @Job)
	if @validcount>0
		begin
		select @msg = 'Job in POIB - Cannot purge', @rcode = 1
		goto bspexit
		end

	--POIT
	declare poitem_cursor cursor for
	select bPOIT.PO, bPOIT.POItem from bPOIT with(nolock)
	join bPOHD on bPOHD.POCo=bPOIT.POCo and bPOHD.PO=bPOIT.PO
	where bPOIT.PostToCo=@Company and bPOIT.Job = @Job and bPOHD.Status<>2
		and (bPOIT.RemUnits <> 0 or bPOIT.RemCost <> 0 or bPOIT.RemTax <> 0)
   
	open poitem_cursor
	select @openpoitem=1

	poitem_cursor_loop:             --loop through all the records
	fetch next from poitem_cursor into @po, @poitem
   
	if @@fetch_status = 0
		begin
		select @msg = 'Job ' + @Job + ' exists in POIT for PO#: ' + isnull(@po,'') + ', Item: ' + isnull(convert(varchar(6), @poitem),''), @rcode = 1
		close poitem_cursor
		deallocate poitem_cursor
		select @openpoitem = 0
		goto bspexit
		end
   
	--close and deallocate cursor
	if @openpoitem = 1
		begin
		close poitem_cursor
		deallocate poitem_cursor
		select @openpoitem=0
		end

	--bPRTH
	select @validcount=Count(1) from bPRTH with(nolock) join bPRPC on
	bPRPC.PRCo = bPRTH.PRCo and bPRPC.PRGroup = bPRTH.PRGroup and bPRPC.PREndDate = bPRTH.PREndDate
	where bPRTH.JCCo = @Company and bPRTH.Job = @Job and bPRPC.JCInterface = 'N'
	if @validcount>0
		begin
		select @msg = 'Job in PRTH - Cannot purge', @rcode = 1
		goto bspexit
		end

	--bSLCA
	select @validcount=Count(1) from bSLCA with(nolock)
	where JCCo = @Company and Job = @Job
	if @validcount>0
		begin
		select @msg = 'Job in SLCA - Cannot purge', @rcode = 1
		goto bspexit
		end

	--bSLXA
	select @validcount=Count(1) from bSLXA with(nolock)
	where JCCo = @Company and Job = @Job
	if @validcount>0
		begin
		select @msg = 'Job in SLXA - Cannot purge', @rcode = 1
		goto bspexit
		end

	--bSLIB
	select @validcount=Count(1) from bSLIB with(nolock)
	where (JCCo = @Company and Job = @Job) or (OldJCCo = @Company and OldJob = @Job)
	if @validcount>0
		begin
		select @msg = 'Job in SLIB - Cannot purge', @rcode = 1
		goto bspexit
		end
   
	--SLIT
	declare sl_cursor cursor for
	select bSLIT.SL, bSLIT.SLItem,
		'Units' = case bSLIT.UM  when 'LS' then (bSLIT.CurCost - bSLIT.InvCost)
			 else (bSLIT.CurUnits - bSLIT.InvUnits) end
	from bSLIT with(nolock)
	join bSLHD on bSLHD.SLCo=bSLIT.SLCo and bSLHD.SL=bSLIT.SL and bSLHD.Status<>2
	where bSLIT.JCCo=@Company and bSLIT.Job = @Job
   
	open sl_cursor
	select @openslitem=1

	sl_cursor_loop:             --loop through all the records
	fetch next from sl_cursor into @sl, @slitem, @slunits
	if @@fetch_status = 0
		begin
		if @slunits <> 0
			begin
			select @msg = 'Job ' + @Job + ' exist in SLIT for SL#: ' + isnull(@sl,'') + ', Item: ' + isnull(convert(varchar(6), @slitem),''), @rcode=1
			close sl_cursor
			deallocate sl_cursor
			select @openslitem = 0
			goto bspexit
			end

		goto sl_cursor_loop           --get next record
		end

	--close and deallocate cursor
	if @openslitem=1
		begin
		close sl_cursor
		deallocate sl_cursor
		select @openslitem=0
		end
   
	--bINIB
	select @validcount=Count(1) from bINIB with(nolock)
	where (JCCo = @Company and Job = @Job) or (OldJCCo = @Company and OldJob = @Job)
	if @validcount>0
		begin
		select @msg = 'Job in INIB - Cannot purge', @rcode = 1
		goto bspexit
		end
   
	--INMI
	declare mo_cursor cursor for
	select bINMI.MO, bINMI.MOItem, bINMI.RemainUnits
	from bINMI with(nolock)
	join bINMO on bINMO.INCo=bINMI.INCo and bINMO.MO=bINMI.MO and bINMO.Status <> 2 and bINMI.RemainUnits <> 0
	where bINMI.JCCo=@Company and bINMI.Job = @Job

	open mo_cursor
	select @openmoitem=1

	mo_cursor_loop:             --loop through all the records
	fetch next from mo_cursor into @mo, @moitem, @mounits
	if @@fetch_status = 0
		begin
		if @mounits <> 0
			begin
			select @msg = 'Job ' + @Job + ' exist in INMI for MO#: ' + isnull(@mo,'') + ', Item: ' + isnull(convert(varchar(6), @moitem),''), @rcode=1
			close mo_cursor
			deallocate mo_cursor
			select @openmoitem = 0
			goto bspexit
			end

		goto mo_cursor_loop           --get next record
		end
   
	--close and deallocate cursor
	if @openmoitem=1
		begin
		close mo_cursor
		deallocate mo_cursor
		select @openmoitem=0
		end
   
	select @validcount=count(1) from bJCDA with(nolock) where Job=@Job and JCCo=@Company			/*CostAdjustmentGLBatch	*/
	if @validcount>0
		begin
		select @msg = 'Job in JCDA - Cannot purge', @rcode = 1
		goto bspexit
		end

	select @validcount=count(1) from bJCCB with(nolock) where Job=@Job and Co=@Company			/*CostAdjustmentBatch	*/
	if @validcount>0
		begin
		select @msg = 'Job in JCCB - Cannot purge', @rcode = 1
		goto bspexit
		end

	select @validcount=count(1) from bJCPB with(nolock) where Job=@Job and Co=@Company
	if @validcount>0
		begin
		select @msg = 'Job in JCPB - Cannot purge', @rcode = 1
		goto bspexit
		end

	select @validcount=count(1) from bJCCC with(nolock) where Job=@Job and Co=@Company		/*Item Trans Batch*/
	if @validcount>0
		begin
		select @msg = 'Job in JCCC - Cannot purge', @rcode = 1
		goto bspexit
		end
   
	select @validcount=count(1) from bJCPP with(nolock) where Job=@Job and Co=@Company		/*Item Trans Batch*/
	if @validcount>0
		begin
		select @msg = 'Job in JCPP - Cannot purge', @rcode = 1
		goto bspexit
		end
	end
   
--DC Issue 18384 ----  START--------------------------------------
If @Type=0 or @Type = 2 --DC Issue #18384										--JOB
	BEGIN
   	UPDATE bJCJM set ClosePurgeFlag='Y'
	where bJCJM.Job=@Job and bJCJM.JCCo=@Company
   	IF @Type = 2  -- Replace existing data
		BEGIN
		--Delete Job from bJCHJ 
		if exists (select 1 from bJCHJ where JCCo=@Company and Job=@Job)
			BEGIN
			DELETE bJCHJ where JCCo=@Company and Job=@Job
			END
			
		INSERT INTO bJCHJ(JCCo,Contract,Item,Job,PhaseGroup,Phase,CostType,JobDesc,PhaseDesc,ProjMgr,UM,
			ActualHours,ActualUnits,ActualCost,OrigEstHours,OrigEstUnits,OrigEstCost,
			CurrEstHours,CurrEstUnits,CurrEstCost,ProjHours,ProjUnits,ProjCost,ItemUnitFlag)
		SELECT bJCCP.JCCo,bJCJP.Contract,bJCJP.Item,bJCCP.Job,
			bJCCP.PhaseGroup,bJCCP.Phase,bJCCP.CostType,bJCJM.Description,
			bJCJP.Description,bJCJM.ProjectMgr,bJCCH.UM,
			sum(bJCCP.ActualHours),sum(bJCCP.ActualUnits),sum(bJCCP.ActualCost),
			sum(bJCCP.OrigEstHours),sum(bJCCP.OrigEstUnits),sum(bJCCP.OrigEstCost),
			sum(bJCCP.CurrEstHours),sum(bJCCP.CurrEstUnits),sum(bJCCP.CurrEstCost),
			sum(bJCCP.ProjHours),sum(bJCCP.ProjUnits),sum(bJCCP.ProjCost),
			bJCCH.ItemUnitFlag
		FROM bJCCP with(nolock)
		join bJCJP on bJCJP.JCCo=bJCCP.JCCo and bJCJP.Job=bJCCP.Job and bJCJP.PhaseGroup=bJCCP.PhaseGroup and
			bJCJP.Phase=bJCCP.Phase
		join bJCJM on bJCJM.JCCo=bJCCP.JCCo and bJCJM.Job=bJCCP.Job
		join bJCCH on bJCCH.JCCo = bJCCP.JCCo and bJCCH.Job = bJCCP.Job and bJCCH.PhaseGroup=bJCCP.PhaseGroup and
			bJCCH.Phase=bJCCP.Phase and bJCCH.CostType=bJCCP.CostType
		WHERE bJCCP.JCCo=@Company and bJCCP.Job=@Job
		GROUP BY bJCCP.JCCo, bJCJP.Contract, bJCJP.Item, bJCCP.Job, bJCCP.PhaseGroup, bJCCP.Phase, bJCCP.CostType,
			bJCJM.Description, bJCJM.ProjectMgr, bJCCH.UM, bJCJP.Description,bJCCH.ItemUnitFlag
		END
   
	--Delete ApprovedChgOrderDetail Moved to before purging PM tables issue #15896
	DELETE bJCOD	
	where JCCo = @Company and Job =@Job
   
	--Delete from PM tables -- Issue 15896  added and len(object_name(id)) = 5 to where clause
	--PM Tables with no delete trigger
	delete bPMBC where Co=@Company and Project=@Job
	delete bPMBE where Co=@Company and Project=@Job
	delete bPMCD where PMCo=@Company and Project=@Job
	delete bPMDC where PMCo=@Company and Project=@Job
	delete bPMDH where PMCo=@Company and Project=@Job
	delete bPMIH where PMCo=@Company and Project=@Job
	delete bPMMD where PMCo=@Company and Project=@Job
	delete bPMMF where PMCo=@Company and Project=@Job
	delete bPMML where PMCo=@Company and Project=@Job
	delete bPMOA where PMCo=@Company and Project=@Job
	delete bPMOB where PMCo=@Company and Project=@Job
	delete bPMOC where PMCo=@Company and Project=@Job
	delete bPMOM where PMCo=@Company and Project=@Job
	delete bPMPA where PMCo=@Company and Project=@Job
	delete bPMPC where PMCo=@Company and Project=@Job
	delete bPMPD where PMCo=@Company and Project=@Job
	delete bPMQD where PMCo=@Company and Project=@Job
	delete bPMRD where PMCo=@Company and Project=@Job
	delete bPMSL where PMCo=@Company and Project=@Job
	delete bPMSI where PMCo=@Company and Project=@Job
	delete bPMSM where PMCo=@Company and Project=@Job
	delete bPMSS where PMCo=@Company and Project=@Job -- new table for 5.7 build
	delete bPMTC where PMCo=@Company and Project=@Job
	delete bPMTS where PMCo=@Company and Project=@Job
	delete bPMDR where PMCo=@Company and Project=@Job -- new table for 5.7 build
	delete bPMDG where PMCo=@Company and Project=@Job -- new table for 5.7 build
	delete bPMIL where PMCo=@Company and Project=@Job -- new table for 5.7 build
	delete bPMTL where PMCo=@Company and Project=@Job -- new table for 5.7 build
	delete bPMED where PMCo=@Company and Project=@Job -- new table for 6.x
	delete bPMEH where PMCo=@Company and Project=@Job -- new table for 6.x
	delete bPMDZ where PMCo=@Company and Project=@Job -- new table for 6.x
	-- PM tables with delete triggers
	delete bPMNR where PMCo=@Company and Project=@Job
	delete bPMPN where PMCo=@Company and Project=@Job
	delete bPMDD where PMCo=@Company and Project=@Job
	delete bPMDL where PMCo=@Company and Project=@Job
	delete bPMMI where PMCo=@Company and Project=@Job
	delete bPMMM where PMCo=@Company and Project=@Job
	delete bPMOD where PMCo=@Company and Project=@Job
	delete bPMOL where PMCo=@Company and Project=@Job
	delete bPMOI where PMCo=@Company and Project=@Job
	delete bPMOP where PMCo=@Company and Project=@Job
	delete bPMOH where PMCo=@Company and Project=@Job
	delete bPMPI where PMCo=@Company and Project=@Job
	delete bPMPL where PMCo=@Company and Project=@Job
	delete bPMPU where PMCo=@Company and Project=@Job
	delete bPMRI where PMCo=@Company and Project=@Job
	delete bPMRQ where PMCo=@Company and Project=@Job
	delete bPMTM where PMCo=@Company and Project=@Job
	delete bPMPF where PMCo=@Company and Project=@Job
	delete bPMIH where PMCo=@Company and Project=@Job -- special case check again before PMIM
	delete bPMDH where PMCo=@Company and Project=@Job
	delete bPMIM where PMCo=@Company and Project=@Job
	----TK-03291
	DELETE dbo.vPMSubcontractCO WHERE PMCo=@Company AND Project=@Job
	----TK-03569
	DELETE dbo.vPMPOCO WHERE PMCo=@Company AND Project=@Job
		
	DELETE bJCOI
	where JCCo=@Company and Job=@Job	--Delete ApprovedChgOrderItems

	DELETE bJCOH
	where JCCo=@Company and Job=@Job  --Delete ApprovedChgOrderHeader

	DELETE bJCCD
	where JCCo=@Company and Job=@Job	--Delete JCCD

	DELETE bJCCP
	where JCCo=@Company and Job=@Job	-- Delete CostByPeriod

	DELETE bJCAJ
	  where JCCo=@Company and Job=@Job	-- Allocation accounts

	DELETE bJCCH
	where JCCo=@Company and Job=@Job	 -- Delete CostHeader

	DELETE vJCJPRoles					 -- #135527
	where JCCo=@Company and Job=@Job	 -- Delete Job Phase Roles

	DELETE bJCJP
	where JCCo=@Company and Job=@Job	 -- Delete Job Phases
	
	DELETE vJCJobRoles					 -- #135527
	where JCCo=@Company and Job=@Job	 -- Delete Job Roles	
   
	DELETE bJCJM
	where JCCo=@Company and Job=@Job	 -- Delete Job Master

	DELETE bEMJT
	where JCCo=@Company and Job=@Job -- Delete EM Job Template
	
	---- #135986
	DELETE dbo.bJCJR
	where bJCJR.JCCo=@Company and bJCJR.Job=@Job	
	
	END
   
If @Type = 1 or @Type = 3 --DC Issue 18384 ------START--------------------------------------
	BEGIN
	update bJCCM set ClosePurgeFlag='Y'
	where bJCCM.Contract=@Contract and bJCCM.JCCo = @Company
   	IF @Type = 3  -- Replace existing data
   		BEGIN
		--Delete Job from bJCHC 
   		if exists (select 1 from bJCHC with(nolock) where JCCo=@Company and Contract=@Contract)
			BEGIN
			DELETE bJCHC where JCCo=@Company and Contract=@Contract
			END
			
		INSERT INTO bJCHC(JCCo,Contract,Item,MthClosed,ContractDesc,ItemDesc,UM,SIRegion,SICode,Department,
			OrigContractAmt,OrigContractUnits,OrigUnitPrice, FinalContractAmt,FinalContractUnits,FinalUnitPrice,
			ActualHours,ActualUnits,ActualCost,OrigEstHours,OrigEstUnits,OrigEstCost,CurrEstHours,
			CurrEstUnits,CurrEstCost,ProjHours,ProjUnits,ProjCost, BilledUnits, BilledAmt)
		SELECT bJCCI.JCCo, bJCCI.Contract,bJCCI.Item, bJCCM.MonthClosed,bJCCM.Description, bJCCI.Description, bJCCI.UM,
			bJCCI.SIRegion,bJCCI.SICode, bJCCI.Department,bJCCI.OrigContractAmt,bJCCI.OrigContractUnits,
			bJCCI.OrigUnitPrice,bJCCI.ContractAmt,bJCCI.ContractUnits,bJCCI.UnitPrice,
			(select isnull(sum(Hours.ActualHours),0)
			from bJCHJ Hours with(nolock)
			where 	bJCCI.JCCo=Hours.JCCo and 
					bJCCI.Contract = Hours.Contract and 
					bJCCI.Item = Hours.Item and 
					charindex(';' + rtrim(convert(varchar(3),Hours.CostType)) + ';',@HoursCostTypes) <> 0),
			(select isnull(sum(Units.ActualUnits),0)
			from bJCHJ Units with(nolock)
			where 	bJCCI.JCCo=Units.JCCo and 
					bJCCI.Contract = Units.Contract and 
					bJCCI.Item = Units.Item and 
					Units.ItemUnitFlag = 'Y' and 
					Units.UM = bJCCI.UM),
					isnull(sum(Cost.ActualCost),0),
			(select isnull(sum(Hours.OrigEstHours),0)
			from bJCHJ Hours with(nolock)
			where 	bJCCI.JCCo=Hours.JCCo and 
					bJCCI.Contract = Hours.Contract and 
					bJCCI.Item = Hours.Item and 
					charindex(';' + rtrim(convert(varchar(3),Hours.CostType)) + ';',@HoursCostTypes) <> 0),
			(select isnull(sum(Units.OrigEstUnits),0)
			from bJCHJ Units with(nolock)
			where 	bJCCI.JCCo=Units.JCCo and 
					bJCCI.Contract = Units.Contract and 
					bJCCI.Item = Units.Item and 
					Units.ItemUnitFlag = 'Y' and 
					Units.UM = bJCCI.UM),
					isnull(sum(Cost.OrigEstCost),0),
			(select isnull(sum(Hours.CurrEstHours),0)
			from bJCHJ Hours with(nolock)
			where 	bJCCI.JCCo=Hours.JCCo and 
					bJCCI.Contract = Hours.Contract and 
					bJCCI.Item = Hours.Item and 
					charindex(';' + rtrim(convert(varchar(3),Hours.CostType)) + ';',@HoursCostTypes) <> 0),
			(select isnull(sum(Units.CurrEstUnits),0)
			from bJCHJ Units with(nolock)
			where 	bJCCI.JCCo=Units.JCCo and 
					bJCCI.Contract = Units.Contract and 
					bJCCI.Item = Units.Item and 
					Units.ItemUnitFlag = 'Y' and 
					Units.UM = bJCCI.UM),
					isnull(sum(Cost.CurrEstCost),0),
			(select isnull(sum(Hours.ProjHours),0)
			from bJCHJ Hours with(nolock)
			where 	bJCCI.JCCo=Hours.JCCo and 
					bJCCI.Contract = Hours.Contract and 
					bJCCI.Item = Hours.Item and 
					charindex(';' + rtrim(convert(varchar(3),Hours.CostType)) + ';',@HoursCostTypes) <> 0),
			(select isnull(sum(Units.ProjUnits),0)
			from bJCHJ Units with(nolock)
			where 	bJCCI.JCCo=Units.JCCo and 
					bJCCI.Contract = Units.Contract and 
					bJCCI.Item = Units.Item and 
					Units.ItemUnitFlag = 'Y' and 
					Units.UM = bJCCI.UM),
				isnull(sum(Cost.ProjCost),0),
			bJCCI.BilledUnits, bJCCI.BilledAmt
		FROM bJCCI with(nolock)
		left join bJCHJ Cost on bJCCI.JCCo=Cost.JCCo and bJCCI.Contract = Cost.Contract and bJCCI.Item = Cost.Item
		join bJCCM on bJCCM.JCCo=bJCCI.JCCo and bJCCM.Contract=bJCCI.Contract
		WHERE bJCCI.JCCo=@Company and bJCCI.Contract=@Contract
		GROUP BY bJCCI.JCCo,bJCCI.Contract,bJCCI.Item,bJCCM.MonthClosed,bJCCM.Description,bJCCI.Description,bJCCI.UM,bJCCI.SIRegion,
			bJCCI.SICode,bJCCI.Department,bJCCI.OrigContractAmt,bJCCI.OrigContractUnits,bJCCI.OrigUnitPrice,
			bJCCI.ContractAmt,bJCCI.ContractUnits,bJCCI.UnitPrice,bJCCI.BilledUnits, bJCCI.BilledAmt
   		END
  
	-- delete in other PM Tables which has Contract
	delete bPMOI where PMCo=@Company and Contract=@Contract
	delete bPMOH where PMCo=@Company and Contract=@Contract
	delete bPMOP where PMCo=@Company and Contract=@Contract
	delete bPMPA where PMCo=@Company and Contract=@Contract
    
	DELETE bJCIP
	where bJCIP.JCCo=@Company and bJCIP.Contract=@Contract

	DELETE bJCID
	where bJCID.Contract=@Contract and bJCID.JCCo=@Company	   -- Delete Item Detail

	DELETE bJCCI
	 where Contract=@Contract and JCCo=@Company  	-- Delete Contract Items

	DELETE bJCCM
	where bJCCM.Contract=@Contract and bJCCM.JCCo=@Company	    -- Delete Contract Master

	DELETE bJCOI
	where bJCOI.JCCo=@Company and bJCOI.Contract=@Contract	  -- Double check ApprovedChgOrderItems
   
	DELETE bJCOH
	where bJCOH.Contract=@Contract and bJCOH.JCCo=@Company	  -- Double check Change order Header

	DELETE vJCJPRoles					 -- #135527
	where JCCo=@Company and Job=@Job	 -- Delete Job Phase Roles

	DELETE bJCJP
	where bJCJP.Contract=@Contract and bJCJP.JCCo=@Company	      -- Double check Job Phase

	DELETE vJCJobRoles					 -- #135527
	where JCCo=@Company and Job=@Job	 -- Delete Job Roles	

	DELETE bJCJM
	where bJCJM.JCCo=@Company and bJCJM.Contract=@Contract	  -- Double check Job Master

	DELETE bJCXB
	where Co = @Company and Contract =@Contract
	
	----#129897
	DELETE dbo.vJCForecastMonth
	where JCCo=@Company and Contract=@Contract
	   
	END
   
RETURN
   
bspexit:
if @opendelete=1
	begin
	close delete_cursor
	deallocate delete_cursor
	end
if @openpoitem=1
	begin
	close poitem_cursor
	deallocate poitem_cursor
	end
if @openslitem=1
	begin
	close sl_cursor
	deallocate sl_cursor
	end
if @openmoitem = 1
	begin
	close mo_cursor
	deallocate mo_cursor
	end
   
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJCContractDelete] TO [public]
GO
