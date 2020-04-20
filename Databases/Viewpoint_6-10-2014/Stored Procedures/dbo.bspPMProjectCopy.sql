SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/******************************************************************************/
CREATE procedure [dbo].[bspPMProjectCopy]
/*******************************************************************************
* Created By:   GF 05/25/2001
* Modified By:	GF 12/07/2001 - Added user memos to some of the table copies.
*				GF 02/06/2002 - Use the contract department for contract items. Issue #16180
*				GF 09/06/2002 - issue #18387 - added start month to JCCI, copy from source.
*				GF 11/19/2002 - enhancement, added TotalType flag to PMOA.
*				GF 02/07/2003 - issue #20317 option to copy submittal items.
*				DC 4/11/03 - issue 20818  get CustGroup from HQCO using ARCo
*				GF 12/05/2003 - #23212 - check error messages, wrap concatenated values with isnull
*				GF 02/10/2004 - #21542 - option to copy drawing logs.
*				GF 03/08/2004 - #23931 - columns added to JCJM.
*				DF 03/19/2004 - #20980 - Default Security and expand Security Group.
*				GF 05/11/2004 - #24513 - Added user memos for bJCCH to copy routine.
*				GF 10/22/2007 - #125909 - added project budgets to copy routine (PMEH,PMED)
*				MV 12/19/2007 - #29702 - Unapproved Enhancement - copy RevGrpInv in JCJM
*				GF 01/03/2008 - issue #120218 dropped unused columns
*				CHS	1/15/08	-	issue #121678 Copy lock phases data from source to destination job
*				GF 02/26/2008 - issue #127210 added basis cost type to add-on copy (PMPA, PMOA)
*				GF 03/11/2008 - issue #127076 JCCM and JCJM country columns added.
*				CHS	06/26/2008	-	issue #126233, #122767 - copy department and bill group info
*				GP 12/09/2008 - Issue 131019, added Supplier to PMMF insert.
*				TRL 03/30/2009 - Issue 132113, added @copyitemretainge parameter
*				GF 04/20/2009 - issue #132326 JCCI start month cannot be null
*				GP 05/12/2009 - Issue 132805 added UseTaxYN to JCJM insert.
*				GP 10/06/2009 - Issue 135571 added copy for Job Reviewers
*				GF 11/08/2009 - issue #136483 - expand job and contract descriptions to 60
*				TJL 12/03/09 - Issue #129894, add fields MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN to be copied
*				GP 01/20/2010 - Issue 135527 add copy for Job Roles and Job Phase Roles
*				GF 04/11/2010 - issue #139029
*				GF 08/03/2010 - issue #134354 added PMPA/PMPC columns
*				GF 03/04/2011 - issue #143523 added JCJP.InsCode to insert for JCJP.
*				GP 06/28/2011 - TK-06445 Added PricingMethod to PMOL insert
*				DAN SO 07/05/2011 - TK-06471 - PMMF select where ... AND Phase IS NOT NULL
*												PMSL select where ... AND Phase IS NOT NULL
*				GF 05/15/2012 TK-13879 copy new columns for JC Job Roles
*
*
* This SP will copy a source project into a destination project within PM.
*
*
* It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
*
* Pass In
* pmco          PM Company
* srcproject    Source PM project
* destpmco      Destination PM company
* destproject   Destination PM project
* projectdesc   Destination project description
* LiabTemplate  JC Liability template
* PRStateCode   PR State Code
* Contract      Contract
* contractdesc  Contract description
* department    Department for contract
* Customer      Customer for contract
* RetainPCT     Retainage percentage for contract
* StartMonth    Start Month for contract
* amountopt     Copy amounts option (0 - none, 1 - all, 2 - original estimates)
* subcontractyn Copy subcontract detail flag
* materialyn    Copy material detail flag
* firmsyn       Copy project firms flag
* otherdocyn    Copy other documents flag
* submittalyn   Copy submittals flag
* issueyn       Copy issues flag
* dailylogyn    Copy daily logs flag
* punchlistyn   Copy punch list flag
* meetingminyn  Copy meeting minutes flag
* rfiyn         Copy RFI'S flag
* rfqyn         Copy RFQ's flag
* transmittalyn Copy transmittals flag
* submittalitemsyn Copy submittal items flag
* projbudgets	Copy project budgets flag
* username      User name
*
* RETURN PARAMS
*   msg           Error Message, or Success message
*
* Returns
*      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
*
********************************************************************************/

(@pmco bCompany = Null, @srcproject bJob = Null, @destpmco bCompany = null, @destproject bJob = Null,
 @projectdesc bItemDesc = Null, @liabtemplate smallint = null, @prstate varchar(4) = null, @contract bContract = null,
 @contractdesc bItemDesc = Null, @department bDept = Null, @customer bCustomer = null, @jccmretpct bPct,
 @startmonth bMonth, @amountopt char(1) = '0', @subcontractyn bYN = 'N', @materialyn bYN = 'N',
 @firmyn bYN = 'N', @chgheader bYN = 'N', @chgitems bYN = 'N', @chgdetail bYN = 'N', @otherdocyn bYN = 'N',
 @submittalyn bYN = 'N', @issueyn bYN = 'N', @dailylogyn bYN = 'N', @punchlistyn bYN = 'N',
 @meetingminyn bYN = 'N', @rfiyn bYN = 'N', @rfqyn bYN = 'N', @transmittalyn bYN = 'N',
 @submittalitemsyn bYN = 'N', @drawinglogsyn bYN = 'N', @projbudgetsyn bYN = 'N',
 @username varchar(15) = Null, @copyitemdept bYN = 'N', @copyitembillgroup bYN = 'N', 
 @copyitemretainge bYN='N', @copyjobreviewers bYN='N', @CopyJobRoles bYN = 'N', @CopyJobPhaseRoles bYN = 'N', 
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @sequence int, @validcnt int, @openpmsl_cursor tinyint, @openpmmf_cursor tinyint,
        @openpmpf_cursor tinyint, @pmpfseq int, @pmslseq int, @pmmfseq int, @openpmsm_cursor tinyint

declare @xphasegroup bGroup, @xmatlgroup bGroup, @xvendorgroup bGroup, @xtaxgroup bGroup, @xcustgroup bGroup,
        @phasegroup bGroup, @matlgroup bGroup, @vendorgroup bGroup, @taxgroup bGroup, @custgroup bGroup,
        @xprco bCompany, @apco bCompany, @prco bCompany, @phasegrpyn bYN, @matlgrpyn bYN, @taxgrpyn bYN,
        @custgrpyn bYN, @vendgrpyn bYN, @prcoyn bYN, @pmcoyn bYN, @srccontract bContract, @contractstatus tinyint

declare @recordtype char(1), @pcotype bDocType, @pco bPCO, @pcoitem bPCOItem, @aco bACO, @acoitem bACOItem,
        @phase bPhase, @costtype bJCCType, @vendor bVendor, @slitemtype tinyint, @units bUnits, @um bUM,
        @unitcost bUnitCost, @amount bDollar, @subco smallint, @wcretgpct bPct, @smretgpct bPct,
        @supplier bVendor, @sendflag bYN

declare @materialcode bMatl, @vendmatid varchar(30), @mtldescription bItemDesc, @materialoption char(1),
        @recvyn bYN, @ecm bECM, @reqdate bDate, @taxcode bTaxCode, @taxtype tinyint, @requisitionnum varchar(20)

declare @pmpfgroup bGroup, @firm bFirm, @contact bEmployee, @pmpfdesc bDesc, @joins varchar(1000),
		@where varchar(1000), @jobsecure bYN, @jobdefaultsecurity int, 
		@contractsecure bYN, @contractdefaultsecurity int,	@pmpfud_flag bYN, @pmpaud_flag bYN,
		@pmpcud_flag bYN, @jcciud_flag bYN, @jcjpud_flag bYN, @jcchud_flag bYN, @jccmud_flag bYN,
		@jcjmud_flag bYN, @insert varchar(1000), @select varchar(1000), @sql varchar(max),
		@pmsmud_flag bYN, @processgroup varchar(10), @pmehud_flag bYN, @pmedud_flag bYN

select @rcode = 0, @openpmsl_cursor = 0, @openpmmf_cursor = 0, @openpmsm_cursor = 0,
		@phasegrpyn = 'Y', @matlgrpyn = 'Y', @taxgrpyn = 'Y', @custgrpyn = 'Y', @vendgrpyn = 'Y', @prcoyn = 'Y',
		@pmcoyn = 'Y', @pmpfud_flag = 'N', @pmpaud_flag = 'N', @pmpcud_flag = 'N', @jcciud_flag = 'N',
		@jcjpud_flag = 'N', @jcchud_flag = 'N', @jccmud_flag = 'N', @jcjmud_flag = 'N', @pmsmud_flag = 'N',
		@pmehud_flag = 'N', @pmedud_flag = 'N'

if @pmco is null
    begin
    select @msg = 'Missing PM company', @rcode = 1
    goto bspexit
    end

if @srcproject is null
    begin
    select @msg = 'Missing Source Project', @rcode = 1
    goto bspexit
    end

if @destpmco is null
    begin
    select @msg = 'Missing Destination PM company', @rcode = 1
    goto bspexit
    end

if @destproject is null
    begin
    select @msg = 'Missing Destination Project', @rcode = 1
    goto bspexit
    end

if @contract is null
    begin
    select @msg = 'Missing Destination Contract', @rcode = 1
    goto bspexit
    end

if @department is null
    begin
    select @msg = 'Missing contract department', @rcode = 1
    goto bspexit
    end

-- validate source project
select @srccontract=Contract from bJCJM with (nolock) where JCCo=@pmco and Job=@srcproject
if @@rowcount = 0
    begin
    select @msg = 'Invalid source project - ' + isnull(@srcproject,'') + ' not found in JCJM.', @rcode = 1
    goto bspexit
    end

-- verify destination project not in JCJM
select @validcnt=count(*) from bJCJM with (nolock) where JCCo=@destpmco and Job=@destproject
if @validcnt <> 0
    begin
    select @msg = 'Invalid destination project - ' + isnull(@destproject,'') + ' must not be in JCJM.', @rcode = 1
    goto bspexit
    end

-- start: DC 4/11/03  issue 20818
select @xcustgroup=h.CustGroup
from bHQCO h with (nolock) JOIN bJCCO j with (nolock) ON (h.HQCo = j.ARCo)
where j.JCCo = @pmco
if @@rowcount <> 1
    begin
    select @msg='Invalid HQ Company ' + convert(varchar(3),@pmco) + '!', @rcode=1
    goto bspexit
    end
-- End

-- load groups from HQCO for source PMCO
select @xphasegroup=PhaseGroup, @xmatlgroup=MatlGroup, @xtaxgroup=TaxGroup
from bHQCO with (nolock) where HQCo=@pmco
if @@rowcount = 0
    begin
    select @msg = 'Invalid HQ source company ' + convert(varchar(3),@pmco) + '!', @rcode = 1
    goto bspexit
    end

-- load source vendor group - use APCo from PMCo
select @apco=APCo, @xprco=PRCo from bPMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0
    begin
    select @msg = 'Invalid AP source company ' + convert(varchar(3),@apco) + ' in PMCO - unable to load vendor group', @rcode = 1
    goto bspexit
    end

select @xvendorgroup=VendorGroup from bHQCO with (nolock) where HQCo=@apco
if @@rowcount = 0
    begin
    select @msg = 'Invalid HQ source company ' + convert(varchar(3),@apco) + '!', @rcode =1
    goto bspexit
    end


-- load groups from HQCO for destination PMCO - only if @pmco<>@destpmco
if @pmco = @destpmco
    begin
    select @phasegroup=@xphasegroup, @matlgroup=@xmatlgroup, @taxgroup=@xtaxgroup,
           @custgroup=@xcustgroup, @vendorgroup=@xvendorgroup, @prco=@xprco
    end
else
    begin
	-- start: DC 4/11/03  issue 20818
	select @custgroup=h.CustGroup
	from bHQCO h with (nolock) JOIN bJCCO j with (nolock) ON (h.HQCo = j.ARCo)
	where j.JCCo = @destpmco
	if @@rowcount <> 1
	    begin
	    select @msg='Invalid destination Company ' + convert(varchar(3),@pmco) + '!', @rcode=1
	    goto bspexit
	    end
	-- End
    select @phasegroup=PhaseGroup, @matlgroup=MatlGroup, @taxgroup=TaxGroup
    from bHQCO with (nolock) where HQCo=@destpmco
    if @@rowcount = 0
        begin
        select @msg='Invalid HQ destination company ' + convert(varchar(3),@destpmco) + '!', @rcode=1
        goto bspexit
        end

    -- load destination vendor group - use APCo from PMCo
    select @apco=APCo, @prco=PRCo from bPMCO with (nolock) where PMCo=@destpmco
    if @@rowcount = 0
        begin
        select @msg = 'Invalid AP destination company ' + convert(varchar(3),@apco) + ' in PMCO - unable to load vendor group', @rcode = 1
        goto bspexit
        end

    select @vendorgroup=VendorGroup from bHQCO with (nolock) where HQCo=@apco
    if @@rowcount = 0
        begin
        select @msg = 'Invalid HQ destination company ' + convert(varchar(3),@apco) + '!', @rcode =1
        goto bspexit
        end
    end


-- set group flags to track whether the groups are consistent between source and destination
if @xphasegroup <> @phasegroup select @phasegrpyn = 'N'
if @xmatlgroup <> @matlgroup select @matlgrpyn = 'N'
if @xtaxgroup <> @taxgroup select @taxgrpyn = 'N'
if @xcustgroup <> @custgroup select @custgrpyn = 'N'
if @xvendorgroup <> @vendorgroup select @vendgrpyn = 'N'
if @xprco <> @prco select @prcoyn = 'N'

if @pmco <> @destpmco select @pmcoyn = 'N'



-- set the user memo flags for the tables that have user memos
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.PMPA'))
	select @pmpaud_flag = 'Y'

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.PMPC'))
	select @pmpcud_flag = 'Y'

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.PMPF'))
	select @pmpfud_flag = 'Y'

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.JCCI'))
	select @jcciud_flag = 'Y'

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.JCJP'))
	select @jcjpud_flag = 'Y'

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.JCCH'))
	select @jcchud_flag = 'Y'

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.JCCM'))
	select @jccmud_flag = 'Y'

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.JCJM'))
	select @jcjmud_flag = 'Y'

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.PMSM'))
	select @pmsmud_flag = 'Y'

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.PMEH'))
	select @pmehud_flag = 'Y'

if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.PMED'))
	select @pmedud_flag = 'Y'


---- if source pmco differs from destination pmco see if JCCM.ProcessGroup is still valid
set @processgroup = null
select @processgroup=ProcessGroup from JCCM c with (nolock) where JCCo=@pmco and Contract=@srccontract
if isnull(@processgroup,'') <> '' and @pmco <> @destpmco
	begin
	if not exists(select * from JBPG with (nolock) where JBCo=@destpmco and ProcessGroup = @processgroup)
		set @processgroup = null
	end




begin transaction

-- -- -- insert contract into bJCCM if does not exists, else check status
select @contractstatus = ContractStatus
from JCCM with (nolock) where JCCo=@destpmco and Contract=@contract
if @@rowcount = 0
    begin
    select @contractstatus = 0
    insert into JCCM (JCCo, Contract, Description, Department, ContractStatus, OriginalDays, CurrentDays, StartMonth,
            CustGroup, Customer, PayTerms, TaxInterface, TaxGroup, TaxCode, RetainagePCT, DefaultBillType,
            OrigContractAmt, ContractAmt, BilledAmt, ReceivedAmt, CurrentRetainAmt, SIRegion, SIMetric,
            ProcessGroup, BillAddress, BillAddress2, BillCity, BillState, BillZip, BillOnCompletionYN,
            CustomerReference, CompleteYN, RoundOpt, ReportRetgItemYN, ProgressFormat, TMFormat, BillGroup,
            BillDayOfMth, ArchitectName, ArchitectProject, ContractForDesc, StartDate, JBTemplate,
            JBFlatBillingAmt, JBLimitOpt, Notes, BillNotes, RecType, ClosePurgeFlag, MiscDistCode, SecurityGroup,
			UpdateJCCI,BillCountry, MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle)
    select @destpmco, @contract, @contractdesc, @department, @contractstatus, 0, 0, @startmonth,
			@custgroup, @customer, c.PayTerms, c.TaxInterface, @taxgroup,
			TaxCode = case when @taxgrpyn='Y' then c.TaxCode else null end, @jccmretpct, c.DefaultBillType,
			0, 0, 0, 0, 0, c.SIRegion, c.SIMetric,
			@processgroup, c.BillAddress, c.BillAddress2, c.BillCity, c.BillState, c.BillZip, c.BillOnCompletionYN,
			null, 'N', c.RoundOpt, c.ReportRetgItemYN, c.ProgressFormat, c.TMFormat, c.BillGroup,
			c.BillDayOfMth, c.ArchitectName, c.ArchitectProject, c.ContractForDesc, c.StartDate, c.JBTemplate,
			c.JBFlatBillingAmt, c.JBLimitOpt, c.Notes, c.BillNotes, c.RecType, 'N', c.MiscDistCode,
			c.SecurityGroup, 'N', c.BillCountry, c.MaxRetgOpt, c.MaxRetgPct, c.MaxRetgAmt, c.InclACOinMaxYN, c.MaxRetgDistStyle
    from JCCM c with (nolock) where c.JCCo=@pmco and c.Contract=@srccontract
	if @@rowcount <> 0 and @jccmud_flag = 'Y'
		begin
		-- build joins and where clause
		select @joins = ' from JCCM join JCCM z on z.JCCo = ' + convert(varchar(3),@pmco) + ' and z.Contract = ' + CHAR(39) + @srccontract + CHAR(39)
		select @where = ' where JCCM.JCCo = ' + convert(varchar(3),@destpmco) + ' and JCCM.Contract = ' + CHAR(39) + @contract + CHAR(39)
		-- execute user memo update
		exec @rcode = dbo.bspPMProjectCopyUserMemos 'JCCM', @joins, @where, @msg output
		end

		-- copy bill groups  CHS 06/26/2008 - issue #126233, #122767
		if @copyitembillgroup = 'Y'
			begin
				insert into bJBBG(JBCo, Contract, BillGroup, Description, Notes)
				select @destpmco, @contract, g.BillGroup, g.Description, g.Notes
				from bJBBG g
				where g.JBCo = @pmco and g.Contract = @srccontract 
					and not exists(select top 1 1 from bJBBG bg where bg.JBCo = @destpmco and bg.Contract = @contract)
			end	
    end
else
    begin
    -- check for valid contract status
    If isnull(@contractstatus,0) > 1
        begin
        select @msg = 'Invalid contract status for contract - ' + @contract + ' - must be pending or open.', @rcode = 1
        goto bspexit
        end
    end

-- insert destination project into bJCJM
insert into JCJM (JCCo, Job, Description, Contract, JobStatus, BidNumber, LockPhases, ProjectMgr, JobPhone, JobFax,
		MailAddress, MailCity, MailState, MailZip, MailAddress2, ShipAddress, ShipCity, ShipState, ShipZip, ShipAddress2,
		LiabTemplate, TaxGroup, TaxCode, InsTemplate, MarkUpDiscRate, PRLocalCode, PRStateCode, Certified,
		EEORegion, SMSACode, CraftTemplate, ProjMinPct, SLCompGroup, POCompGroup, VendorGroup,
		ArchEngFirm, OurFirm, OTSched, PriceTemplate, HaulTaxOpt, GeoCode, BaseTaxOn, Notes, WghtAvgOT, HrsPerManDay, 
		UpdatePlugs, AutoAddItemYN, AutoGenSubNo, ContactCode, SecurityGroup, DefaultStdDaysDue, DefaultRFIDaysDue,
		UpdateAPActualsYN, UpdateMSActualsYN, AutoGenPCONo, AutoGenMTGNo, AutoGenRFINo, RateTemplate,
		RevGrpInv, MailCountry, ShipCountry, UseTaxYN)

select  @destpmco, @destproject, @projectdesc, @contract, @contractstatus, j.BidNumber, j.LockPhases,
		ProjectMgr = case when @pmcoyn='Y' then j.ProjectMgr else null end, j.JobPhone, j.JobFax,
		j.MailAddress, j.MailCity, j.MailState, j.MailZip, j.MailAddress2, j.ShipAddress, j.ShipCity, j.ShipState,
		j.ShipZip, j.ShipAddress2, @liabtemplate, @taxgroup,
		TaxCode = case when @taxgrpyn='Y' then j.TaxCode else null end,
		InsTemplate = case when @pmcoyn='Y' then j.InsTemplate else null end, j.MarkUpDiscRate,
		PRLocalCode = case when @prcoyn='Y' then j.PRLocalCode else null end, @prstate, j.Certified,
		EEORegion = case when @prcoyn='Y' then j.EEORegion else null end,
		SMSACode = case when @prcoyn='Y' then j.SMSACode else null end,
		CraftTemplate = case when @prcoyn='Y' then j.CraftTemplate else null end, j.ProjMinPct,
		SLCompGroup = case when @vendgrpyn='Y' then j.SLCompGroup else null end,
		POCompGroup = case when @vendgrpyn='Y' then j.POCompGroup else null end, @vendorgroup,
		ArchEngFirm = case when @vendgrpyn='Y' then j.ArchEngFirm else null end,
		OurFirm = case when @vendgrpyn = 'Y' then j.OurFirm else null end,
		OTSched = case when @prcoyn='Y' then j.OTSched else null end, j.PriceTemplate, j.HaulTaxOpt,
		GeoCode = case when @prcoyn='Y' then j.GeoCode else null end, j.BaseTaxOn, j.Notes,
		j.WghtAvgOT, j.HrsPerManDay, j.UpdatePlugs, j.AutoAddItemYN, j.AutoGenSubNo, j.ContactCode, 
		j.SecurityGroup, j.DefaultStdDaysDue, j.DefaultRFIDaysDue, j.UpdateAPActualsYN, j.UpdateMSActualsYN,
		j.AutoGenPCONo, j.AutoGenMTGNo, j.AutoGenRFINo, j.RateTemplate,
		j.RevGrpInv, j.MailCountry, j.ShipCountry, j.UseTaxYN
from JCJM j with (nolock) where j.JCCo=@pmco and j.Job=@srcproject
if @@rowcount <> 0 and @jcjmud_flag = 'Y'
	begin
	-- build joins and where clause
	select @joins = ' from JCJM join JCJM z on z.JCCo = ' + convert(varchar(3),@pmco) + ' and z.Job = ' + CHAR(39) + @srcproject + CHAR(39)
	select @where = ' where JCJM.JCCo = ' + convert(varchar(3),@destpmco) + ' and JCJM.Job = ' + CHAR(39) + @destproject + CHAR(39)
	-- execute user memo update
	exec @rcode = dbo.bspPMProjectCopyUserMemos 'JCJM', @joins, @where, @msg output
	end


-- insert contract items if missing in destination contract
select @insert = null, @select = null

select @department=Department from bJCCM with (nolock) where JCCo=@destpmco and Contract=@contract

if @jcciud_flag = 'Y'
	begin
	exec @rcode = dbo.bspPMProjectCopyUDBuild 'JCCI', 'i', @insert output, @select output, @msg output
	end

select @sql = 'insert into JCCI (JCCo, Contract, Item, Description, Department, TaxGroup, TaxCode, UM, SIRegion, SICode, ' +
		'RetainPCT, OrigContractAmt, OrigContractUnits, OrigUnitPrice, ContractAmt, ContractUnits, UnitPrice, ' +
		'BilledAmt, BilledUnits, ReceivedAmt, CurrentRetainAmt, BillType, BillGroup, BillDescription, ' +
		'BillOriginalUnits, BillOriginalAmt, BillCurrentUnits, BillCurrentAmt, BillUnitPrice, InitSubs, Notes, ' +
		'MarkUpRate, ProjPlug, StartMonth'

-- -- -- if isnull(@insert,'') <> '' select @sql = @sql + @insert

select @sql = @sql + ') select ' + convert(varchar(3),@destpmco) + ', ' + CHAR(39) + @contract + CHAR(39) +
	', i.Item, i.Description, ' 

if @copyitemdept = 'Y' select @sql = @sql + 'i.Department'
else select @sql = @sql + CHAR(39) + @department + CHAR(39) 


select @sql = @sql + ', ' + convert(varchar(3),@taxgroup) + ', ' +
	'TaxCode = case when ' + convert(varchar(3),@xtaxgroup) + ' = ' + convert(varchar(3),@taxgroup) + ' then i.TaxCode else null end, ' +
	'i.UM, i.SIRegion, i.SICode,'+
	/**Issue 132113*/
	' RetainPCT = case when ' + CHAR(39) + @copyitemretainge + CHAR(39) + ' = ' + Char(39) + Char(89) + Char(39) +'then i.RetainPCT else '+ convert(varchar,@jccmretpct) +' end, ' +
	'OrigContractAmt = case when ' + CHAR(39) + @amountopt + CHAR(39) + ' = 0 then 0 else i.OrigContractAmt end, ' +
	'OrigContractUnits = case when ' + CHAR(39) + @amountopt + CHAR(39) + ' = 0 then 0 else i.OrigContractUnits end, ' +
	'OrigUnitPrice = case when ' + CHAR(39) + @amountopt + CHAR(39) + ' = 0 then 0 else i.OrigUnitPrice end, ' +
	'0, 0, 0, 0, 0, 0, 0, i.BillType, i.BillGroup, i.BillDescription, 0, 0, 0, 0, 0, i.InitSubs, ' +
	'i.Notes, i.MarkUpRate, i.ProjPlug, ' + CHAR(39) + convert(varchar(30),@startmonth) + CHAR(39)
	

-- -- -- if isnull(@insert,'') <> '' select @sql = @sql + @select

select @sql = @sql + ' from JCCI i where i.JCCo = ' + convert(varchar(3),@pmco) + ' and i.Contract = ' + CHAR(39) + @srccontract + CHAR(39) +
	' and not exists(select Item from JCCI a where a.JCCo = ' + convert(varchar(3),@destpmco) + ' and a.Contract = ' + CHAR(39) + @contract + CHAR(39) +
	' and a.Item=i.Item)'

exec (@sql)


-- insert phases into bJCJP if missing in destination project - only if phase groups match
if @phasegrpyn = 'Y'
    begin

	select @insert = null, @select = null
	if @jcjpud_flag = 'Y'
		begin
		exec @rcode = dbo.bspPMProjectCopyUDBuild 'JCJP', 'p', @insert output, @select output, @msg output
		end

	----#143523
	select @sql = 'insert into JCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN, InsCode, Notes'

	if isnull(@insert,'') <> '' select @sql = @sql + @insert
	----143523
	select @sql = @sql + ') select ' + convert(varchar(3),@destpmco) + ', ' + CHAR(39) + @destproject + CHAR(39) + ', ' +
		convert(varchar(3),@phasegroup) + ', p.Phase, p.Description, ' + CHAR(39) + @contract + CHAR(39) + ', p.Item, p.ProjMinPct, ' +
		CHAR(39) +  'Y' + CHAR(39) + ', p.InsCode, p.Notes'

	if isnull(@insert,'') <> '' select @sql = @sql + @select

	select @sql = @sql + ' from JCJP p where p.JCCo = ' + convert(varchar(3),@pmco) + ' and p.Job = ' + CHAR(39) + @srcproject + CHAR(39) +
    	' and not exists(select Phase from JCJP a where a.JCCo = ' + convert(varchar(3),@destpmco) + ' and a.Job = ' + CHAR(39) + @destproject + CHAR(39) +
		' and a.Phase=p.Phase)'

	exec (@sql)


	select @insert = null, @select = null
	if @jcchud_flag = 'Y'
		begin
		exec @rcode = dbo.bspPMProjectCopyUDBuild 'JCCH', 'h', @insert output, @select output, @msg output
		end

	select @sql = 'insert into JCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, ' +
				  'BuyOutYN, Plugged, ActiveYN, OrigHours, OrigUnits, OrigCost, SourceStatus, Notes'

	if isnull(@insert,'') <> '' select @sql = @sql + @insert

	select @sql = @sql + ') select ' + convert(varchar(3),@destpmco) + ', ' + CHAR(39) + @destproject + CHAR(39) + ', ' +
			convert(varchar(3),@phasegroup) + ', h.Phase, h.CostType, h.UM, h.BillFlag, h.ItemUnitFlag, h.PhaseUnitFlag, ' +
			'h.BuyOutYN, ' + CHAR(39) + 'N' + CHAR(39) + ', ' + CHAR(39) + 'Y' + CHAR(39) + ', ' +
			'OrigHours = case when ' + CHAR(39) + @amountopt + CHAR(39) + ' = 0 then 0 else h.OrigHours end, ' +
			'OrigUnits = case when ' + CHAR(39) + @amountopt + CHAR(39) + ' = 0 then 0 else h.OrigUnits end, ' +
			'OrigCost = case when ' + CHAR(39) + @amountopt + CHAR(39) + ' = 0 then 0 else h.OrigCost end, ' +
			CHAR(39) + 'Y' + CHAR(39) + ', h.Notes'

	if isnull(@insert,'') <> '' select @sql = @sql + @select

	select @sql = @sql + ' from JCCH h where h.JCCo = ' + convert(varchar(3),@pmco) + ' and h.Job = ' + CHAR(39) + @srcproject + CHAR(39) +
		' and not exists(select CostType from JCCH a where a.JCCo = ' + convert(varchar(3),@destpmco) + ' and a.Job = ' + 
		CHAR(39) + @destproject + CHAR(39) + ' and a.Phase=h.Phase and a.CostType=h.CostType)'

	exec (@sql)
    end

-- insert project addons into bPMPA if missing in destination project
select @insert = null, @select = null
if @pmpaud_flag = 'Y'
	begin
	exec @rcode = dbo.bspPMProjectCopyUDBuild 'PMPA', 'b', @insert output, @select output, @msg output
	end

----#134354
select @sql = 'insert into PMPA (PMCo, Project, AddOn, Description, Basis, Pct, Amount, ' +
			  'PhaseGroup, Phase, CostType, Contract, Item, Notes, TotalType, Include, NetCalcLevel, BasisCostType, ' +
			  'RevRedirect, RevItem, RevStartAtItem, RevFixedACOItem, RevUseItem, Standard, RoundAmount '

if isnull(@insert,'') <> '' select @sql = @sql + @insert


select @sql = @sql + ') select ' + convert(varchar(3),@destpmco) + ', ' + CHAR(39) + @destproject + CHAR(39) +
		', b.AddOn, b.Description, b.Basis, b.Pct, b.Amount, ' + convert(varchar(3),@phasegroup) + ', ' +
        'Phase = case when ' + convert(varchar(3),@xphasegroup) + ' = ' + convert(varchar(3),@phasegroup) + ' then b.Phase else null end, ' +
        'CostType = case when ' + convert(varchar(3),@xphasegroup) + ' = ' + convert(varchar(3),@phasegroup) + ' then b.CostType else null end, ' +
        CHAR(39) + @contract + CHAR(39) + ', b.Item, b.Notes, b.TotalType, b.Include, b.NetCalcLevel, b.BasisCostType, ' +
        'b.RevRedirect, b.RevItem, b.RevStartAtItem, b.RevFixedACOItem, b.RevUseItem, b.Standard, b.RoundAmount '
----#134354

if isnull(@insert,'') <> '' select @sql = @sql + @select

select @sql = @sql + ' from dbo.PMPA b where b.PMCo = ' + convert(varchar(3),@pmco) + ' and b.Project = ' + CHAR(39) + @srcproject + CHAR(39) +
		' and not exists(select AddOn from dbo.PMPA a where a.PMCo = ' + convert(varchar(3),@destpmco) + ' and a.Project = ' + CHAR(39) + @destproject + CHAR(39) +
		' and a.AddOn=b.AddOn)'

exec (@sql)


-- insert project markups into bPMPC if missing in destination project - only if phase groups match
if @phasegrpyn = 'Y'
    begin
	select @insert = null, @select = null

	if @pmpcud_flag = 'Y'
		begin
		exec @rcode = dbo.bspPMProjectCopyUDBuild 'PMPC', 'b', @insert output, @select output, @msg output
		end
	----#134354
	select @sql = 'insert into PMPC (PMCo, Project, PhaseGroup, CostType, Markup, RoundAmount'

	if isnull(@insert,'') <> '' select @sql = @sql + @insert

	select @sql = @sql + ') select ' + convert(varchar(3),@destpmco) + ', ' + CHAR(39) + @destproject + CHAR(39) +
			', ' + convert(varchar(3),@phasegroup) + ', b.CostType, b.Markup, b.RoundAmount'

	if isnull(@insert,'') <> '' select @sql = @sql + @select

	select @sql = @sql + ' from PMPC b where b.PMCo = ' + convert(varchar(3),@pmco) + ' and b.Project = ' + CHAR(39) + @srcproject + CHAR(39) +
			' and not exists(select CostType from PMPC a where a.PMCo = ' + convert(varchar(3),@destpmco) + ' and a.Project = ' + CHAR(39) + @destproject + CHAR(39) +
			' and a.CostType=b.CostType)'

	exec (@sql)
    end



-- insert project firms into bPMPF if missing in destination project - only if phase groups match
if @phasegrpyn = 'Y' and @firmyn = 'Y'
BEGIN
    declare bcPMPF cursor LOCAL FAST_FORWARD 
	for select Seq
    from PMPF where PMCo=@pmco and Project=@srcproject

    open bcPMPF
    select @openpmpf_cursor = 1

    PMPF_loop:

    fetch next from bcPMPF into @pmpfseq

    if @@fetch_status <> 0 goto PMPF_end

    -- read project firm data
    select @pmpfgroup=VendorGroup, @firm=FirmNumber, @contact=ContactCode, @pmpfdesc=Description
    from PMPF with (nolock) where PMCo=@pmco and Project=@srcproject and Seq=@pmpfseq
	if @@rowcount = 0 goto PMPF_loop

    -- get next sequence number
    select @sequence=max(Seq) + 1
    from PMPF where PMCo=@destpmco and Project=@destproject
	if isnull(@sequence,0) = 0 set @sequence = 1

	--insert into PMPF
    insert PMPF (PMCo, Project, Seq, VendorGroup, FirmNumber, ContactCode, Description, Notes, PortalSiteAccess)
    select @destpmco, @destproject, @sequence, @pmpfgroup, @firm, @contact, @pmpfdesc, Notes, PortalSiteAccess
	from PMPF with (nolock) where PMCo=@pmco and Project=@srcproject and Seq=@pmpfseq
	and not exists(select top 1 1 from PMPF a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
				and a.VendorGroup=@pmpfgroup and a.FirmNumber=@firm and a.ContactCode=@contact)
	if @@Error <> 0 goto bspexit
	if @@rowcount <> 0 and @pmpfud_flag = 'Y'
		begin
		-- build joins and where clause
		select @joins = ' from PMPF join PMPF z on z.PMCo = ' + convert(varchar(3),@pmco) + ' and z.Project = ' +
					CHAR(39) + @srcproject + CHAR(39) + ' and z.Seq = ' + convert(varchar(10),@pmpfseq)
		select @where = ' where PMPF.PMCo = ' + convert(varchar(3),@destpmco) + ' and PMPF.Project = ' +
					CHAR(39) + @destproject + CHAR(39) + ' and PMPF.Seq = ' + convert(varchar(10),@sequence)
		-- execute user memo update
		exec @rcode = dbo.bspPMProjectCopyUserMemos 'PMPF', @joins, @where, @msg output
		end

    goto PMPF_loop

    PMPF_end:
        if @openpmpf_cursor = 1
            begin
      	    close bcPMPF
      	    deallocate bcPMPF
 	        select @openpmpf_cursor = 0
            end
END


-- insert issue into bPMIM if missing in destination project
if  @issueyn = 'Y'
    begin
    insert into bPMIM (PMCo, Project, Issue, Description, DateInitiated, VendorGroup, FirmNumber,
			Initiator, MasterIssue, DateResolved, Status, Notes)
    select @destpmco, @destproject, i.Issue, i.Description, i.DateInitiated, @vendorgroup,
            FirmNumber = case when @vendgrpyn='Y' then i.FirmNumber else null end,
            Initiator = case when @vendgrpyn='Y' then i.Initiator else null end,
            i.MasterIssue, i.DateResolved, i.Status, i.Notes
    from bPMIM i with (nolock) where i.PMCo=@pmco and i.Project=@srcproject
    and not exists(select top 1 1 from bPMIM a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject and a.Issue=i.Issue)
	if @@Error <> 0 goto bspexit
    end


-- insert change order data if missing in destination project - only to appropiate level
if @chgheader = 'Y'
    begin
    -- insert pending CO headers
    insert into PMOP (PMCo, Project, PCOType, PCO, Description, Issue, Contract, PendingStatus,
            Date1, Date2, Date3, ApprovalDate, Notes, IntExt, PricingMethod)
    select @destpmco, @destproject, h.PCOType, h.PCO, h.Description,
            Issue = case when @issueyn='Y' then h.Issue else null end,
            @contract, h.PendingStatus, h.Date1, h.Date2, h.Date3, h.ApprovalDate, h.Notes, h.IntExt, h.PricingMethod
    from PMOP h with (nolock) where h.PMCo=@pmco and h.Project=@srcproject
    and not exists(select top 1 1 from PMOP a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
                    and a.PCOType=h.PCOType and a.PCO=h.PCO)
	if @@Error <> 0 goto bspexit

    -- insert approved CO headers
    insert into PMOH (PMCo, Project, ACO, Description, ACOSequence, Issue, Contract, ChangeDays,
            NewCmplDate, IntExt, DateSent, DateReqd, DateRecd, ApprovalDate, ApprovedBy, BillGroup, Notes)
    select @destpmco, @destproject, h.ACO, h.Description, h.ACOSequence,
            Issue = case when @issueyn='Y' then h.Issue else null end, @contract, h.ChangeDays,
            h.NewCmplDate, h.IntExt, h.DateSent, h.DateReqd, h.DateRecd, h.ApprovalDate, h.ApprovedBy, h.BillGroup, h.Notes
    from PMOH h with (nolock) where h.PMCo=@pmco and h.Project=@srcproject
    and not exists(select top 1 1 from PMOH a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject and a.ACO=h.ACO)
	if @@Error <> 0 goto bspexit

    -- insert change order items if missing in destination project
    if @chgitems = 'Y'
        begin
        insert into PMOI (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, Description, Status, ApprovedDate,
                UM, Units, UnitPrice, PendingAmount, ApprovedAmt, Issue, Date1, Date2, Date3, Contract, ContractItem,
                Approved, ApprovedBy, ForcePhaseYN, FixedAmountYN, FixedAmount, BillGroup, ChangeDays, Notes,
				ProjectCopy, BudgetNo)
        select @destpmco, @destproject, i.PCOType, i.PCO, i.PCOItem, i.ACO, i.ACOItem, i.Description, i.Status,
                i.ApprovedDate, i.UM,
                Units = case when @amountopt='1' then i.Units else 0 end,
                UnitPrice = case when @amountopt='1' then i.UnitPrice else 0 end,
                PendingAmount = case when @amountopt='1' then i.PendingAmount else 0 end,
                ApprovedAmt = case when @amountopt='1' then i.ApprovedAmt else 0 end,
                Issue = case when @issueyn='Y' then i.Issue else null end, i.Date1, i.Date2, i.Date3, @contract,
                i.ContractItem, i.Approved, i.ApprovedBy, i.ForcePhaseYN, i.FixedAmountYN, i.FixedAmount, i.BillGroup,
                i.ChangeDays, i.Notes, 'Y', BudgetNo = case when @projbudgetsyn='Y' then i.BudgetNo else null end
        from PMOI i with (nolock) where i.PMCo=@pmco and i.Project=@srcproject
        and not exists(select top 1 1 from PMOI a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
                and isnull(a.PCOType,'')=isnull(i.PCOType,'') and isnull(a.PCO,'')=isnull(i.PCO,'')
                and isnull(a.PCOItem,'')=isnull(i.PCOItem,'') and isnull(a.ACO,'')=isnull(i.ACO,'')
                and isnull(a.ACOItem,'')=isnull(i.ACOItem,''))
		if @@Error <> 0 goto bspexit

        -- insert change order detail if missing in destination project - only if phase groups match
        if @chgdetail = 'Y' and @phasegrpyn = 'Y'
            begin
			-- -- -- ALTER TABLE PMOL DISABLE TRIGGER ALL
            insert into PMOL (PMCo, Project, PCOType, PCO, PCOItem, ACO, ACOItem, PhaseGroup, Phase, CostType,
                    EstUnits, UM, UnitHours, EstHours, HourCost, UnitCost, ECM, EstCost, SendYN, Notes)
            select @destpmco, @destproject, l.PCOType, l.PCO, l.PCOItem, l.ACO, l.ACOItem, @phasegroup, l.Phase, l.CostType,
                    EstUnits = case when @amountopt='1' then isnull(l.EstUnits,0) else 0 end, l.UM,
                    UnitHours = case when @amountopt='1' then isnull(l.UnitHours,0) else 0 end,
                    EstHours = case when @amountopt='1' then isnull(l.EstHours,0) else 0 end,
                    HourCost = case when @amountopt='1' then isnull(l.HourCost,0) else 0 end,
                    UnitCost = case when @amountopt='1' then isnull(l.UnitCost,0) else 0 end, 'C',
                    EstCost = case when @amountopt='1' then isnull(l.EstCost,0) else 0 end, l.SendYN, l.Notes
            from PMOL l with (nolock) where l.PMCo=@pmco and l.Project=@srcproject
            and not exists(select top 1 1 from PMOL a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
                    and isnull(a.PCOType,'')=isnull(l.PCOType,'') and isnull(a.PCO,'')=isnull(l.PCO,'')
                    and isnull(a.PCOItem,'')=isnull(l.PCOItem,'') and isnull(a.ACO,'')=isnull(l.ACO,'')
                    and isnull(a.ACOItem,'')=isnull(l.ACOItem,'') and a.Phase=l.Phase and a.CostType=l.CostType)
			if @@Error <> 0	goto bspexit
			-- -- -- update copy flag
			update PMOL set ECM = 'E' where ECM = 'C'
			-- -- -- ALTER TABLE bPMOL ENABLE TRIGGER ALL
            end

        -- insert change order item addons if missing in destination project
        insert into PMOA (PMCo, Project, PCOType, PCO, PCOItem, AddOn, Basis, AddOnPercent, AddOnAmount,
					Status, TotalType, Include, NetCalcLevel, BasisCostType, PhaseGroup)
        select @destpmco, @destproject, i.PCOType, i.PCO, i.PCOItem, i.AddOn, i.Basis, i.AddOnPercent, i.AddOnAmount,
					'N', i.TotalType, i.Include, i.NetCalcLevel, i.BasisCostType, i.PhaseGroup
        from PMOA i with (nolock) where i.PMCo=@pmco and i.Project=@srcproject
        and not exists(select top 1 1 from PMOA a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
                and a.PCOType=i.PCOType and a.PCO=i.PCO and a.PCOItem=i.PCOItem and a.AddOn=i.AddOn)
		if @@Error <> 0 goto bspexit

        -- insert change order item markups if missing in destination project - only if phase groups match
        if @phasegrpyn = 'Y'
            begin
            insert into PMOM (PMCo, Project, PCOType, PCO, PCOItem, PhaseGroup, CostType, IntMarkUp, ConMarkUp)
            select @destpmco, @destproject, m.PCOType, m.PCO, m.PCOItem, @phasegroup, m.CostType, m.IntMarkUp, m.ConMarkUp
            from PMOM m with (nolock) where m.PMCo=@pmco and m.Project=@srcproject
            and not exists(select top 1 1 from PMOM a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
                    and a.PCOType=m.PCOType and a.PCO=m.PCO and a.PCOItem=m.PCOItem and a.CostType=m.CostType)
			if @@Error <> 0 goto bspexit
            end

		---- update Project Copy flag in PMOI
		update PMOI set ProjectCopy='N'
		where PMOI.PMCo=@destpmco and PMOI.Project=@destproject
        end
    end


-- insert Other documents into bPMOD if missing in destination project
if @otherdocyn = 'Y'
    begin
    insert into PMOD (PMCo, Project, DocType, Document, Description, Location, VendorGroup, RelatedFirm,
            Issue, Status, ResponsibleFirm, ResponsiblePerson, DateDue, DateRecd, DateSent, DateDueBack,
            DateRecdBack, DateRetd, Notes)
    select @destpmco, @destproject, d.DocType, d.Document, d.Description, d.Location, @vendorgroup,
            RelatedFirm = case when @vendgrpyn='Y' then d.RelatedFirm else null end,
            Issue = case when @issueyn='Y' then d.Issue else null end, d.Status,
            ResponsibleFirm = case when @vendgrpyn='Y' then d.ResponsibleFirm else null end,
            ResponsiblePerson = case when @vendgrpyn='Y' then d.ResponsiblePerson else null end,
            d.DateDue, d.DateRecd, d.DateSent, d.DateDueBack, d.DateRecdBack, d.DateRetd, d.Notes
    from PMOD d with (nolock) where d.PMCo=@pmco and d.Project=@srcproject
    and not exists(select top 1 1 from PMOD a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
                    and a.DocType=d.DocType and a.Document=d.Document)
	if @@Error <> 0 goto bspexit
    end


-- insert Submittal documents into bPMSM if missing in destination project
if @submittalyn = 'Y'
    begin
    insert into PMSM (PMCo, Project, Submittal, SubmittalType, Rev, Description, PhaseGroup, Phase, Issue,
			Status, VendorGroup, ResponsibleFirm, ResponsiblePerson, SubFirm, SubContact, ArchEngFirm,
            ArchEngContact, DateReqd, DateRecd, ToArchEng, DueBackArch, RecdBackArch, DateRetd, ActivityDate,
            CopiesRecd, CopiesSent, CopiesReqd, CopiesRecdArch, CopiesSentArch, Notes, SpecNumber)

    select @destpmco, @destproject, s.Submittal, s.SubmittalType, s.Rev, s.Description, @phasegroup,
            Phase = case when @phasegrpyn='Y' then s.Phase else null end,
            Issue = case when @issueyn='Y' then s.Issue else null end, s.Status, @vendorgroup,
            ResponsibleFirm = case when @vendgrpyn='Y' then s.ResponsibleFirm else null end,
            ResponsiblePerson = case when @vendgrpyn='Y' then s.ResponsiblePerson else null end,
            SubFirm = case when @vendgrpyn='Y' then s.SubFirm else null end,
            SubContact = case when @vendgrpyn='Y' then s.SubContact else null end,
            ArchEngFirm = case when @vendgrpyn='Y' then s.ArchEngFirm else null end,
            ArchEngContact = case when @vendgrpyn='Y' then s.ArchEngContact else null end,
			null, null, null, null, null, null, null, null, null, null, null, null, s.Notes, s.SpecNumber
    from PMSM s with (nolock) where s.PMCo=@pmco and s.Project=@srcproject
    and not exists(select top 1 1 from PMSM a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
                    and a.Submittal=s.Submittal and a.SubmittalType=s.SubmittalType and a.Rev=s.Rev)
	if @@Error <> 0 goto bspexit

    -- insert submittal items if missing in destination project
    if @submittalitemsyn = 'Y'
        begin
		-- bulk copy submittal items
        insert into PMSI (PMCo, Project, Submittal, SubmittalType, Rev, Item, Description, Status, Send,
				DateReqd, DateRecd, ToArchEng, DueBackArch, RecdBackArch, DateRetd, ActivityDate,
				CopiesRecd, CopiesSent, CopiesReqd, CopiesRecdArch, CopiesSentArch, Notes)
        select @destpmco, @destproject, i.Submittal, i.SubmittalType, i.Rev, i.Item, Description, i.Status, i.Send,
				null, null, null, null, null, null, null, null, null, null, null, null, i.Notes
				from PMSI i with (nolock) where i.PMCo=@pmco and i.Project=@srcproject
				and not exists(select top 1 1 from PMSI a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
						and a.Submittal=i.Submittal and a.Rev=i.Rev and a.Item=i.Item)
		if @@Error <> 0 goto bspexit
		end
    end


-- insert Drawing Logs(PMDG) and Revisions(PMDR) if missing in destination project
if @drawinglogsyn = 'Y'
    begin
	-- drawing logs
    insert into PMDG(PMCo, Project, DrawingType, Drawing, DateIssued, Status, Notes, Description)
    select @destpmco, @destproject, d.DrawingType, d.Drawing, d.DateIssued, d.Status, d.Notes, d.Description
    from PMDG d with (nolock) where d.PMCo=@pmco and d.Project=@srcproject
    and not exists(select top 1 1 from PMDG a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
                    and a.DrawingType=d.DrawingType and a.Drawing=d.Drawing)
	-- drawing log revisions
	insert into PMDR(PMCo, Project, DrawingType, Drawing, Rev, RevisionDate, Status, Notes, Description)
    select @destpmco, @destproject, d.DrawingType, d.Drawing, d.Rev, d.RevisionDate, d.Status, d.Notes, d.Description
    from PMDR d with (nolock) where d.PMCo=@pmco and d.Project=@srcproject
    and not exists(select top 1 1 from PMDR a with (nolock) where a.PMCo=@destpmco and a.Project=@destproject
                    and a.DrawingType=d.DrawingType and a.Drawing=d.Drawing and a.Rev=d.Rev)
	if @@Error <> 0 goto bspexit
    end


-- insert project budgets into PMEH/PMED if missing in destination project - only if phase groups match
if @phasegrpyn = 'Y' and @projbudgetsyn = 'Y'
    begin
	select @insert = null, @select = null
	if @pmehud_flag = 'Y'
		begin
		exec @rcode = dbo.bspPMProjectCopyUDBuild 'PMEH', 'b', @insert output, @select output, @msg output
		end

	select @sql = 'insert into PMEH (PMCo, Project, BudgetNo, Description, Notes'
	if isnull(@insert,'') <> '' select @sql = @sql + @insert
	select @sql = @sql + ') select ' + convert(varchar(3),@destpmco) + ', ' + CHAR(39) + @destproject + CHAR(39) + ', b.BudgetNo, b.Description, b.Notes'
	if isnull(@insert,'') <> '' select @sql = @sql + @select

	select @sql = @sql + ' from PMEH b where b.PMCo = ' + convert(varchar(3),@pmco) + ' and b.Project = ' + CHAR(39) + @srcproject + CHAR(39) +
			' and not exists(select BudgetNo from PMEH a where a.PMCo = ' + convert(varchar(3),@destpmco) + ' and a.Project = ' + CHAR(39) + @destproject + CHAR(39) +
			' and a.BudgetNo=b.BudgetNo)'

	exec (@sql)

	---- now insert budget detail (PMED)
	select @insert = null, @select = null
	if @pmedud_flag = 'Y'
		begin
		exec @rcode = dbo.bspPMProjectCopyUDBuild 'PMED', 'b', @insert output, @select output, @msg output
		end

	select @sql = 'insert into PMED (PMCo, Project, BudgetNo, Seq, CostLevel, GroupNo, Line, BudgetCode, Description, PhaseGroup, Phase, CostType, Units, UM, HrsPerUnit, Hours, HourCost, UnitCost, Markup, Amount, Notes'
	if isnull(@insert,'') <> '' select @sql = @sql + @insert
	select @sql = @sql + ') select ' + convert(varchar(3),@destpmco) + ', ' + CHAR(39) + @destproject + CHAR(39) + 
			', b.BudgetNo, b.Seq, b.CostLevel, b.GroupNo, b.Line, b.BudgetCode, b.Description, b.PhaseGroup, b.Phase, b.CostType, b.Units, b.UM, b.HrsPerUnit, b.Hours, b.HourCost, b.UnitCost, b.Markup, b.Amount, b.Notes '
	if isnull(@insert,'') <> '' select @sql = @sql + @select

	select @sql = @sql + ' from PMED b where b.PMCo = ' + convert(varchar(3),@pmco) + ' and b.Project = ' + CHAR(39) + @srcproject + CHAR(39) +
			' and not exists(select BudgetNo from PMED a where a.PMCo = ' + convert(varchar(3),@destpmco) + ' and a.Project = ' + CHAR(39) + @destproject + CHAR(39) +
			' and a.BudgetNo=b.BudgetNo)'

	exec (@sql)

    end


-- insert subcontract detail into bPMSL if missing in destination project - only if phase groups match
if @phasegrpyn = 'Y' and @subcontractyn = 'Y'
BEGIN
	---- ALTER TABLE bPMSL DISABLE TRIGGER ALL
    declare bcPMSL cursor LOCAL FAST_FORWARD for select Seq
    from PMSL where PMCo=@pmco and Project=@srcproject
		AND Phase IS NOT NULL -- TK-06471

    open bcPMSL
    select @openpmsl_cursor = 1

    PMSL_loop:

    fetch next from bcPMSL into @pmslseq

    if @@fetch_status <> 0 goto PMSL_end

    -- read subcontract data
    select @recordtype=RecordType, @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem, @aco=ACO, @acoitem=ACOItem,
           @phase=Phase, @costtype=CostType, @vendor=Vendor, @slitemtype=SLItemType, @units=Units, @um=UM,
           @unitcost=UnitCost, @amount=Amount, @subco=SubCO, @wcretgpct=WCRetgPct, @smretgpct=SMRetgPct,
           @supplier=Supplier, @sendflag=SendFlag
    from PMSL with (nolock) where PMCo=@pmco and Project=@srcproject and Seq=@pmslseq
		AND Phase IS NOT NULL -- TK-06471

    -- check if copying CO detail
    if @chgdetail = 'N' and @recordtype = 'C' goto PMSL_loop
    if @chgdetail = 'N' and (isnull(@pcotype,'') <> '' or isnull(@aco,'') <> '') goto PMSL_loop

    -- null out change order columns if not copying
    if @chgdetail = 'N'
        begin
        select @pcotype = null, @pco = null, @pcoitem = null, @aco = null, @acoitem = null, @subco = null
        end

    -- null out vendors if vendor groups don't match
    if @vendgrpyn = 'N'
        begin
        select @vendor = null, @supplier = null
        end

    -- set units, unitcost, amount depending on @amountopt flag
    if @amountopt = '0'
        begin
        select @units = 0, @unitcost = 0, @amount = 0
        end

    if @amountopt = '2' and @recordtype = 'C'
        begin
        select @units = 0, @unitcost = 0, @amount = 0
        end

    -- get next sequence number
    select @sequence=isnull(max(Seq),0)+1
    from PMSL with (nolock) where PMCo=@destpmco and Project=@destproject
		AND Phase IS NOT NULL -- TK-06471

    --insert into PMSL
    insert PMSL (PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem, Line, PhaseGroup,
            Phase, CostType, VendorGroup, Vendor, SLCo, SL, SLItem, SLItemDescription, SLItemType, SLAddon,
            SLAddonPct, Units, UM, UnitCost, Amount, SubCO, WCRetgPct, SMRetgPct, Supplier, InterfaceDate,
            SendFlag, SLMth, SLTrans, IntFlag, Notes)
    select  @destpmco, @destproject, @sequence, @recordtype, @pcotype, @pco, @pcoitem, @aco, @acoitem, null, @phasegroup,
			@phase, @costtype, @vendorgroup, @vendor, @apco, null, null, null, @slitemtype, null,
			null, @units, @um, @unitcost, @amount, @subco, @wcretgpct, @smretgpct, @supplier, null, @sendflag, 
			null, null, null, Notes 
	from PMSL with (nolock) where PMCo=@pmco and Project=@srcproject and Seq=@pmslseq
		AND Phase IS NOT NULL -- TK-06471
		
	if @@rowcount = 0 goto bspexit

    goto PMSL_loop


    PMSL_end:
        if @openpmsl_cursor = 1
            begin
      	    close bcPMSL
      	    deallocate bcPMSL
 	        select @openpmsl_cursor = 0
            end
	---- ALTER TABLE bPMSL ENABLE TRIGGER ALL
END


-- insert material detail into bPMMF if missing in destination project - only if phase groups match
if @phasegrpyn = 'Y' and @materialyn = 'Y'
BEGIN
	---- ALTER TABLE bPMMF DISABLE TRIGGER ALL
    declare bcPMMF cursor LOCAL FAST_FORWARD for select Seq
    from PMMF with (nolock) where PMCo=@pmco and Project=@srcproject
		AND Phase IS NOT NULL -- TK-06471

    open bcPMMF
    select @openpmmf_cursor = 1

    PMMF_loop:

    fetch next from bcPMMF into @pmmfseq

    if @@fetch_status <> 0 goto PMMF_end

    -- read material data
    select @recordtype=RecordType, @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem, @aco=ACO, @acoitem=ACOItem,
           @materialcode=MaterialCode, @mtldescription=MtlDescription, @phase=Phase,
           @costtype=CostType, @materialoption=MaterialOption, @vendor=Vendor, @recvyn=RecvYN, @um=UM, @units=Units,
           @unitcost=UnitCost, @ecm=ECM, @amount=Amount, @reqdate=ReqDate, @taxcode=TaxCode, @taxtype=TaxType,
           @sendflag=SendFlag, @requisitionnum=RequisitionNum, @supplier=Supplier
    from PMMF with (nolock) where PMCo=@pmco and Project=@srcproject and Seq=@pmmfseq
			AND Phase IS NOT NULL -- TK-06471

    -- check if copying CO detail
    if @chgdetail = 'N' and @recordtype = 'C' goto PMMF_loop
    if @chgdetail = 'N' and (isnull(@pcotype,'') <> '' or isnull(@aco,'') <> '') goto PMMF_loop

    -- null out change order columns if not copying
    if @chgdetail = 'N'
        begin
        select @pcotype = null, @pco = null, @pcoitem = null, @aco = null, @acoitem = null
        end

    -- null out vendor if vendor groups don't match

    if @vendgrpyn = 'N'
        begin
        select @vendor = null, @vendmatid = null
        end

    -- null out material if material groups don't match
    if @matlgrpyn = 'N' select @materialcode = null

    -- null out tax code if tax groups don't match
    if @taxgrpyn = 'N' select @taxcode = null

    -- set units, unitcost, amount depending on @amountopt flag
    if @amountopt = '0'
        begin
        select @units = 0, @unitcost = 0, @amount = 0

        end

    if @amountopt = '2' and @recordtype = 'C'
        begin
        select @units = 0, @unitcost = 0, @amount = 0
        end

    -- get next sequence number
    select @sequence=isnull(max(Seq),0)+1
    from PMMF with (nolock) where PMCo=@destpmco and Project=@destproject

    --insert into PMMF
    insert PMMF (PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem, MaterialGroup,
            MaterialCode, MtlDescription, PhaseGroup, Phase, CostType, MaterialOption, VendorGroup,
            Vendor, POCo, PO, POItem, RecvYN, Location, MO, MOItem, UM, Units, UnitCost, ECM, Amount, ReqDate,
            InterfaceDate, TaxGroup, TaxCode, TaxType, SendFlag, RequisitionNum, MSCo, Quote, INCo, RQLine, Notes, Supplier)
    select @destpmco, @destproject, @sequence, @recordtype, @pcotype, @pco, @pcoitem, @aco, @acoitem, @matlgroup,
            @materialcode, @mtldescription, @phasegroup, @phase, @costtype, @materialoption, @vendorgroup,
            @vendor, @apco, null, null, @recvyn, null, null, null, @um, @units, @unitcost, @ecm, @amount, @reqdate,
            null, @taxgroup, @taxcode, @taxtype, @sendflag, @requisitionnum, null, null, null, null,
            Notes, @supplier 
    from PMMF with (nolock) where PMCo=@pmco and Project=@srcproject and Seq=@pmmfseq
		AND Phase IS NOT NULL -- TK-06471
            
	if @@rowcount = 0 goto bspexit

    goto PMMF_loop

    PMMF_end:
        if @openpmmf_cursor = 1
            begin
          	close bcPMMF
          	deallocate bcPMMF
          	select @openpmmf_cursor = 0
            end
	---- ALTER TABLE bPMMF ENABLE TRIGGER ALL
END

--Issue 135571
if @copyjobreviewers = 'Y'
begin
	insert into dbo.bJCJR (JCCo, Job, Seq, Reviewer, Memo, ReviewerType)
	select @destpmco, @destproject, j.Seq, j.Reviewer, j.Memo, j.ReviewerType 
	from dbo.bJCJR j with (nolock)	
	where j.JCCo=@pmco and j.Job=@srcproject 
		and not exists(select top 1 1 from dbo.bJCJR r with (nolock) where r.JCCo=@destpmco and r.Job=@destproject and r.Reviewer=j.Reviewer)
end

--Issue 135527
if @CopyJobRoles = 'Y'
begin	
	----TK-13879
	insert dbo.vJCJobRoles(JCCo, Job, VPUserName, Role, Notes, Lead, Active)
	select @destpmco, @destproject, VPUserName, Role, Notes, Lead, Active
		from dbo.vJCJobRoles with (nolock) where JCCo=@pmco and Job=@srcproject
end	
	
if @CopyJobPhaseRoles = 'Y'
begin		
	insert dbo.vJCJPRoles(JCCo, Job, PhaseGroup, Phase, Process, Role, Notes)
	select @destpmco, @destproject, r.PhaseGroup, r.Phase, r.Process, r.Role, r.Notes
		from dbo.vJCJPRoles r with (nolock) where r.JCCo=@pmco and r.Job=@srcproject
		and exists(select top 1 1 from dbo.JCJP p where p.JCCo=@destpmco and p.Job=@destproject and r.PhaseGroup=p.PhaseGroup and r.Phase=p.Phase) 
end


-------- Setup default security group to have access if securing bJob
----select @jobsecure = Secure, @jobdefaultsecurity = DfltSecurityGroup
----from dbo.DDDTShared with (nolock) where Datatype = 'bJob'
----If @@rowcount = 1 and @jobsecure <> 'N'
----	begin
----	---- if no security group entry exists then set to default
----	if not exists (select top 1 1 from dbo.vDDDS with (nolock) where Datatype = 'bJob'
----				and Qualifier = @destpmco and Instance = @destproject)
----		begin
----		if @jobdefaultsecurity is not null
----			begin
----			Insert vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
----			values ('bJob', @destpmco, @destproject, @jobdefaultsecurity)
----			end
----		end
----	end
----
-------- Setup default security group to have access if securing bContract
----select @contractsecure = Secure, @contractdefaultsecurity = DfltSecurityGroup
----from dbo.DDDTShared with (nolock) where Datatype = 'bContract'
----If @@rowcount = 1 and @contractsecure <> 'N'
----	begin
----	---- if no security group entry exists then set to default
----	if not exists (select top 1 1 from dbo.vDDDS with (nolock) where Datatype = 'bContract' 
----			and Qualifier = @destpmco and Instance = @contract)
----		begin
----		if @contractdefaultsecurity is not null
----			begin
----			Insert vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
----			values ('bContract', @destpmco, @contract, @contractdefaultsecurity)
----			end
----		end
----	end



commit transaction




bspexit:
	if @@trancount > 0
		begin
		rollback transaction
		end

    if @openpmpf_cursor = 1
        begin
      	close bcPMPF
    	deallocate bcPMPF
      	select @openpmpf_cursor = 0
        end

    if @openpmsl_cursor = 1
        begin
      	close bcPMSL
    	deallocate bcPMSL
      	select @openpmsl_cursor = 0
        end

    if @openpmmf_cursor = 1
        begin
      	close bcPMMF
      	deallocate bcPMMF
      	select @openpmmf_cursor = 0
        end

	-- -- -- ALTER TABLE bPMOL ENABLE TRIGGER ALL
	-- -- -- ALTER TABLE bPMMF ENABLE TRIGGER ALL
	-- -- -- ALTER TABLE bPMSL ENABLE TRIGGER ALL
	return @rcode






GO
GRANT EXECUTE ON  [dbo].[bspPMProjectCopy] TO [public]
GO
