SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************************/
CREATE  procedure [dbo].[vspPMPCOSAdd]
/************************************************************************
* Created By:	GF 06/05/2007 6.x
* Modified By:	GF 02/28/2008 issue #127210 - additional columns for PMOA
*				GF 02/29/2008 - issue #127195 and #127210 for 6.1.0
*				GF 01/10/2008 - issue #129669 set status to 'Y' when inserting addons
*				GF 03/05/2009 - issue #132046 - PCO internal add-on initialize
*				GF 08/03/2010 - issue #134354 use standard flag when inserting change order addons.
*				JG 08/12/2010 - issue #140529 - After new PCO is added, default distributions are coppied.
*				DAN SO 08/19/2010 - Issue #140529 - TFS #622 - allow new PCO from PM Project Issues form
*				GF 09/03/2010 - issue #141031 change to use date only function
*				DAN SO 11/01/2010 - Issue #140529 - TFS #1057 - Dev - Add Auto Relation to PM Issues
*				DAN SO 11/04/2010 - Issue #140529 - TFS #1069 - removing successful message
*				GF 12/21/2010 - issue #141957 record linking
*				GF 02/21/2011 - B-02489 - TK-01924
*				GP 06/22/2011 - TK-06318/06319/06320 Added Details, ROMAmount and Notes (looks at checkbox value) to PMOP insert
*				GF 06/22/2011 - D-02339 use view not tables for links
*				TL  07/12/2011 - TK-06773 (D-02473) added IsNull(@ROMAmount,0) create from an RFI on insert into PMOP
*				TK 08/09/2011 - TK-07581  changed "bPMOP" to "PMOP"
*				JayR 10/16/2012 TK-16099 Fix overlapping variables issue
*
* Purpose of Stored Procedure is to create a PCO and PCO Item from a source
* RFI Document. Currently called from PMPCOSAdd with default values
* passed in.
*
* Need a source RFI to initialize from.
*
* Will create:
* A Pending change order record (PMOP) will be added if new PCO.
* A Pending change order item record (PMOI) will be added. Must be new item
*
*
* Input parameters:
* PM Company
* Project
* RFIType
* RFI
*
* PCOType
* PCO
* PCO Description
* PCO Issue
* PCO Ext/Int Flag
* PCO Copy Notes Flag
* PCO Copy Response Flag
* PCO Copy Requested Flag
* PCO Copy Attachments Flag
* 
* PCOItem
* PCO Item Description
* PCO Item Issue
* PCO Item Status
* PCO Item Contract Item
* PCO Item Fixed Amount Flag
* PCO Item Units
* PCO Item UM
* PCO Item Unit Price
* PCO Item Fixed Amount
* PCO Item Pending Amount (may not need)
* PCO Item Force Phase Flag
* PCO Item Change In Days
* PCO Item Budget Code
* PCO Item Copy Notes Flag
* PCO Item Copy Response Flag
* PCO Item Copy Requested Flag
* PCO Item Copy Attachments
* BudgetType, SubType, POType, ContractType, Priority
*
* ERROR:
* @PCOKeyID		PCO Key Id used to access correct record in PCO FORM
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@pmco bCompany, @project bProject, @rfitype bDocType, @rfi bDocument,
 @pcotype bDocType, @pco bPCO, @pcodesc bItemDesc = null, @pcoissue bIssue = null,
 @pcointext varchar(1) = 'E', @pco_notes bYN = 'N', @pco_response bYN = 'N',
 @pco_requested bYN = 'N', @pco_attachments bYN = 'N',
 @pcoitem bPCOItem, @pcoitem_desc bItemDesc = null, @pcoitem_issue bIssue = null,
 @pcoitem_status bStatus = null, @pcoitem_contractitem bContractItem = null,
 @pcoitem_fixedamountyn bYN = 'N', @pcoitem_units bUnits = 0, @pcoitem_unitprice bUnitCost = 0,
 @pcoitem_um bUM = null, @pcoitem_fixedamount bDollar = 0, @pcoitem_pendingamount bDollar = 0,
 @pcoitem_forcephase bYN = 'N', @pcoitem_changedays smallint = 0,
 @pcoitem_budget varchar(10) = null, @pcoitem_notes bYN = 'N', @pcoitem_response bYN = 'N',
 @pcoitem_requested bYN = 'N', @pcoitem_attachments bYN = 'N',
 @BudgetType bYN = 'N', @SubType bYN = 'N', @POType bYN = 'N', @ContractType bYN = 'N',
 @Priority TINYINT = 3,
 @PCOKeyID BIGINT = NULL OUTPUT, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @rfi_notes varchar(max), @rfi_response varchar(max), @rfi_requested varchar(max),
		@pmop_notes varchar(max), @pmoi_notes varchar(max), @contract bContract,
		@rfi_respfirm bVendor, @rfi_respperson bEmployee, @initdate bDate, @newissue bIssue,
		@errmsg varchar(255), @retcode int, @phasegroup bGroup, @IssueNum bIssue,
		----#141957
		@RecTableName NVARCHAR(128), @RECID BIGINT, @LinkTableName NVARCHAR(128),
		@BeginStatus bStatus, @Details varchar(max), @ROMAmount bDollar
		

select @rcode = 0, @retcode = 0
----#141957
SET @LinkTableName = 'PMOP'
SET @PCOKeyID = -1

----#141031
set @initdate = dbo.vfDateOnly()

if @pmco is null
	begin
	select @msg = 'Missing PM Company', @rcode = 1
	goto bspexit
	end
if isnull(@project,'') = ''
	begin
	select @msg = 'Missing project', @rcode = 1
	goto bspexit
	end

if isnull(@rfitype,'') = ''
	begin
	select @msg = 'Missing RFI Type', @rcode = 1
	goto bspexit
	end
if isnull(@rfi,'') = ''
	begin
	select @msg = 'Missing RFI', @rcode = 1
	goto bspexit
	end

if isnull(@pcotype,'') = ''
	begin
	select @msg = 'Missing PCO Type', @rcode = 1
	goto bspexit
	end
if isnull(@pco,'') = ''
	begin
	select @msg = 'Missing PCO', @rcode = 1
	goto bspexit
	end
if isnull(@pcoitem,'') = ''
	begin
	select @msg = 'Missing PCO Item', @rcode = 1
	goto bspexit
	end

---- get phase group from HQCO
select @phasegroup=PhaseGroup from HQCO where HQCo=@pmco
if @@rowcount = 0
	begin
	select @msg = 'Invalid PM Company.', @rcode = 1
	goto bspexit
	end

---- get beginning status from PMCo
exec @retcode = dbo.bspPMSCBegStatusGet @pmco, @BeginStatus output, @errmsg output

--------------
-- TFS #622 --
--------------
-- HARD CODE @rfitype INPUT IN frmPMProjectIssues BUTTON CLICK TO
-- BE ABLE TO REUSE THE EXISTING RFI FIELDS AND CODE 

IF @rfitype = 'ISSUE'
	BEGIN
		-- CLEAN UP --
		SET @IssueNum = CAST(@rfi as integer)
		SET @rfitype = NULL
		SET @rfi = NULL
		----##141957
		SET @RecTableName = 'PMIM'
		-- verify ISSUE exists -- *** DID NOT DO ANYTHING WITH NOTES AT THIS TIME PER Jeremy L.
		SELECT @rfi_respfirm = PMCo, @rfi_respperson = Initiator, @RECID = KeyID, @Details = IssueInfo, @ROMAmount = isnull(ROMImpact,0), 
			@rfi_notes = case when @pco_notes = 'Y' then Notes else null end
		FROM dbo.PMIM WITH (NOLOCK) 
		WHERE PMCo = @pmco AND Project = @project AND Issue = @IssueNum
		IF @@ROWCOUNT = 0
			BEGIN
				SELECT @msg = 'Invalid ISSUE, cannot continue', @rcode = 1
				GOTO bspexit
			END
	END
ELSE 
	BEGIN
		-- verify RFI exists --
		----##141957
		SET @RecTableName = 'PMRI'
		select @rfi_notes=Notes, @rfi_response=Response, @rfi_requested=InfoRequested,
			   @rfi_respfirm=ResponsibleFirm, @rfi_respperson=ResponsiblePerson,
			   @RECID = KeyID
		from dbo.PMRI with (nolock) where PMCo=@pmco and Project=@project and RFIType=@rfitype and RFI=@rfi
		if @@rowcount = 0
			begin
			select @msg = 'Invalid RFI, cannot continue', @rcode = 1
			goto bspexit
			end
	END

-- END TFS #622 --


---- get contract from JCJM
select @contract=Contract
from JCJM with (nolock) where JCCo=@pmco and Job=@project
if @@rowcount = 0
	begin
	select @msg = 'Error has occurred reading contract for project.', @rcode = 1
	goto bspexit
	end



BEGIN TRY

	begin
	---- create transaction
	begin transaction

	---- check pending change order header exists - add if new
	if not exists(select PMCo from dbo.PMOP where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco)
		begin
		---- build notes if any
		select @pmop_notes = null
		if @pco_notes = 'Y' select @pmop_notes = @rfi_notes
		if @pco_response = 'Y'
			begin
			if @pmop_notes is null
				select @pmop_notes = @rfi_response
			else
				select @pmop_notes = @pmop_notes + char(13) + char(10) + @rfi_response
			end
		if @pco_requested = 'Y'
			begin
			if @pmop_notes is null
				select @pmop_notes = @rfi_requested
			else
				select @pmop_notes = @pmop_notes + char(13) + char(10) + @rfi_requested
			end

		---- may need to initialize a new project issue
		if @pcoissue = -1
			begin
			exec @retcode = dbo.vspPMIssueInitialize @pmco, @project, @rfi_respfirm, @rfi_respperson, @pcodesc, @initdate, @newissue output, @errmsg output
			if @retcode <> 0
				begin
				select @newissue = null
				end
			if isnull(@newissue,0) <> 0 select @pcoissue = @newissue
			end
		
		---- get PMDT defaults B-02849
		--SELECT @BudgetType = BudgetType, @SubType = SubType, @POType = POType, @ContractType = ContractType
		--FROM dbo.PMDT WHERE DocType = @pcotype
		--IF @pcointext = 'I' SET @ContractType = 'N'
		
		IF @pcointext = 'I' SET @ContractType = 'N'
		
		---- insert PMOP row B-02849
		insert PMOP (PMCo, Project, PCOType, PCO, Description, Issue, Contract, PendingStatus, IntExt, Notes,
						BudgetType, SubType, POType, ContractType, Priority, Status, Details, ROMAmount)
		select @pmco, @project, @pcotype, @pco, @pcodesc, @pcoissue, @contract, 0, @pcointext, @pmop_notes,
				@BudgetType, @SubType, @POType, @ContractType, @Priority, @BeginStatus, @Details, IsNull(@ROMAmount,0)
		
		SET @PCOKeyID = SCOPE_IDENTITY()	
		---- INSERT RECORD LINK #141957	
		INSERT dbo.PMRelateRecord ( RecTableName , RECID , LinkTableName , LINKID)
		SELECT @RecTableName, @RECID, @LinkTableName, @PCOKeyID
		WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName=@RecTableName
				AND v.RECID=@RECID AND v.LinkTableName=@LinkTableName AND v.LINKID=@PCOKeyID)

		DECLARE @sentdate bDate
		----#141031
		SET @sentdate = dbo.vfDateOnly()
		
		---- pull default distributions for new PCO
		exec dbo.vspPMProjDefDistIntoPMCD @pmco, @project, @pcotype, @pco, @sentdate, null, null
		end


	---- now add the PCO item to PMOI
	select @pmoi_notes = null
	---- build notes if any
	if @pcoitem_notes = 'Y' select @pmoi_notes = @rfi_notes
	if @pcoitem_response = 'Y'
		begin
		if @pmoi_notes is null
			select @pmoi_notes = @rfi_response
		else
			select @pmoi_notes = @pmoi_notes + char(13) + char(10) + @rfi_response
		end
	if @pcoitem_requested = 'Y'
		begin
		if @pmoi_notes is null
			select @pmoi_notes = @rfi_requested
		else
			select @pmoi_notes = @pmoi_notes + char(13) + char(10) + @rfi_requested
		end

	---- may need to initialize a new project issue for PCO item
	if @pcoitem_issue = -1
		begin
		exec @retcode = dbo.vspPMIssueInitialize @pmco, @project, @rfi_respfirm, @rfi_respperson, @pcoitem_desc, @initdate, @newissue output, @errmsg output
		if @retcode <> 0
			begin
			select @newissue = null
			end
		if isnull(@newissue,0) <> 0 select @pcoitem_issue = @newissue
		end


	---- insert PMOI record
	insert into bPMOI (PMCo, Project, PCOType, PCO, PCOItem, Description, Status, Issue, Contract,
				ContractItem, ForcePhaseYN, Approved, ChangeDays, UM, Units,
				FixedAmountYN, UnitPrice, PendingAmount, FixedAmount, ProjectCopy, BillGroup,
				RFIType, RFI, Notes)
	select @pmco, @project,@pcotype, @pco, @pcoitem, @pcoitem_desc, @pcoitem_status, @pcoitem_issue, @contract,
				@pcoitem_contractitem, @pcoitem_forcephase, 'N', @pcoitem_changedays, @pcoitem_um, @pcoitem_units,
				@pcoitem_fixedamountyn, case @pcoitem_fixedamountyn when 'N' then 0 else @pcoitem_unitprice end,
				0, case @pcoitem_fixedamountyn when 'N' then 0 else @pcoitem_fixedamount end, 'N', null,
				@rfitype, @rfi, @pmoi_notes		

	---- insert markups and addons
	if @@rowcount <> 0
		begin
		---- PMOM
		insert into bPMOM(PMCo,Project,PCOType,PCO,PCOItem,PhaseGroup,CostType,IntMarkUp,ConMarkUp)
		select @pmco, @project, @pcotype, @pco, @pcoitem, @phasegroup, a.CostType, 0,
				case when isnull(h.IntExt,'E') = 'E' then isnull(a.Markup,0)
					 when isnull(t.InitAddons,'Y') = 'Y' then IsNull(a.Markup,0)
					 else 0 end
		from bPMPC a with (nolock)
		----#132046
		join bPMOP h with (nolock) on h.PMCo=@pmco and h.Project=@project and h.PCOType=@pcotype and h.PCO=@pco
		join bPMDT t with (nolock) on t.DocType=h.PCOType
		where a.PMCo=@pmco and a.Project=@project
----		and (h.IntExt = 'E' or (h.IntExt = 'I' and t.InitAddons = 'Y'))
		and not exists(select PMCo from bPMOM b where b.PMCo=@pmco and b.Project=@project and b.PCOType=@pcotype
   						and b.PCO=@pco and b.PCOItem=@pcoitem and b.CostType=a.CostType)
		---- PMOA
		insert into dbo.bPMOA(PMCo, Project, PCOType, PCO, PCOItem, AddOn, Basis, AddOnPercent,
				AddOnAmount, Status, TotalType, Include, NetCalcLevel, BasisCostType, PhaseGroup)
		select @pmco, @project, @pcotype, @pco, @pcoitem, a.AddOn, a.Basis, a.Pct,
				a.Amount, 'Y', a.TotalType, a.Include, a.NetCalcLevel, a.BasisCostType, a.PhaseGroup
		from dbo.bPMPA a
		----#132046
		join dbo.bPMOP h with (nolock) on h.PMCo=a.PMCo and h.Project=@project and h.PCOType=@pcotype and h.PCO=@pco
		join dbo.bPMDT t with (nolock) on t.DocType=h.PCOType
		----#134354
		where a.PMCo=@pmco and a.Project=@project and a.Standard = 'Y'
		and (h.IntExt = 'E' or (h.IntExt = 'I' and t.InitAddons = 'Y'))
		and not exists(select PMCo from dbo.bPMOA b where b.PMCo=@pmco and b.Project=@project and b.PCOType=@pcotype
   						and b.PCO=@pco and b.PCOItem=@pcoitem and b.AddOn=a.AddOn)
   		----#141957			
   		SELECT @PCOKeyID = KeyID
		FROM dbo.PMOP where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
		IF @@ROWCOUNT <> 0
			BEGIN
			---- INSERT RECORD LINK 
			INSERT dbo.PMRelateRecord ( RecTableName , RECID , LinkTableName , LINKID)
			SELECT @RecTableName, @RECID, @LinkTableName, @PCOKeyID
			WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName=@RecTableName
					AND v.RECID=@RECID AND v.LinkTableName=@LinkTableName AND v.LINKID=@PCOKeyID)
			END	
		END
		
		

   	---- calculate pending amount, addons, markups
   	exec @retcode = dbo.vspPMOACalcs @pmco, @project, @pcotype, @pco, @pcoitem

	commit transaction

	end

END TRY



BEGIN CATCH
	begin
	IF @@TRANCOUNT > 0
		begin
		rollback transaction
		end
	select @msg = 'PCO insert failed. ' + ERROR_MESSAGE()
	select @rcode = 1
	end
END CATCH


bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOSAdd] TO [public]
GO
