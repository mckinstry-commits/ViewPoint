SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspPMImportUpload    Script Date: 8/28/99 9:36:46 AM ******/
CREATE procedure [dbo].[bspPMImportUpload]
/*******************************************************************************
* Creation Date:	GF 05/25/99 - rolled up 5.x mod lines before 2006
* Modified Date:	GF 08/24/2006 - issue #29640 - added check for inactive phase and cost types when importing into existing job.
*					GF 12/04/2006 - issue #27450 - allow upload into existing change order using starting item and increment by.
*					GF 04/25/2007 - issue #124410 - check JCCT.TrackHours flag, do not load hours if 'N'.
*					GF 02/14/2008 - issue #127210 - new columns in PMPA 6.1.0
*					GF 03/11/2008 - issue #127076 added Mail Country and Ship Country to JCJM
*					GF 06/19/2008 - issue #128736 need to update column PMSL.SMRetgPct
*					gf 06/20/2008 - issue #128??? add try catch with transaction around the update into PM tables.
*					GF 10/30/2008 - issue #130136 submatl_notes changed from varchar(8000) to varchar(max)
*					GF 10/30/2008 - issue #130772 expanded descriptions for co and item to 60 characters
*					GF 11/28/2008 - issue #131100 expanded phase description
*					GP 12/08/2008 - Issue 131019, added supplier as null to bPMMF insert.
*					GF 01/10/2008 - issue #129669 add-on cost distribution set Status to 'Y' on insert
*					GP 01/30/2009 - Issue #127486 added @ProjSecGrp and @ContSecGrp, insert into JCJM & JCCM.
*					GF 03/05/2009 - issue #132046 intialize addons by PCO Type
*					GF 03/05/2009 - issue #132108 use PMDT.IntExtDefault for PCO
*					GP 03/17/2009 - issue #126939 added new standard fields and UD fields to inserts for
*										PM Import Template Detail enhancement.
*					GF 07/02/2009 - issue #134632 bJCCH original estimates doubling
*					GP 08/18/2009 - issue #135029 Phase insert uses Sequence in where clause, UD updates all use views and Sequence
*					GP 08/27/2009 - issue #135277 Added null to bspJCCHAddUpdate call for @inscode param
*					GP 09/01/2009 - issue #135348 Used views for dynamic sql updates on UD instead of tables
*					GP 12/18/2009 - issue #136961 Material detail records use bPMWM INCo & Loc in validation
*					GF 04/09/2010 - issue #138935 changed logic for JCCI user memos for a bulk insert.
*					GF 05/17/2010 - issue #139633 check to make sure default security group is not null before adding
*					GF 08/03/2010 - issue #134354 use the addon standard flag when inserting change order addons.
*					GF 02/21/2011 - TK-01924 additional columns from PMDT update to PMOP 
*					gf 06/10/2011 - ISSUE #144043 TK-05746
*					GF 09/27/2011 - TK-08632
*					TRL 12/08/2012 TK-10902  added 'Y' has paramter for bspPMPCOApprove
*					GP	01/10/2012 TK-11600 Force bPMOP ContractType to Y if PCO Item amounts exist
*					DAN SO 03/15/2012 - TK-13139 - added 2 additional ('Y') input parameters to the bspPMPCOApprove call
*					GF 05/18/2012 TK-14980 #146075 need to populate Vendor Group from HQCO for PMOL rows
*
*
*
*
*
* This SP will upload a importid work data into PM. If the COItem flag in PMUT
* is set to Y, then each contract item for each phase is consider to be a unique
* change order item. If the COItem flag in PMUT is set to N, then all the phases
* will be assigned to the COItem passed into SP.
*
* It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
*
* Pass In
*   PMCo	PM Company
*   ImportId    ImportId to upload
*   Project     Project
*   PDesc	Project Description
*   Contract    Contract
*   CDesc	Contract Description
*   Department  Department for project
*   COYN	Change Order Yes/No
*   COType	Pending CO Type
*   CO          Change Order
*   CODesc	Change Order Description
*   COItem	Change Order Item
*   COItemDesc  Change Order Item Description
*   ApproveYN   Approve the change order Yes/No
*   IssueOpt    Option group for issue creation. 0-no, 1-new, 2-existing
*   Issue       Issue number if loading to existing, else empty.
*   UploadBy    User Name
*   StartMonth  Contract Start Month
*   LiabTemplate JC Liability Template
*   PRStateCode  PR State Code
*   Customer     JCCM Customer
*   RetainPCT    JCCM Retainage percent
*   StartMonth   Contract Start Month
*   LockPhases		Lock Phase flag
*	 TaxCode		Contract Tax Code
* INCo				IN Company
* Location			IN Location
* Markupdiscrate	JC Markup/discount rate
* Startingitem		Starting PCO item
* IncrementBy		Increment By
*
* RETURN PARAMS
*   msg           Error Message, or Success message
*
* Returns
*  
*      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
*
********************************************************************************/
(@pmco bCompany = Null, @importid varchar(10) = Null, @project bJob = Null, @pdescription bItemDesc = Null,
 @contract bContract = Null, @cdescription bItemDesc = Null, @department bDept = Null, @coyn bYN = 'N',
 @pcotype bPCOType = Null, @pco bPCO = Null, @pcodescription bItemDesc = Null, @pcoitem bPCOItem = Null,
 @pcoitemdesc bItemDesc = Null, @approveyn bYN = 'N', @issueopt char(1) = '0', @existissue bIssue,
 @uploadby varchar(15) = Null, @liabtemplate smallint = null, @prstate varchar(4) = null,
 @customer bCustomer = null, @jccmretpct bPct, @startmonth bMonth, @lockphases bYN,
 @taxcode bTaxCode = null, @inco bCompany = null, @location bLoc = null, @markupdiscrate bRate = 0,
 @startingitem int, @incrementby int, @ProjSecGrp int = null, @ContSecGrp int = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @sequence int, @validcnt int, @phasegroup bGroup, @matlgroup bGroup,
		@vendorgroup bGroup, @taxgroup bGroup, @custgroup bGroup, @template varchar(10),
     	@createfirm bYN, @createcoitem bYN, @createsicode bYN, @defaultbilltype bBillType,
     	@projminpct bPct, @openpcoitem tinyint, @openphase tinyint, @opencosttype tinyint,
     	@openpcodetail tinyint, @opensubct tinyint, @openmaterial tinyint, @slctcnt int, @coseq int,
     	@contractstatus tinyint, @siregion varchar(6), @sicode varchar(16), @um bUM,
     	@units bUnits, @vphase bPhase, @vdesc bItemDesc, @vphasegroup bGroup, @vcontract bContract,
     	@vitem bContractItem, @vdept bDept, @jcjpexists bYN, @pmsg varchar(255), @newissue bIssue,
     	@ourfirm bFirm, @initiator bEmployee, @dateinit bDate, @beginstatus bStatus, @item bContractItem,

      	@description bItemDesc, @inputmask varchar(30), @itemlength varchar(10), @itemmask varchar(30),
      	@seqitem varchar(20), @phase bPhase, @costtype bJCCType, @billflag char(1), @itemunitflag bYN,
      	@phaseunitflag bYN, @hours bHrs, @costs bDollar, @unitcost bUnitCost, @hourcost bUnitCost,
      	@unithour decimal(16,5),@aco bACO, @approveddate bDate, @slco bCompany, @slcosttype bJCCType,
      	@vendor bVendor, @material bMatl, @ecm bECM, @phaseactive bYN, @retainpct bPct,
       	@mtldescription bItemDesc, @fixedamt bYN, @itemamt bDollar, @itemuc bUnitCost,
       	@jcchum bUM, @stocked bYN, @pqm char(1), @contractsecure bYN, @jobsecure bYN,
   		@contractdefaultsecurity smallint, @jobdefaultsecurity smallint,
     	@nextitem int, @importitem varchar(30), @contractitem bContractItem, @errmsg varchar(255),
    	@arco bCompany, @pmolum bUM, @mo_valid bYN, @detailup bUnitCost, @detailecm bECM, 
   		@factor smallint, @pmsl_desc bItemDesc, @submatl_notes varchar(max),
   		@inactive_check varchar(2000), @pmwd_seq int, @openpmwi int, @pmwi_count int,
		@pmoi_item bPCOItem, @pmoi_desc bItemDesc, @pmoi_item_next int, @pco_exists bYN,
		@trackhours bYN, @intextdefault char(1),
		--Parameters to hold newly added column values returned by cursors.
		@ws_Supplier bVendor, @ws_TaxType tinyint, @ws_TaxCode bTaxCode, @ws_TaxGroup bGroup, @ws_SMRetgPct bPct, 
		@ws_SendFlag bYN, @wm_RecvYN bYN, @wm_TaxCode bTaxCode, @wm_TaxType tinyint, 
		@wm_SendFlag bYN, @wm_MSCo bCompany, @wm_Quote varchar(10), @wm_Supplier bVendor,
		@wm_MatlOption char(1), @wm_Location bLoc, @wm_INCo bCompany,
		--Parameters to store UD insert and select values.
		@UDStatement nvarchar(max), @UDWhere nvarchar(255), @SQLString nvarchar(max), @KeyID bigint,
		--Parameters to store cursor sequences
		@pmws_seq int, @pmwm_seq int, @pmwp_seq int, @joins nvarchar(max), @where nvarchar(max),
		---- TK-01924
		@BudgetType CHAR(1), @SubType CHAR(1), @POType CHAR(1), @ContractType CHAR(1),
		@ProjOurFirm bVendor
		

select @rcode=0, @openpcoitem=0, @openphase=0, @opencosttype=0, @openpcodetail=0, @openpmwi=0,
		@opensubct=0, @openmaterial=0, @siregion = null
    
If @importid is null
	begin
	select @msg='Missing Import Id', @rcode=1
	goto bspexit
	end
   
if isnull(@markupdiscrate,0) = 0 select @markupdiscrate = 0

select @template=Template from bPMWH where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0
	begin
	select @msg='Invalid Import Id', @rcode = 1
	goto bspexit
	end

---- get groups from HQCO
select @phasegroup=PhaseGroup, @matlgroup=MatlGroup, @vendorgroup=VendorGroup, @taxgroup=TaxGroup
from bHQCO with (nolock) where HQCo=@pmco
if @@rowcount = 0
	begin
	select @msg='Missing data group for HQ Company ' + convert(varchar(3),@pmco) + '!', @rcode=1
	goto bspexit
	end

---- get ARCO from JCCO
select @arco=ARCo from bJCCO with (nolock) where JCCo=@pmco
if @@rowcount = 0
	begin
	select @msg='Unable to get AR Company from JC Company for ' + convert(varchar(3),isnull(@pmco,'')) + '!', @rcode=1
	goto bspexit
	end

---- get customer group from HQCo
select @custgroup=CustGroup from bHQCO with (nolock) where HQCo=@arco
if @@rowcount = 0
	begin
	select @msg='Unable to get Customer Group for AR Company: ' + convert(varchar(3),isnull(@arco,'')) + '!', @rcode=1
	goto bspexit
	END

if @taxgroup is null
	begin
	select @msg = 'Missing Tax Group!', @rcode = 1
	goto bspexit
	end

if @phasegroup is null
	begin
	select @msg = 'Missing Phase Group!', @rcode = 1
	goto bspexit
	end

if @matlgroup is null
	begin
	select @msg = 'Missing Material Group!', @rcode = 1
	goto bspexit
	end

if @vendorgroup is null
	begin
	select @msg = 'Missing Vendor Group!', @rcode = 1
	goto bspexit
	end

if isnull(@inco,0) = 0
	begin
	select @inco = null, @location = null
	end

if isnull(@location,'') = ''
	begin
	select @location = null
	end

select @createfirm=isnull(DefaultFirm,'N'), @createcoitem=isnull(COItem,'N'),
		@createsicode=isnull(CreateSICode,'N'), @fixedamt=isnull(FixedAmt,'N')
from bPMUT where Template=@template

if @coyn='Y'
	begin
	if @pcotype is null
		begin
		select @msg = 'Missing Pending CO Type!', @rcode = 1
		goto bspexit
		end

	if @pco is null
		begin
		select @msg = 'Missing Pending Change Order!', @rcode = 1
   		goto bspexit
		end
    
	if @createcoitem='N' and @pcoitem is null and @startingitem is null
		begin
		select @msg = 'Must have a PCO Item or a starting PCO Item.', @rcode = 1
   		goto bspexit
		end
	end

---- call SP to check cost type UM changes for errors only if not a change order
if @coyn <> 'Y'
   	begin
   	exec @rcode = bspPMImportUploadCheck @pmco, @importid, @project, @msg output
   	if @rcode <> 0 goto bspexit
   	end
   
---- get the mask for bPCOItem
select @inputmask=InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bPCOItem'
if isnull(@inputmask,'') = '' select @inputmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '16'
if @inputmask in ('R','L')
	begin
	select @inputmask = @itemlength + @inputmask + 'N'
	end

---- get input mask for bContractItem
select @itemmask=InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bContractItem'
if isnull(@itemmask,'') = '' select @itemmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '16'
if @itemmask in ('R','L')
	begin
	select @itemmask = @itemlength + @itemmask + 'N'
	end

---- get DefaultBillType
select @defaultbilltype=isnull(DefaultBillType, 'P') from bJCCO with (nolock) where JCCo=@pmco

---- get document type default #132108
if @pcotype is not null
	begin
	select @intextdefault = IntExtDefault,
	----TK-01924
	@BudgetType = BudgetType, @SubType = SubType, @POType = POType, @ContractType = ContractType
	from dbo.bPMDT with (nolock) where DocType=@pcotype
	end
if isnull(@intextdefault,'N') = 'N' set @intextdefault = 'E'

---- get Our Firm
select @ourfirm=OurFirm, @slco=APCo, @slcosttype=SLCostType, @beginstatus=BeginStatus
from bPMCO with (nolock) where PMCo=@pmco
if @beginstatus is null
	begin
	---- get beginning status
	select @beginstatus=Min(Status) from bPMSC where CodeType='B'
	if @beginstatus is null
		begin
		select @beginstatus=Min(Status) from bPMSC
		end
	end

---- get vendor group for @slco from HQCO TK-08632
SELECT @vendorgroup = VendorGroup
FROM dbo.bHQCO WHERE HQCo = @slco

---- see if project has a our firm TK-08632
IF EXISTS(SELECT 1 FROM dbo.bJCJM WHERE JCCo=@pmco AND Job=@project AND OurFirm is NOT NULL)
	BEGIN
	SELECT @ourfirm = OurFirm
	FROM dbo.bJCJM WHERE JCCo=@pmco AND Job=@project
	END

---- get SI region
select @siregion = SIRegion from bPMWH where PMCo=@pmco and ImportId=@importid
if @@rowcount = 0
	begin
	select @siregion = DefaultSIRegion from bPMUT where Template=@template
	if @@rowcount = 0 set @siregion = null
	end


---- Setup default security group to have access if securing bJob
select @jobsecure = Secure, @jobdefaultsecurity = DfltSecurityGroup
from dbo.DDDTShared with (nolock) where Datatype = 'bJob'
if @@rowcount = 0 or isnull(@jobsecure,'N') <> 'Y' select @jobsecure='N', @jobdefaultsecurity = null

---- Setup default security group to have access if securing bContract
select @contractsecure = Secure, @contractdefaultsecurity = DfltSecurityGroup
from dbo.DDDTShared with (nolock) where Datatype = 'bContract'
if @@rowcount = 0 or isnull(@contractsecure,'N') <> 'Y' select @contractsecure='N', @contractdefaultsecurity = null

---- need to check for inactive phase/cost types for job being imported into.
set @inactive_check = ''
select @inactive_check = @inactive_check + 'Phase: ' + h.Phase + ' CostType: ' + convert(varchar(3),h.CostType) + ', '
from PMWD d
join JCCH h on h.JCCo=@pmco and h.Job=@project and h.PhaseGroup=@phasegroup and h.Phase=d.Phase and h.CostType=d.CostType
where d.PMCo=@pmco and d.ImportId=@importid and h.JCCo=@pmco and h.Job=@project and h.ActiveYN='N'
if @@rowcount <> 0
   	begin
   	select @msg = 'Inactive phase cost types found, cannot import. ' + @inactive_check, @rcode = 1
   	goto bspexit
   	end

---- check PMWI for null contract item
if exists(select 1 from dbo.bPMWI with (nolock) where PMCo=@pmco and ImportId=@importid and Item is null)
	begin
	select @msg = 'Missing contract item in Item work table, cannot import. ', @rcode = 1
	goto bspexit
	end

/*************************************/
BEGIN TRY

	begin
	---- start transaction
	begin transaction

	---- insert contract into bJCCM if does not exists
	select @validcnt = Count(*) from bJCCM where JCCo=@pmco and Contract=@contract
	if @validcnt = 0
   		begin
   		select @contractstatus=0
   		insert bJCCM (JCCo, Contract, Description, Department, ContractStatus, OriginalDays, CurrentDays,
   				StartMonth, CustGroup, Customer, TaxInterface, TaxGroup, TaxCode, RetainagePCT, DefaultBillType,
   				OrigContractAmt, ContractAmt, BilledAmt, ReceivedAmt, CurrentRetainAmt, SIRegion, SecurityGroup)
   		select @pmco, @contract, @cdescription, @department,@contractstatus, 0, 0, @startmonth, @custgroup,
   				@customer,'N', @taxgroup, @taxcode, @jccmretpct, @defaultbilltype, 0, 0, 0, 0, 0, 
   				@siregion, isnull(@ContSecGrp,@contractdefaultsecurity)
   		end
	else
   		begin
   		select @contractstatus=isnull(ContractStatus,0), @siregion=SIRegion
   		from bJCCM where JCCo=@pmco and Contract=@contract
   		end

	---- insert project into bJCJM if does not exists
	insert into bJCJM (JCCo,Job,Description,Contract,JobStatus,LockPhases,JobPhone,JobFax,MailAddress,
   				MailCity,MailState,MailZip,MailAddress2,ShipAddress,ShipCity,ShipState,ShipZip,ShipAddress2,
   				TaxGroup,TaxCode,Certified,ProjMinPct,VendorGroup,BidNumber,LiabTemplate,PRStateCode,MarkUpDiscRate,
   				SecurityGroup, Notes, MailCountry, ShipCountry)
	select @pmco,@project,@pdescription,@contract,@contractstatus,@lockphases,h.JobPhone,h.JobFax,h.MailAddress,
				h.MailCity,h.MailState,h.MailZip,h.MailAddress2,h.ShipAddress,h.ShipCity,h.ShipState,h.ShipZip,
				h.ShipAddress2,@taxgroup,null,'N',0,@vendorgroup,substring(isnull(h.EstimateCode,''),1,10),@liabtemplate,
				@prstate,@markupdiscrate, isnull(@ProjSecGrp,@jobdefaultsecurity), h.Notes, h.MailCountry, h.ShipCountry
	from bPMWH h where h.PMCo=@pmco and h.ImportId=@importid
	and not exists(select top 1 1 from bJCJM m where m.JCCo=@pmco and m.Job=@project)

	--Update UD Fields--
	set @KeyID = SCOPE_IDENTITY()
	select @UDWhere = null, @UDStatement = null, @SQLString = null
	set @UDWhere = 'where PMCo='+cast(@pmco as varchar(3))+' and ImportId='+char(39)+@importid+char(39)

	execute dbo.vspPMImportUDBuild 'bJCJM', 'PMWH', @UDWhere, @UDStatement output, @errmsg output

	if @UDStatement is not null
	begin
		set @SQLString = 'update JCJM set ' + @UDStatement + ' where KeyID='+cast(@KeyID as varchar(10))
		execute sp_executesql @SQLString
	end
	--------------------

	---- if createsicode is yes - insert into bJCSI where not exists
	if @createsicode='Y' and @siregion is not null
   		begin
   		insert into bJCSI(SIRegion,SICode,Description,UM,MUM,UnitPrice)
   		select @siregion,i.SICode,min(i.Description),min(i.UM),null,min(i.UnitCost)
   		from bPMWI i where i.PMCo=@pmco and i.ImportId=@importid and i.SICode is not null
   		and not exists(select * from bJCSI s where s.SIRegion=@siregion and s.SICode=i.SICode)
   		group by i.SICode
   		end

	---- insert items from bPMWI into bJCCI where item does not exists - else skip
	if @coyn='Y'
		begin
   		insert into bJCCI (JCCo,Contract,Item,Description,Department,TaxGroup,TaxCode,UM,SIRegion,SICode,
   				RetainPCT,OrigContractAmt,OrigContractUnits,OrigUnitPrice,ContractAmt,
   				ContractUnits,UnitPrice,BilledAmt,BilledUnits,ReceivedAmt,CurrentRetainAmt,
   				BillType,BillDescription,BillOriginalUnits,BillOriginalAmt,BillCurrentUnits,
   				BillCurrentAmt,BillUnitPrice,InitSubs,StartMonth,Notes,BillGroup,InitAsZero,MarkUpRate)
   		select @pmco,@contract,i.Item,i.Description, isnull(i.Dept,@department), @taxgroup, isnull(i.TaxCode,@taxcode), 
				i.UM, @siregion, case when @siregion is null then null else i.SICode end,
   				i.RetainPCT, 0,0,0,0,0,0,0,0,0,0, isnull(i.BillType,@defaultbilltype), i.BillDescription,0,0,0,0,0,
				isnull(i.InitSubs,'Y'),isnull(i.StartMonth,@startmonth),i.Notes,i.BillGroup,i.InitAsZero,i.MarkUpRate
   		from bPMWI i where i.PMCo=@pmco and i.ImportId=@importid and i.Item is not null
   		and not exists(select * from bJCCI c where c.JCCo=@pmco and c.Contract=@contract and c.Item=i.Item)
   		end
	else
   		begin
   		insert into bJCCI (JCCo,Contract,Item,Description,Department,TaxGroup,TaxCode,UM,SIRegion,SICode,RetainPCT,
   				OrigContractAmt,OrigContractUnits,OrigUnitPrice,ContractAmt,ContractUnits,UnitPrice,
   				BilledAmt,BilledUnits,ReceivedAmt,CurrentRetainAmt,BillType,BillDescription,
   				BillOriginalUnits,BillOriginalAmt,BillCurrentUnits,BillCurrentAmt,BillUnitPrice,
   				InitSubs,StartMonth,Notes,BillGroup,InitAsZero,MarkUpRate)
   		select @pmco,@contract,i.Item,i.Description, isnull(i.Dept,@department),@taxgroup,isnull(i.TaxCode,@taxcode),
				i.UM, @siregion, case when @siregion is null then null else i.SICode end,
   				i.RetainPCT, i.Amount, i.Units, i.UnitCost, i.Amount, i.Units, i.UnitCost,0,0,0,0,
   				isnull(i.BillType,@defaultbilltype), i.BillDescription,0,0,0,0,0,isnull(i.InitSubs,'Y'),
				isnull(i.StartMonth,@startmonth),i.Notes,i.BillGroup,i.InitAsZero,i.MarkUpRate
   		from bPMWI i where i.PMCo=@pmco and i.ImportId=@importid and i.Item is not null
   		and not exists(select * from bJCCI c where c.JCCo=@pmco and c.Contract=@contract and c.Item=i.Item)
   		end

	--Update UD Fields--
	set @KeyID = SCOPE_IDENTITY()
	select @UDWhere = null, @UDStatement = null, @SQLString = null
	set @UDWhere = 'where PMCo='+cast(@pmco as varchar(3))+' and ImportId='+char(39)+@importid+char(39)+' and Item is not null'

	execute dbo.vspPMImportUDBuild 'bJCCI', 'PMWI', @UDWhere, @UDStatement output, @errmsg output

	---- #138935
	if @UDStatement is not null
		begin
		-- build joins and where clause
		select @joins = ' from PMWI z join JCCI on JCCI.JCCo = ' + convert(varchar(3),@pmco) + ' and JCCI.Contract = ' + CHAR(39) + @contract + CHAR(39) + ' and JCCI.Item = z.Item'
		select @where = ' where z.PMCo = ' + convert(varchar(3),@pmco) + ' and z.ImportId= ' + char(39) + @importid + char(39) + ' and z.Item is not null'
		-- execute user memo update
		exec @rcode = dbo.bspPMProjectCopyUserMemos 'JCCI', @joins, @where, @msg output
		end
	
		--set @SQLString = 'update JCCI set ' + @UDStatement + ' where KeyID='+cast(@KeyID as varchar(10))
		--execute sp_executesql @SQLString
	--end
	---- #138935
	--------------------

---- insert phases from bPMWP into bJCJP where not exists
declare phase_cursor cursor LOCAL FAST_FORWARD
for select Item, Phase, Description, Sequence
from bPMWP where PMCo=@pmco and ImportId=@importid

open phase_cursor
set @openphase = 1

phase_cursor_loop: --loop through all phases for this importid
fetch next from phase_cursor into @item, @phase, @description, @pmwp_seq
if @@fetch_status = 0
   	begin
   	select @validcnt = Count(*)
   	from bJCJP where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase
   	if @validcnt <> 0 goto phase_cursor_loop
    
   	---- get ProjMinPct for this phase
   	exec @rcode = dbo.bspJCVPHASE @pmco,@project,@phase,@phasegroup, 'Y',@vphase output,@vdesc output,@vphasegroup output,
                 @vcontract output,@vitem output,@vdept output,@projminpct output,@jcjpexists output,@pmsg output
    
   	insert bJCJP (JCCo,Job,PhaseGroup,Phase,Description,Contract,Item,ProjMinPct,ActiveYN,Notes,InsCode)
   	select @pmco, @project, @phasegroup, @phase, @description, @contract, @item, @projminpct,isnull(p.ActiveYN,'Y'),
		p.Notes,p.InsCode
   	from bPMWP p where p.PMCo=@pmco and p.ImportId=@importid and p.Sequence=@pmwp_seq
   	and not exists(select top 1 1 from bJCJP j with (nolock) where j.JCCo=@pmco and j.Job=@project and j.PhaseGroup=@phasegroup
   	and j.Phase=@phase)

	--Update UD Fields--
	set @KeyID = SCOPE_IDENTITY()
	select @UDWhere = null, @UDStatement = null, @SQLString = null
	set @UDWhere = 'where PMCo='+cast(@pmco as varchar(3))+' and ImportId='+char(39)+@importid+char(39)+' and Sequence='+cast(@pmwp_seq as varchar(10))

	execute dbo.vspPMImportUDBuild 'bJCJP', 'PMWP', @UDWhere, @UDStatement output, @errmsg output

	if @UDStatement is not null
	begin
		set @SQLString = 'update JCJP set ' + @UDStatement + ' where KeyID='+cast(@KeyID as varchar(10))
		execute sp_executesql @SQLString
	end
	--------------------

   	goto phase_cursor_loop
   	end

---- deallocate cursor
if @openphase = 1
	begin
	close phase_cursor
	deallocate phase_cursor
	set @openphase = 0
	end

---- 2 sections to update costtypes, materials, subcontracts. If coyn='Y' goto change order section
if @coyn='Y' goto change_order_section

---- insert costtypes from bPMWD into bJCCH where not exists, if exists accumulate orighrs, cost, units
declare costtype_cursor cursor LOCAL FAST_FORWARD
for select Sequence, Item, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, Hours, Units, Costs
from bPMWD where PMCo=@pmco and ImportId=@importid

open costtype_cursor
set @opencosttype=1

costtype_cursor_loop:   --loop through all costtypes for this importid
fetch next from costtype_cursor into @pmwd_seq, @item, @phasegroup, @phase, @costtype, @um, @billflag, @itemunitflag,
              @phaseunitflag, @hours, @units, @costs
if @@fetch_status=0
	begin
	---- get track hours flag from JCCT
	select @trackhours=TrackHours from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@costtype
	if @@rowcount = 0 select @trackhours='N'
	---- @trackhours <> 'Y' zero out hours
	if isnull(@trackhours,'N') <> 'Y'
		begin
		select @hours = 0
		end
	---- get UM from JCCH if exists
   	select @jcchum = UM from JCCH
	where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase= @phase and CostType=@costtype
	if @@rowcount = 0   --insert into bJCCH
   		begin
   		insert bJCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag,
   					BuyOutYN, Plugged, ActiveYN, OrigHours, OrigUnits, OrigCost, SourceStatus, Notes)
   		select @pmco, @project, @phasegroup, @phase, @costtype, @um, @billflag, @itemunitflag, @phaseunitflag,
   					isnull(d.BuyOutYN,'N'), 'N', isnull(d.ActiveYN,'Y'), @hours, @units, @costs, 'Y', d.Notes
   		from bPMWD d where d.PMCo=@pmco and d.ImportId=@importid and d.Sequence=@pmwd_seq
   		----end #134632

		--Update UD Fields--
		set @KeyID = SCOPE_IDENTITY()
		select @UDWhere = null, @UDStatement = null, @SQLString = null
		set @UDWhere = 'where PMCo='+cast(@pmco as varchar(3))+' and ImportId='+char(39)+@importid+char(39)+
		' and Sequence='+cast(@pmwd_seq as varchar(10))

		execute dbo.vspPMImportUDBuild 'bJCCH', 'PMWD', @UDWhere, @UDStatement output, @errmsg output

		if @UDStatement is not null
			begin
			set @SQLString = 'update JCCH set ' + @UDStatement + ' where KeyID='+cast(@KeyID as varchar(10))
			execute sp_executesql @SQLString
			end
		end ----#134632
		--------------------
   	else
		---- accumulate Orighrs, cost, units if upload UM and JCCH.UM are the same
   		begin
   		if @jcchum = @um
   			begin
   			update bJCCH set OrigHours=(OrigHours+@hours), OrigUnits=(OrigUnits+@units), OrigCost=(OrigCost+@costs), SourceStatus='Y'
   			where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
			end
   		else
			begin
   			---- check JCCD for source not = 'OE'
			if exists (select * from bJCCD where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup
                        and Phase=@phase and CostType=@costtype and UM<>@um and JCTransType<>'OE')
                    update bJCCH set OrigHours=(OrigHours+@hours), OrigCost=(OrigCost+@costs), SourceStatus='Y'
                    where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
			else
                    update bJCCH set UM=@um, OrigHours=(OrigHours+@hours), OrigUnits=@units, OrigCost=(OrigCost+@costs), SourceStatus='Y'
                    where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
			end
		end
	goto costtype_cursor_loop
	end

---- close and deallocate cursor
if @opencosttype = 1
   	begin
   	close costtype_cursor
   	deallocate costtype_cursor
   	set @opencosttype = 0
   	end

---- insert subcontract detail into bPMSL from bPMWS
declare subcontract_cursor cursor LOCAL FAST_FORWARD
for select Item, PhaseGroup, Phase, CostType, VendorGroup, Vendor, Units, UM, UnitCost, Amount, WCRetgPct, Description, 
	Notes, Supplier, TaxType, TaxCode, TaxGroup, SMRetgPct, SendFlag, Sequence
from bPMWS where PMCo=@pmco and ImportId=@importid

open subcontract_cursor
set @opensubct=1

subcontract_cursor_loop:   -- -- -- loop through all subcontract detail for this importid
fetch next from subcontract_cursor into @item, @phasegroup, @phase, @costtype, @vendorgroup, @vendor, @units,
                  @um, @unitcost, @costs, @retainpct, @pmsl_desc, @submatl_notes, @ws_Supplier, @ws_TaxType,
				  @ws_TaxCode, @ws_TaxGroup, @ws_SMRetgPct, @ws_SendFlag, @pmws_seq
if @@fetch_status=0
	begin
   	if @um = 'LS'
   		begin
   		select @units = 0, @unitcost = 0
   		end

	if isnull(@pmsl_desc,'') = '' set @pmsl_desc = null
   	select @sequence=isnull(max(Seq),0)+1
   	from bPMSL where PMCo=@pmco and Project=@project
   	---- insert into PMSL #128736
   	insert bPMSL (PMCo, Project, Seq, RecordType, PhaseGroup, Phase, CostType, VendorGroup, Vendor, SLCo, SLItemType,
   			Units, UM, UnitCost, Amount, WCRetgPct, SMRetgPct, SendFlag, SLItemDescription, Notes, Supplier, TaxType,
			TaxCode, TaxGroup)
   	select @pmco, @project, @sequence, 'O', @phasegroup, @phase, @costtype, @vendorgroup, @vendor, @slco, 1,
   			@units, @um, @unitcost, @costs, @retainpct, isnull(@ws_SMRetgPct,0), isnull(@ws_SendFlag,'Y'), @pmsl_desc, 
			@submatl_notes, @ws_Supplier, @ws_TaxType, @ws_TaxCode, @ws_TaxGroup

	--Update UD Fields--
	set @KeyID = SCOPE_IDENTITY()
	select @UDWhere = null, @UDStatement = null, @SQLString = null
	set @UDWhere = 'where PMCo='+cast(@pmco as varchar(3))+' and ImportId='+char(39)+@importid+char(39)+
	' and Sequence='+cast(@pmws_seq as varchar(5))

	execute dbo.vspPMImportUDBuild 'bPMSL', 'PMWS', @UDWhere, @UDStatement output, @errmsg output

	if @UDStatement is not null
	begin
		set @SQLString = 'update PMSL set ' + @UDStatement + ' where KeyID='+cast(@KeyID as varchar(10))
		execute sp_executesql @SQLString
	end
	--------------------
   	goto subcontract_cursor_loop
   	end

---- close and deallocate cursor
if @opensubct = 1
   	begin
   	close subcontract_cursor
   	deallocate subcontract_cursor
   	set @opensubct=0
   	end

---- insert material detail into PMMF from PMWM
declare orgmaterial_cursor cursor LOCAL FAST_FORWARD
for select Item, PhaseGroup, Phase, CostType, MatlGroup, Material, MatlDescription, VendorGroup, Vendor, UM, Units, 
	UnitCost, ECM, Amount, Notes, RecvYN, TaxCode, TaxType, SendFlag, MSCo, Quote, Supplier, MatlOption, Location, INCo,
	Sequence
from bPMWM where PMCo=@pmco and ImportId=@importid

open orgmaterial_cursor
set @openmaterial=1

orgmaterial_cursor_loop:    --loop through all material detail for this importid
fetch next from orgmaterial_cursor into @item, @phasegroup, @phase, @costtype, @matlgroup, @material, @mtldescription,
   			@vendorgroup, @vendor, @um, @units, @unitcost, @ecm, @costs, @submatl_notes, @wm_RecvYN, @wm_TaxCode, 
			@wm_TaxType, @wm_SendFlag, @wm_MSCo, @wm_Quote, @wm_Supplier, @wm_MatlOption, @wm_Location, @wm_INCo,
			@pmwm_seq
if @@fetch_status = 0
   	begin
   	if @um = 'LS'
   		begin
   		select @units = 0, @unitcost = 0 , @ecm = null
   		end

	if @um <> 'LS' and @costs <> 0 and @units = 0 select @units = 1
    
   	---- check if material is in HQMT, if found and stocked then MaterialOption is (M) else (P)
   	select @stocked = 'N', @pqm='P'
   	select @stocked=Stocked from bHQMT WITH (NOLOCK) where MatlGroup=@matlgroup and Material=@material
   	if @@rowcount = 1 and isnull(@stocked,'N') = 'Y' select @pqm = 'M'
   	if @pqm = 'M' and @um = 'LS' select @pqm = 'P'
 
   	---- validate material at location
	set @mo_valid = 'Y'
   	if not exists(select top 1 1 from bINMT where INCo=isnull(@wm_INCo,@inco) and Loc=isnull(@wm_Location,@location) 
				and MatlGroup=@matlgroup and Material=@material)
		begin
   		set @mo_valid = 'N'
		end
   
   	---- if valid stocked material at location and no unit cost - go find one
   	if @pqm = 'M' and @mo_valid = 'Y' and @unitcost = 0
   		begin
   		exec @retcode = dbo.bspINMOMatlUMVal @inco, @location, @material, @matlgroup, @um, @pmco, @project,
   			null, @detailecm output, @detailup output, @errmsg output
   		if @retcode <> 0
   			begin
   			select @detailup = 0, @detailecm = 'E'
   			end
   		select @unitcost = @detailup, @ecm = @detailecm
   		-- calculate Material Cost
   		select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   		select @costs = (@units * @unitcost) / @factor
   		end
  
   	---- insert PMMF material
   	select @sequence=isnull(max(Seq),0)+1
   	from bPMMF where PMCo=@pmco and Project=@project
   	-- insert material detail
   	insert bPMMF (PMCo, Project, Seq, RecordType, MaterialGroup, MaterialCode, MtlDescription, PhaseGroup, 
   			Phase, CostType, MaterialOption, VendorGroup, Vendor, POCo, RecvYN, UM, Units, UnitCost, ECM, 
   			Amount, TaxGroup, SendFlag, INCo, Location, Notes, Supplier, TaxCode, TaxType, MSCo, Quote)
   	select @pmco, @project, @sequence, 'O', @matlgroup, @material, @mtldescription, @phasegroup, 
   			@phase, @costtype, isnull(@wm_MatlOption,@pqm), @vendorgroup, @vendor, @slco, isnull(@wm_RecvYN,'N'), @um, @units, @unitcost, @ecm, 
   			@costs, @taxgroup, isnull(@wm_SendFlag,'Y'),
   			case when @pqm = 'M' and @mo_valid = 'Y' then isnull(@wm_INCo,@inco) else null end,
   			case when @pqm = 'M' and @mo_valid = 'Y' then isnull(@wm_Location,@location) else null end,
   			@submatl_notes, @wm_Supplier, @wm_TaxCode, @wm_TaxType, @wm_MSCo, @wm_Quote

	--Update UD Fields--
	set @KeyID = SCOPE_IDENTITY()
	select @UDWhere = null, @UDStatement = null, @SQLString = null
	set @UDWhere = 'where PMCo='+cast(@pmco as varchar(3))+' and ImportId='+char(39)+@importid+char(39)+
	' and Sequence='+cast(@pmwm_seq as varchar(5))

	execute dbo.vspPMImportUDBuild 'bPMMF', 'PMWM', @UDWhere, @UDStatement output, @errmsg output

	if @UDStatement is not null
	begin
		set @SQLString = 'update PMMF set ' + @UDStatement + ' where KeyID='+cast(@KeyID as varchar(10))
		execute sp_executesql @SQLString
	end
	--------------------
   	goto orgmaterial_cursor_loop
   	end

---- close and deallocate cursor
if @openmaterial = 1
   	begin
   	close orgmaterial_cursor
   	deallocate orgmaterial_cursor
   	set @openmaterial=0
   	end




---- **************** CHANGE ORDER SECTION ****************
change_order_section: -- change order section
---- ******************************************************
if @coyn <> 'Y' goto upload_complete

---- if uploading change order, create pending co header and pending co items, do not do approval at this time
select @newissue=null
if @issueopt = '2' and @existissue is not null select @newissue=@existissue
if @issueopt = '1'
   	begin
   	select @initiator = Null, @dateinit= convert(varchar(30),GetDate())
   	exec @rcode = dbo.bspPMIssueInitialize @pmco,@project,@ourfirm,@initiator,@pcodescription,@dateinit,
          					 @newissue output, @pmsg output
   	if @rcode<>0 select @newissue=null
   	end

--Set override for Contract Type if item amounts exist
if exists (select top 1 1 from dbo.bPMWI where PMCo = @pmco and ImportId = @importid and Amount <> 0)
begin
	set @ContractType = 'Y'
end

select @pco_exists = 'N'
---- create PMOP pending change order header if needed
if not exists(select * from bPMOP where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco)
begin
	---- #132108
	insert bPMOP (PMCo,Project,PCOType,PCO,Description,Issue,Contract,PendingStatus, IntExt,
				----TK-01924 TK-08632
				BudgetType, SubType, POType, ContractType, Status,
				VendorGroup, ResponsibleFirm, DateCreated)
	values(@pmco,@project,@pcotype,@pco,@pcodescription,@newissue,@contract,0,
				----TK-01924
				case when @ContractType = 'N' then 'I' ELSE @intextdefault END,
				@BudgetType, @SubType, @POType, @ContractType, @beginstatus,
				@vendorgroup, @ourfirm, dbo.vfDateOnly())
end
else
begin
	update dbo.bPMOP
	set ContractType = @ContractType
	where PMCo = @pmco and Project = @project and PCOType = @pcotype and PCO = @pco

	select @pco_exists = 'Y'
end

---- from here on has been changed for issue #27450
---- get count of PMWI rows
select @pmwi_count = 0
select @pmwi_count = count(*) from bPMWI where PMCo=@pmco and ImportId=@importid
---- if more than one item and no starting item set to 1 with increment by = 1
if @pmwi_count > 1 and @startingitem is null
	begin
	select @startingitem = 1, @incrementby = 1
	end
---- set staring item
if @pmwi_count > 1 select @pmoi_item_next = @startingitem
if isnull(@incrementby,0) = 0 select @incrementby = 1

if @pmwi_count = 0
	begin
   	select @um='LS', @units=0, @item=null, @itemuc=0, @itemamt = 0
   	end
else
	begin
	---- create cursor on PMWI to cycle through contract items
	declare pmwi_items_cursor cursor LOCAL FAST_FORWARD
	for select Item, UM, Units, Amount, UnitCost, Description
	from bPMWI where PMCo=@pmco and ImportId=@importid

	open pmwi_items_cursor
	select @openpmwi = 1

	pmwi_items_cursor_loop:
	fetch next from pmwi_items_cursor into @item, @um, @units, @itemamt, @itemuc, @description
   	if @@fetch_status <> 0 goto pmwi_items_end
   	end


pmwi_insert_loop:
---- if @pmwi_count = 0 goto pmwi_items_end
---- do something special if count = 1 TK-05746
if @pmwi_count < 2 OR @createcoitem = 'Y'
	begin
	select @pmoi_item = @pcoitem, @pmoi_desc = @pcoitemdesc
	if @pmoi_item is null
		begin
		select @seqitem = ltrim(rtrim(@item)), @pmoi_desc = @description
		exec @retcode = dbo.bspHQFormatMultiPart @seqitem, @inputmask, @pmoi_item output
		end
	if @um='LS'
		begin
		select @units = 0, @itemuc = 0
		end
	goto insert_pmoi_record
	end
else
	begin
	---- if UM='LS' zero out values
	if @um = 'LS'
		begin
		select @units = 0, @itemuc = 0
		end

	---- format @pmoi_item_next to bPCOItem
	select @seqitem = convert(varchar(20), @pmoi_item_next)
	select @pmoi_item = null
	exec @retcode = dbo.bspHQFormatMultiPart @seqitem, @inputmask, @pmoi_item output

	---- set @pmoi_item_next to next item using increment by value
	select @pmoi_item_next = @pmoi_item_next + @incrementby
	select @pmoi_desc=@description
	end

insert_pmoi_record:
----select convert(varchar(3),@pmwi_count), @item as [PMWI_Item], @pcoitem as [PCO_Item], @pmoi_item as [PMOI_Item]
----goto bspexit
if not exists(select PMCo from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype
			and PCO=@pco and PCOItem=@pmoi_item)
	begin
	---- update fixed amount if FixedAmt flag is 'Y'
	if @fixedamt = 'Y'
		begin
		insert into bPMOI (PMCo,Project,PCOType,PCO,PCOItem,Description,Status,UM,Units,UnitPrice,
				PendingAmount,Issue,Contract,ContractItem,Approved,ForcePhaseYN,FixedAmountYN,FixedAmount)
		select @pmco, @project, @pcotype, @pco, @pmoi_item, @pmoi_desc,@beginstatus,@um,@units,
				@itemuc,0,@newissue,@contract,@item,'N','N','Y',@itemamt
		---- insert markups and addons
		if @@rowcount <> 0
			begin
			----PMOM
			insert into bPMOM(PMCo,Project,PCOType,PCO,PCOItem,PhaseGroup,CostType,IntMarkUp,ConMarkUp)
			select @pmco, @project, @pcotype, @pco, @pmoi_item, @phasegroup, a.CostType, 0,
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

			----PMOA
			insert into dbo.bPMOA(PMCo, Project, PCOType, PCO, PCOItem, AddOn, Basis, AddOnPercent, AddOnAmount,
					Status, TotalType, Include, NetCalcLevel, BasisCostType, PhaseGroup)
			select @pmco, @project, @pcotype, @pco, @pmoi_item, a.AddOn, a.Basis, a.Pct, a.Amount,
					'Y', a.TotalType, a.Include, a.NetCalcLevel, a.BasisCostType, a.PhaseGroup
			from dbo.bPMPA a
			----#132046
			join dbo.bPMOP h on h.PMCo=a.PMCo and h.Project=@project and h.PCOType=@pcotype and h.PCO=@pco
			join dbo.bPMDT t on t.DocType=h.PCOType
			----#134354
			where a.PMCo=@pmco and a.Project=@project and a.Standard = 'Y'
			and (h.IntExt = 'E' or (h.IntExt = 'I' and t.InitAddons = 'Y'))
			and not exists(select PMCo from dbo.bPMOA b with (nolock) where b.PMCo=@pmco and b.Project=@project
					and b.PCOType=@pcotype and b.PCO=@pco and b.PCOItem=@pmoi_item and b.AddOn=a.AddOn)
			end
		end
	else
		begin
		insert into bPMOI (PMCo,Project,PCOType,PCO,PCOItem,Description,Status,UM,Units,UnitPrice,
						PendingAmount,Issue,Contract,ContractItem,Approved,ForcePhaseYN,FixedAmountYN,FixedAmount)
		select @pmco,@project,@pcotype,@pco, @pmoi_item, @pmoi_desc, @beginstatus, @um, @units, 0,
						0, @newissue, @contract, @item,'N','N','N',0
		---- insert markups and addons
		if @@rowcount <> 0
			begin
			----PMOM
			insert into bPMOM(PMCo,Project,PCOType,PCO,PCOItem,PhaseGroup,CostType,IntMarkUp,ConMarkUp)
			select @pmco, @project, @pcotype, @pco, @pmoi_item, @phasegroup, a.CostType, 0,
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
			----PMOA
			insert into dbo.bPMOA(PMCo, Project, PCOType, PCO, PCOItem, AddOn, Basis, AddOnPercent, AddOnAmount,
					Status, TotalType, Include, NetCalcLevel, BasisCostType, PhaseGroup)
			select @pmco, @project, @pcotype, @pco, @pmoi_item, a.AddOn, a.Basis, a.Pct, a.Amount,
					'Y', a.TotalType, a.Include, a.NetCalcLevel, a.BasisCostType, a.PhaseGroup
			from dbo.bPMPA a
			----#132046
			join dbo.bPMOP h on h.PMCo=a.PMCo and h.Project=@project and h.PCOType=@pcotype and h.PCO=@pco
			join dbo.bPMDT t on t.DocType=h.PCOType
			----#134354
			where a.PMCo=@pmco and a.Project=@project and a.Standard = 'Y'
			and (h.IntExt = 'E' or (h.IntExt = 'I' and t.InitAddons = 'Y'))
			and not exists(select PMCo from dbo.bPMOA b with (nolock) where b.PMCo=@pmco and b.Project=@project
					and b.PCOType=@pcotype and b.PCO=@pco and b.PCOItem=@pmoi_item and b.AddOn=a.AddOn)
			end
		end
	end


if @pmwi_count > 0
	begin
    fetch next from pmwi_items_cursor into @item, @um, @units, @itemamt, @itemuc, @description
    if @@fetch_status = 0 goto pmwi_insert_loop
	end
	

pmwi_items_end:
if @openpmwi <> 0
	begin
	close pmwi_items_cursor
	deallocate pmwi_items_cursor
	select @openpmwi = 0
	end




---- insert cost type detail from bPMWD into bPMOL where not exists
declare pcodetail_cursor cursor LOCAL FAST_FORWARD
for select Sequence, Item, Phase, CostType, UM, Hours, Units, Costs, BillFlag, ItemUnitFlag, PhaseUnitFlag, ImportItem, Notes
----TK-08632
from bPMWD where PMCo=@pmco and ImportId=@importid

open pcodetail_cursor
select @openpcodetail=1

pcodetail_cursor_loop:   --loop through all costtypes for this importid
fetch next from pcodetail_cursor into @coseq, @item, @phase, @costtype, @um, @hours, @units, @costs,
    				@billflag, @itemunitflag, @phaseunitflag, @importitem, @submatl_notes
if @@fetch_status=0
   	begin
   	-- get needed values from bPMWP for phase
   	select @description=Description from bPMWP with (nolock) where PMCo=@pmco and ImportId=@importid and Phase=@phase
	-- format PCO ContractItem from ImportItem
	set @contractitem = null
	exec @retcode = dbo.bspHQFormatMultiPart @importitem, @itemmask, @contractitem output

	-- get the PCO item assigned to the contract item
	select @pcoitem=PCOItem from bPMOI with (nolock)
	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and Contract=@contract and ContractItem=@contractitem
	if @@rowcount = 0
		begin
		-- get the pco item assigned to the phase contract item
		select @pcoitem=PCOItem from bPMOI with (nolock)
		where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and Contract=@contract and ContractItem=@item
		end

	-- check if phase/costtype in bJCCH for active flag setting
	set @phaseactive='Y'
	select @phaseactive = ActiveYN from bJCCH
	where JCCo=@pmco and Job=@project and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
	if @@rowcount = 0 select @phaseactive = 'Y'

	exec @rcode = dbo.bspPMJCCHAddUpdate @pmco,@project,@phasegroup,@phase,@costtype,@item,@description,@um,
    	 	                      @billflag,@itemunitflag,@phaseunitflag,'N',@phaseactive,'P',null,@pmsg output

	---- check UM
	if @um = 'LS'
		begin
		select @units = 0, @unitcost = 0
		end

	---- get track hours flag from JCCT
	select @trackhours=TrackHours from JCCT with (nolock) where PhaseGroup=@phasegroup and CostType=@costtype
	if @@rowcount = 0 select @trackhours='N'
	---- @trackhours <> 'Y' zero out hours
	if isnull(@trackhours,'N') <> 'Y'
		begin
		select @hours = 0
		end
	---- calculate production
	select @unithour=0, @hourcost=0, @unitcost=0
	if @units<>0 select @unitcost = @costs/@units
	if @hours<>0 select @hourcost = @costs/@hours
	if @units<>0 select @unithour = @hours/@units

	-- insert into bPMOL set the ECM to 'C' this will keep the trigger from adding PMSL and PMMF records
	select @pmolum=UM from bPMOL with (nolock) where PMCo=@pmco and Project=@project and PCOType=@pcotype
    				and PCO=@pco and PCOItem=@pcoitem and Phase=@phase and CostType=@costtype
	-- if no record insert PMOL
	if @@rowcount = 0
		begin
		insert bPMOL(PMCo,Project,PCOType,PCO,PCOItem,PhaseGroup,Phase,CostType,EstUnits,UM,
    	 	   		 	UnitHours,EstHours,HourCost,UnitCost,ECM,EstCost,SendYN, Notes
    	 	   		 	----TK-14980
    	 	   		 	,VendorGroup)
		select @pmco,@project,@pcotype,@pco,@pcoitem,@phasegroup,@phase,@costtype,@units,@um,
    	 	     	 	@unithour,@hours,@hourcost,@unitcost,'C',@costs,'Y', @submatl_notes
    	 	     	 	----TK-14980
    	 	     	 	,@vendorgroup
    	 	     	 	
		---- now update ECM in PMOL set to 'E' TK-08632
		update dbo.bPMOL set ECM='E'
		WHERE PMCo=@pmco and Project=@project
			AND PhaseGroup=@phasegroup 
			AND Phase=@phase 
			AND CostType=@costtype
			AND ECM = 'C'
		end
	else
		-- if UM's are the same update units also
		if @pmolum=@um
			begin
			update bPMOL set EstUnits=EstUnits+@units, EstHours=EstHours+@hours, EstCost=EstCost+@costs
			where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
			and Phase=@phase and CostType=@costtype
			end
		else
			-- if UM's are different do not update units
			begin
			update bPMOL set EstHours=EstHours+@hours, EstCost=EstCost+@costs
			where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
			and Phase=@phase and CostType=@costtype
			end
    

   	goto pcodetail_cursor_loop
   	end

---- close and deallocate cursor
if @openpcodetail = 1
   	begin
   	close pcodetail_cursor
   	deallocate pcodetail_cursor
   	set @openpcodetail = 0
	end


---- insert subcontract detail from bPMWS into bPMSL
declare subct_cursor cursor LOCAL FAST_FORWARD
for select  Sequence, Item, Phase, CostType, Vendor, Units, UM, UnitCost, Amount, WCRetgPct, ImportItem, Description, Notes
from bPMWS with (nolock) where PMCo=@pmco and ImportId=@importid

open subct_cursor
set @opensubct = 1

subct_cursor_loop: --loop through all subcontrtact detail for this importid
fetch next from subct_cursor into @coseq, @item, @phase, @costtype, @vendor, @units, @um, @unitcost, @costs, 
   				@retainpct, @importitem, @pmsl_desc, @submatl_notes
if @@fetch_status = 0
   	begin
	if @um = 'LS'
   		begin
   		select @units = 0, @unitcost = 0
   		end
   
   	if isnull(@pmsl_desc,'') = '' set @pmsl_desc = null

	-- format PCO ContractItem from ImportItem
	set @contractitem = null
	exec @retcode = dbo.bspHQFormatMultiPart @importitem, @itemmask, @contractitem output

	-- get the PCO item assigned to the contract item
	select @pcoitem=PCOItem from bPMOI with (nolock)
	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and Contract=@contract and ContractItem=@contractitem
	if @@rowcount = 0
		begin
		-- get the pco item assigned to the phase contract item
		select @pcoitem=PCOItem from bPMOI with (nolock)
		where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and Contract=@contract and ContractItem=@item
		end

	-- insert subcontract #128736
	select @sequence=isnull(max(Seq),0)+1
	from bPMSL where PMCo=@pmco and Project=@project
	insert bPMSL (PMCo,Project,Seq,RecordType,PCOType,PCO,PCOItem,PhaseGroup,Phase,CostType,
   				VendorGroup, Vendor, SLCo, SLItemType, Units, UM, UnitCost, Amount, WCRetgPct,
   				SMRetgPct, SendFlag, SLItemDescription, Notes)
	select @pmco,@project,@sequence,'C',@pcotype,@pco,@pcoitem,@phasegroup,@phase,@costtype,
            	@vendorgroup, @vendor, @slco, 2, @units, @um, @unitcost, @costs, @retainpct,
   				0, 'Y', @pmsl_desc, @submatl_notes
	goto subct_cursor_loop
	end

---- deallocate cursor
if @opensubct = 1
   	begin
	close subct_cursor
   	deallocate subct_cursor
   	set @opensubct = 0
   	end


---- insert material detail from bPMWM into bPMMF
declare material_cursor cursor LOCAL FAST_FORWARD
for select Sequence, Item, Phase, CostType, Material, MatlDescription, Vendor, UM, Units, UnitCost, ECM, Amount, ImportItem, Notes
from bPMWM with (nolock) where PMCo=@pmco and ImportId=@importid

open material_cursor
set @openmaterial = 1

material_cursor_loop: --loop through all material detail for this importid
fetch next from material_cursor into @coseq, @item, @phase, @costtype, @material, @mtldescription, @vendor, @um,
     		@units, @unitcost, @ecm, @costs, @importitem, @submatl_notes

if @@fetch_status = 0
   	begin
   	if @um = 'LS'
   		begin
		select @units = 0, @unitcost = 0, @ecm = null
		end

	if @um <> 'LS' and @costs <> 0 and @units = 0 select @units = 1

	-- format PCO ContractItem from ImportItem
	set @contractitem = null
	exec @retcode = dbo.bspHQFormatMultiPart @importitem, @itemmask, @contractitem output

	-- get the PCO item assigned to the contract item
	select @pcoitem=PCOItem from bPMOI with (nolock)
	where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and Contract=@contract and ContractItem=@contractitem
	if @@rowcount = 0
		begin
		-- get the pco item assigned to the phase contract item
		select @pcoitem=PCOItem from bPMOI with (nolock)
		where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and Contract=@contract and ContractItem=@item
		end

	-- check if material is in HQMT, if found and stocked then MaterialOption is (M) else (P)
	select @stocked = 'N', @pqm='P'
	select @stocked=Stocked from bHQMT WITH (NOLOCK) where MatlGroup=@matlgroup and Material=@material
	if @@rowcount = 1 and isnull(@stocked,'N') = 'Y' select @pqm = 'M'
	if @pqm = 'M' and @um = 'LS' select @pqm = 'P'

   	-- validate material at location
	set @mo_valid = 'Y'
   	if not exists(select top 1 1 from bINMT where INCo=@inco and Loc=@location 
   			and MatlGroup=@matlgroup and Material=@material)
		begin
   		set @mo_valid = 'N'
		end

	-- if valid stocked material at location and no unit cost - go find one
	if @pqm = 'M' and @mo_valid = 'Y' and @unitcost = 0
   		begin
   		exec @retcode = dbo.bspINMOMatlUMVal @inco, @location, @material, @matlgroup, @um, @pmco, @project,
   			null, @detailecm output, @detailup output, @errmsg output
   		if @retcode <> 0
   			begin
   			select @detailup = 0, @detailecm = 'E'
   			end
   		select @unitcost = @detailup, @ecm = @detailecm
   		-- calculate Material Cost
   		select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   		select @costs = (@units * @unitcost) / @factor
   		end
   
	-- insert material
	select @sequence=isnull(max(Seq),0)+1
	from bPMMF where PMCo=@pmco and Project=@project
	insert bPMMF (PMCo,Project,Seq,RecordType,PCOType,PCO,PCOItem,MaterialGroup,MaterialCode,
   				MtlDescription,PhaseGroup,Phase,CostType,MaterialOption,VendorGroup,Vendor,
   				POCo,RecvYN,UM,Units,UnitCost,ECM,Amount,SendFlag, INCo, Location, Notes)
	select @pmco,@project,@sequence,'C',@pcotype,@pco,@pcoitem,@matlgroup,@material,
   				@mtldescription,@phasegroup,@phase,@costtype,@pqm,@vendorgroup,@vendor,
   				@slco,'N',@um,@units,@unitcost,@ecm,@costs,'Y',
   				case when @pqm = 'M' and @mo_valid = 'Y' then @inco else null end,
   				case when @pqm = 'M' and @mo_valid = 'Y' then @location else null end,
   				@submatl_notes
	goto material_cursor_loop
	end

---- deallocate cursor
if @openmaterial = 1
   	begin
   	close material_cursor
   	deallocate material_cursor
   	set @openmaterial = 0
	end

---- calculate pending amount
select @pcoitem = min(PCOItem) from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco
while @pcoitem is not null
begin
	-- calculate pending amount, addons, markups
	exec @retcode = dbo.bspPMOICalcPendingAmt @pmco, @project, @pcotype, @pco, @pcoitem, @errmsg output

select @pcoitem = min(PCOItem) from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem>@pcoitem
if @@rowcount = 0 select @pcoitem = null
end


-- approve pending change order
if @approveyn<>'Y' goto upload_complete
   
-- get input mask for bContractItem
select @itemmask=InputMask, @itemlength = convert(varchar(10), InputLength)
from DDDTShared with (nolock) where Datatype = 'bACO'
if isnull(@itemmask,'') = '' select @itemmask = 'R'
if isnull(@itemlength,'') = '' select @itemlength = '10'
if @itemmask in ('R','L')
	begin
	select @itemmask = @itemlength + @itemmask + 'N'
	end

select @approveddate = GetDate()

-- format ACO
select @seqitem=rtrim(ltrim(@pco))
exec dbo.bspHQFormatMultiPart @seqitem, @itemmask, @aco output

exec @rcode = dbo.bspPMPCOApprove @pmco, @project, @pcotype, @pco, @aco, @pcodescription, @approveddate,
						0, null, null, @uploadby, null, null, null, 0, null, null, 0, 1, 'new', null, 'Y',
						-- TK-13139 -- CreateChangeOrders and CreateSingleChangeOrder
						'Y', 'Y',
						@pmsg output



upload_complete:

---- need to update bPMWH with upload date and user
select @approveddate = GetDate()
Update bPMWH set UploadDate=@approveddate, UploadBy=@uploadby
where PMCo=@pmco and ImportId=@importid
---- create project firms from PMWS & PMWM if needed
if @createfirm='Y'
	begin
	exec @rcode = dbo.bspPMImportUploadFirms @importid,@pmco,@project,@vendorgroup,@pmsg output
	end

----#139633
---- Setup default security group to have access if securing bJob
If isnull(@jobsecure,'N') = 'Y' and @jobdefaultsecurity is not null
	begin
	if not exists (select * from vDDDS where Datatype = 'bJob' and Qualifier = @pmco
				and Instance = @project and SecurityGroup = @jobdefaultsecurity)
		begin
		Insert vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
		values ('bJob', @pmco, @project, @jobdefaultsecurity)                 
		end
	end

---- Setup default security group to have access if securing bContract
If isnull(@contractsecure,'N') = 'Y' and @contractdefaultsecurity is not null
	begin
	if not exists (select * from vDDDS where Datatype = 'bContract' and Qualifier = @pmco
				and Instance = @contract and SecurityGroup = @contractdefaultsecurity)
		begin
		Insert vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
		values ('bContract', @pmco, @contract, @contractdefaultsecurity)                 
		end
	end
----#139633


commit transaction

end

END TRY

BEGIN CATCH
	begin
	IF @@TRANCOUNT > 0
		begin
		rollback transaction
		end
	select @msg = 'PM Import Upload has failed. ' + ERROR_MESSAGE()
	select @rcode = 1
	end
END CATCH




bspexit:
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspPMImportUpload] TO [public]
GO
