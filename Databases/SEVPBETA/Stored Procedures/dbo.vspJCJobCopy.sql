SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************************************/
CREATE proc [dbo].[vspJCJobCopy]
/*******************************************************************************
* Created By:  TV 05/31/2001
* Modified By: DANF 12/03/2001  - Added update of Security to DDDS for bContract.
*				DANF 02/22/2002 - Corrected copy of Job phase Contract Item.
*				GF 09/06/2002 - issue #18387 - added Start Month to JCCI, copy from source.
*				TV 08/15/03 - 22125 Passing in Start Month for JCCM
*				TV 12/3/03 - 22903 fixing Standard items (where'd my code go??)
*				TV 2/4/04 - 23178 Input Department used in JCCI		
*				TV 2/8/04 -23679 input TaxCode into JCCM and JCCI
*				GWC 03/10/2004 - 23735 Adding a default contract item on Job copy error fix
*				DANF 03/19/04 - 20980 Expand SecurityGroup.
*				TV - 23061 added isnulls
*				GF 05/11/2004 - issue #24513 copy user memos for JCCM, JCCI, JCJM, JCJP, JCCH, JCOH, JCOI, JCOD
*				GF 06/22/2004 - issue #24879 customer group incorrect for destination JCCO inserted into JCCM.
*				GF 09/09/2004 - issue #25521 the flag to copy original estimates @origestim was reversed. S/B 'N' then zero.
*				DANF 08/08/2005 - 6.X
*				DANF 02/19/07 - issue #123034 Add Rate template to Job Copy
*				GF 01/03/2008 - issue #120218 dropped unused columns.
*				MV 12/19/2007 - issue #29702 Unapproved Enhancement - add RevGrpInv to JCJM inserts
*				CHS	1/15/08	-	issue #121678 Copy lock phases data from source to destination job
*				GF 03/11/2008 - issue #127076 JCCM and JCJM country columns added.
*				CHS	06/26/2008	-	issue #126233, #122767 - copy department and bill group info
*				GF 03/25/2009 - issue #132875 fix related to 126233 to verify if item exists in JCCI before insert
*				GF 04/20/2009 - issue #132326 JCCI start month cannot be null
*				GP 05/12/2009 - Issue 132805 added UseTaxYN to JCJM insert.
*				DAN SO 07/14/2009 - Issue #133648 - Copy Item Retainage
*				GP 10/06/2009 - Issue 135571 added copy for Job Reviewers
*				GF 11/07/2009 - issue #136483 expanded job/contract descriptions to 60.
*				TJL 12/03/09 - Issue #129894, add fields MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN to be copied
*				GP 01/15/2010 - Issue 135527 added copy for Job Roles and Job Phase Roles
*				GF 04/11/2010 - issue #139029
*				GF 03/04/2011 - issue #143523 added JCJP.InsCode to insert for JCJP.
*				GF 05/15/2012 TK-13879 copy new columns for JC Job Roles
*
*
* This SP will copy a source project into a destination project within PM.
*
*
* It Returns either STDBTK_SUCCESS or STDBTK_ERROR and a msg in @msg
*
* Pass In
* jcco				JC Company
* srcjob			source JC Job
* destpmco			Destination JCompany
* destjob			Destination JCJob
* jobdesc   		Destination Job description
* LiabTemplate		JC Liability template
* Contract			Contract
* contractdesc		Contract description
* department		Department for contract
* Customer			Customer for contract
* RetainPCT			Retainage percentage for contract
* subcontractyn		Copy subcontract detail flag
* changeorders		Copy Change order flag
* costtype			Copy CostType flag
* phases			Copy Phases flag
* origestim			Copy Original Estimates andContracts flag
* username			User name
* CopyItemRetainage Copy Item Retainage
* pr state			Payroll State
*
* RETURN PARAMS
*   msg           Error Message, or Success message
*
* Returns
*      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
*
********************************************************************************/
  (@jcco bCompany = Null, @srcjob bJob = Null, @destjcco bCompany = null, @destjob bJob = Null,
   @jobdesc bItemDesc = Null, @liabtemplate smallint = null, @contract bContract = null,
   @contractdesc bItemDesc = Null, @department bDept = Null, @customer bCustomer = null, @jccmretpct bPct,
   @subcontractyn bYN = 'N', @changeorders bYN = 'N', @phases bYN = 'N', @origestim bYN = 'N', 
   @username varchar(15) = Null, @startmonth bMonth, @taxcode bTaxCode, @prstate varchar(4) = null,
   @copyitemdept bYN = 'N', @copyitembillgroup bYN = 'N', @CopyItemRetainage bYN = 'N',
   @CopyJobReviewers bYN = 'N', @CopyJobRoles bYN = 'N', @CopyJobPhaseRoles bYN = 'N', @msg varchar(255) output)
as
set nocount on

	declare @rcode int, @sequence int, @validcnt int, @openjcsl_cursor tinyint, @openpmmf_cursor tinyint,
			@jcslseq int, @pmmfseq int, @jobsecure bYN, @contractsecure bYN,
			@contractdefaultsecurity smallint, @jobdefaultsecurity smallint
    
    declare @xphasegroup bGroup, @xtaxgroup bGroup, @phasegroup bGroup, @taxgroup bGroup, @vendorgroup bGroup,
            @xprco bCompany, @arco bCompany, @prco bCompany, @phasegrpyn bYN, @taxgrpyn bYN,
            @srccontract bContract, @contractstatus tinyint, @xvendorgroup bGroup, @vendgrpyn bYN,
			@xcustgroup bGroup, @custgroup bGroup, @custgrpyn bYN
    
    --Change Orders
   declare	@recordtype char(1), @pcotype bDocType, @pco bPCO, @pcoitem bPCOItem, @aco bACO, @acoitem bACOItem,
            @phase bPhase,  @vendor bVendor, @slitemtype tinyint, @units bUnits, @um bUM,
            @unitcost bUnitCost, @amount bDollar, @subco smallint, @wcretgpct bPct, @smretgpct bPct,
            @supplier bVendor, @sendflag bYN,@jccoyn bYN,@prcoyn bYN
   
   declare	@jcciud_flag bYN, @jcjpud_flag bYN, @jcchud_flag bYN, @jccmud_flag bYN, @jcjmud_flag bYN, @jcohud_flag bYN,
   			@jcoiud_flag bYN, @jcodud_flag bYN, @insert varchar(1000), @select varchar(1000), @sql varchar(max),
   			@joins varchar(1000), @where varchar(1000)
    
    
   select	@rcode = 0, @phasegrpyn = 'Y', @taxgrpyn = 'Y',@jccoyn = 'Y',@prcoyn = 'Y', @vendgrpyn ='Y', @custgrpyn = 'Y',
   			@jcciud_flag = 'N', @jcjpud_flag = 'N', @jcchud_flag = 'N', @jccmud_flag = 'N', @jcjmud_flag = 'N',
   			@jcohud_flag = 'N', @jcoiud_flag = 'N', @jcodud_flag = 'N'
   
   
    if @jcco is null
        begin
        select @msg = 'Missing JC company', @rcode = 1
        goto bspexit
        end
    
    if @srcjob is null
        begin
        select @msg = 'Missing Source Job', @rcode = 1
        goto bspexit
        end
    
    if @destjcco is null
        begin
        select @msg = 'Missing Destination JC company', @rcode = 1
        goto bspexit
        end
    
    if @destjob is null
        begin
        select @msg = 'Missing Destination Job', @rcode = 1
        goto bspexit
        end

    if @contract is null
        begin
        select @msg = 'Missing Destination Contract', @rcode = 1
        goto bspexit
        end

	---- issue #126233    
    if @department is null and @copyitemdept <> 'Y'
        begin
        select @msg = 'Missing contract department', @rcode = 1
        goto bspexit
        end
    
    -- validate source project
    select @srccontract=Contract from dbo.bJCJM with (nolock) where JCCo=@jcco and Job=@srcjob
    if @@rowcount = 0
        begin
        select @msg = 'Invalid source Job - ' + isnull(@srcjob,'') + ' not found in JCJM.', @rcode = 1
        goto bspexit
        end
    
    -- verify destination project not in JCJM
    select @validcnt=count(*) from dbo.bJCJM with (nolock) where JCCo=@destjcco and Job=@destjob
    if @validcnt <> 0
        begin
        select @msg = 'Invalid destination job - ' + isnull(@destjob,'') + ' must not be in JCJM.', @rcode = 1
        goto bspexit
        end  
   
   
   -- load groups from HQCO for source PMCO
   select @xcustgroup=h.CustGroup
   from dbo.bHQCO h with (nolock) 
   JOIN dbo.bJCCO j with (nolock) 
   ON (h.HQCo = j.ARCo)
   where j.JCCo = @jcco
   if @@rowcount <> 1
       begin
       select @msg='Invalid HQ source company ' + convert(varchar(3),@jcco) + ' !', @rcode=1
       goto bspexit
       end
   
    select @xphasegroup=PhaseGroup, @xtaxgroup=TaxGroup, @vendorgroup = VendorGroup
    from dbo.bHQCO with (nolock) where HQCo=@jcco
    if @@rowcount = 0
        begin
        select @msg = 'Invalid HQ source company ' + isnull(convert(varchar(3),@jcco),'') + '!', @rcode = 1
        goto bspexit
        end
    
    
    -- load source vendor group - use APCo from PMCo
    select @arco=ARCo, @xprco=PRCo from dbo.bJCCO with (nolock) where JCCo=@jcco
    if @@rowcount = 0
        begin
        select @msg = 'Invalid AP source company ' + isnull(convert(varchar(3),@arco),'') + ' in JCCO - unable to load vendor group', @rcode = 1
        goto bspexit
        end
    
    select @xvendorgroup=VendorGroup from dbo.bHQCO with (nolock) where HQCo=@arco
    if @@rowcount = 0
        begin
        select @msg = 'Invalid HQ source company ' + isnull(convert(varchar(3),@jcco),'') + '!', @rcode =1
        goto bspexit
        end
    
    
    -- load groups from HQCO for destination PMCO - only if @pmco<>@destpmco
    if @jcco = @destjcco
        begin
			select @phasegroup=@xphasegroup, @taxgroup=@xtaxgroup, @prco=@xprco, @custgroup=@xcustgroup
        end

    else
        begin
   			select @custgroup=h.CustGroup
   			from bHQCO h with (nolock) 
			JOIN bJCCO j with (nolock) 
			ON (h.HQCo = j.ARCo)
   			where j.JCCo = @destjcco
   			if @@rowcount <> 1
   				begin
   					select @msg='Invalid destination Company ' + convert(varchar(3),@destjcco) + ' !', @rcode=1
   					goto bspexit
   				end
		   
			select @phasegroup=PhaseGroup, @taxgroup=TaxGroup
			from dbo.bHQCO with (nolock) where HQCo=@destjcco
			if @@rowcount = 0
				begin
					select @msg='Invalid HQ destination company ' + isnull(convert(varchar(3),@destjcco),'') + '!', @rcode=1
					goto bspexit
				end
    end

    -- load destination vendor group - use APCo from PMCo
    select @arco=ARCo, @prco=PRCo from dbo.bJCCO with (nolock) where JCCo=@destjcco
    if @@rowcount = 0
        begin
			select @msg = 'Invalid AP destination company ' + isnull(convert(varchar(3),@arco),'') + ' in JCCO - unable to load vendor group', @rcode = 1
			goto bspexit
        end
    
    
    -- set group flags to track whether the groups are consistent between source and destination
   if @xphasegroup <> @phasegroup select @phasegrpyn = 'N'
   if @xtaxgroup <> @taxgroup select @taxgrpyn = 'N'
   if @xprco <> @prco select @prcoyn = 'N'
   if @jcco <> @destjcco select @jccoyn = 'N'
   if @xvendorgroup <> @vendorgroup select @vendgrpyn = 'N'
   if @xcustgroup <> @custgroup select @custgrpyn = 'N'
   
   
  -- set the user memo flags for the tables that have user memos
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bJCCI'))
  	select @jcciud_flag = 'Y'
  
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bJCJP'))
  	select @jcjpud_flag = 'Y'
  
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bJCCH'))
  	select @jcchud_flag = 'Y'
  
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bJCCM'))
  	select @jccmud_flag = 'Y'
  
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bJCJM'))
  	select @jcjmud_flag = 'Y'
  
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bJCOH'))
  	select @jcohud_flag = 'Y'
  
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bJCOI'))
  	select @jcoiud_flag = 'Y'
  
  if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bJCOD'))
  	select @jcodud_flag = 'Y'


    
    -- insert contract into bJCCM if does not exists, else check status
    select @contractstatus = ContractStatus
    from dbo.bJCCM with (nolock) where JCCo=@destjcco and Contract=@contract
    if @@rowcount = 0
        begin
			select @contractstatus = 1
			insert into dbo.bJCCM (JCCo, Contract, Description, Department, ContractStatus, OriginalDays, CurrentDays, StartMonth,
					CustGroup, Customer, PayTerms, TaxInterface, TaxGroup, TaxCode, RetainagePCT, DefaultBillType,
					OrigContractAmt, ContractAmt, BilledAmt, ReceivedAmt, CurrentRetainAmt, SIRegion, SIMetric,
					ProcessGroup, BillAddress, BillAddress2, BillCity, BillState, BillZip, BillOnCompletionYN,
					CustomerReference, CompleteYN, RoundOpt, ReportRetgItemYN, ProgressFormat, TMFormat, BillGroup,
					BillDayOfMth, ArchitectName, ArchitectProject, ContractForDesc, StartDate, JBTemplate,
					JBFlatBillingAmt, JBLimitOpt, Notes, BillNotes, RecType, ClosePurgeFlag, MiscDistCode,
					SecurityGroup, UpdateJCCI, BillCountry, MaxRetgOpt, MaxRetgPct, MaxRetgAmt, InclACOinMaxYN, MaxRetgDistStyle)

			select @destjcco, @contract, @contractdesc, @department, @contractstatus, 0, 0, @startmonth,
					@custgroup, @customer, c.PayTerms, c.TaxInterface, @taxgroup,
					@taxcode, @jccmretpct, c.DefaultBillType,
					0, 0, 0, 0, 0, c.SIRegion, c.SIMetric,
					c.ProcessGroup, c.BillAddress, c.BillAddress2, c.BillCity, c.BillState, c.BillZip, c.BillOnCompletionYN,
					null, 'N', c.RoundOpt, c.ReportRetgItemYN, c.ProgressFormat, c.TMFormat, c.BillGroup,
					c.BillDayOfMth, c.ArchitectName, c.ArchitectProject, c.ContractForDesc, c.StartDate, c.JBTemplate,
					c.JBFlatBillingAmt, c.JBLimitOpt, c.Notes, c.BillNotes, c.RecType, 'N', c.MiscDistCode,
					c.SecurityGroup, 'N', c.BillCountry, c.MaxRetgOpt, c.MaxRetgPct, c.MaxRetgAmt, c.InclACOinMaxYN, c.MaxRetgDistStyle
			from dbo.bJCCM c where c.JCCo=@jcco and c.Contract=@srccontract
   			if @@rowcount <> 0 and @jccmud_flag = 'Y'
   				begin
   					-- build joins and where clause
   					select @joins = ' from JCCM join JCCM z on z.JCCo = ' + convert(varchar(3),@jcco) + ' and z.Contract = ' + CHAR(39) + @srccontract + CHAR(39)
   					select @where = ' where JCCM.JCCo = ' + convert(varchar(3),@destjcco) + ' and JCCM.Contract = ' + CHAR(39) + @contract + CHAR(39)
   					-- execute user memo update
   					exec @rcode = dbo.bspPMProjectCopyUserMemos 'JCCM', @joins, @where, @msg output
   				end

			-- copy bill groups  CHS 06/26/2008 - issue #126233, #122767
			if @copyitembillgroup = 'Y'
				begin
					insert into bJBBG(JBCo, Contract, BillGroup, Description, Notes)
					select @destjcco, @contract, g.BillGroup, g.Description, g.Notes
					from bJBBG g
					where g.JBCo = @jcco and g.Contract = @srccontract 
						and not exists(select top 1 1 from bJBBG bg where bg.JBCo = @destjcco and bg.Contract = @contract)
				end	
		
        end
    else
        begin
        -- check for valid contract status
        If isnull(@contractstatus,0) > 1
            begin
            select @msg = 'Invalid contract status for contract - ' + isnull(@contract,'') + ' - must be pending or open.', @rcode = 1
            goto bspexit
            end
        end
   

    -- insert contract items if missing in destination contract
    if  @subcontractyn = 'Y'
    	begin
   			-- insert contract items if missing in destination contract
   			select @insert = null, @select = null
   			select @department=Department from dbo.bJCCM with (nolock) where JCCo=@destjcco and Contract=@contract
   			if @jcciud_flag = 'Y'
   				begin
   				exec @rcode = dbo.bspPMProjectCopyUDBuild 'JCCI', 'i', @insert output, @select output, @msg output
   				end
		  
		   	select @sql = 'insert into JCCI (JCCo, Contract, Item, Description, Department, TaxGroup, TaxCode, UM, SIRegion, SICode, ' +
			'RetainPCT, OrigContractAmt, OrigContractUnits, OrigUnitPrice, ContractAmt, ContractUnits, UnitPrice, ' +
			'BilledAmt, BilledUnits, ReceivedAmt, CurrentRetainAmt, BillType, BillGroup, BillDescription, ' +
			'BillOriginalUnits, BillOriginalAmt, BillCurrentUnits, BillCurrentAmt, BillUnitPrice, InitSubs, MarkUpRate, ' +
			'Notes, ProjPlug, StartMonth'
		   
   			if isnull(@insert,'') <> '' select @sql = @sql + @insert
		   
   			select @sql = @sql + ') select ' + convert(varchar(3),@destjcco) + ', ' + CHAR(39) + @contract + CHAR(39) + ', i.Item, i.Description, '

			if @copyitemdept = 'Y' select @sql = @sql + 'i.Department'
			else select @sql = @sql + CHAR(39) + @department + CHAR(39) 


   			select @sql = @sql + ', ' + convert(varchar(3),@taxgroup) + ', '

			-- **************** --
			-- #133648 -- START --
			-- **************** --   			
   			if @taxcode is null
   				select @sql = @sql + 'null, ' + ' i.UM, i.SIRegion, i.SICode, ' 
   			else
   				select @sql = @sql + CHAR(39) + @taxcode + CHAR(39) + ', i.UM, i.SIRegion, i.SICode, ' 
   				
   			
   			select @sql = @sql + 'RetainPCT = case when ' + CHAR(39) + @CopyItemRetainage + CHAR(39) + ' = ' + CHAR(39) + 'Y' + CHAR(39) + ' then i.RetainPCT else ' + convert(varchar,@jccmretpct) + ' end, ' 
			-- ************** --
			-- #133648 -- END --	
			-- ************** --
		   
   			select @sql = @sql + 'OrigContractAmt = case when ' + CHAR(39) + @origestim + CHAR(39) + ' = ' + CHAR(39) + 'N' + CHAR(39) + ' then 0 else i.OrigContractAmt end, ' +
   				'OrigContractUnits = case when ' + CHAR(39) + @origestim + CHAR(39) + ' = ' + CHAR(39) + 'N' + CHAR(39) + ' then 0 else i.OrigContractUnits end, ' +
   				'OrigUnitPrice = case when ' + CHAR(39) + @origestim + CHAR(39) + ' = ' + CHAR(39) + 'N' + CHAR(39) + ' then 0 else i.OrigUnitPrice end, ' +
   				'0, 0, 0, 0, 0, 0, 0, i.BillType, i.BillGroup, i.BillDescription, 0, 0, 0, 0, 0, i.InitSubs, i.MarkUpRate, i.Notes, ' +
   				'i.ProjPlug, ' + CHAR(39) + convert(varchar(30),@startmonth) + CHAR(39)
		   
		   
   			if isnull(@insert,'') <> '' select @sql = @sql + @select
		   
   			select @sql = @sql + ' from JCCI i where i.JCCo = ' + convert(varchar(3),@jcco) + ' and i.Contract = ' + CHAR(39) + @srccontract + CHAR(39) +
   				' and not exists(select Item from JCCI a where a.JCCo = ' + convert(varchar(3),@destjcco) + ' and a.Contract = ' + CHAR(39) + @contract + CHAR(39) +
   				' and a.Item=i.Item)'

   		exec (@sql) 
	   
   	end
   
   else
   
    	--If SubContracts are not being copied 1 Item needs to be generated
    	begin
		if not exists ( select top 1 1 from bJCCI where JCCo = @destjcco and Contract = @contract)
			begin
    			declare @contractitem bContractItem, @itemformat varchar(10), @itemmask varchar(10),
   				@ditem bContractItem, @itemlength varchar(10), @inputmask varchar(30)
	    
   				-- get input mask for bContractItem
   				select @inputmask = InputMask, @itemlength = convert(varchar(10), InputLength)
   				from dbo.DDDTShared with (nolock) where Datatype = 'bContractItem'
   				if isnull(@inputmask,'') = '' select @inputmask = 'R'
   	   			if isnull(@itemlength,'') = '' select @itemlength = '16'
   	    		if @inputmask in ('R','L')
   					begin
   					select @inputmask = @itemlength + @inputmask + 'N'
   					end
	    
    			select @ditem = '1'
    			exec dbo.bspHQFormatMultiPart @ditem, @inputmask, @contractitem output

				-- issue #126233	    
--				insert into bJCCI (JCCo, Contract, Item, Description, Department, TaxGroup, TaxCode, UM, RetainPCT, BillType)
--				values (@destjcco, @contract, @contractitem, @contractdesc, @department, @taxgroup, null, 'LS', @jccmretpct, null)

				-- #133648 - added StartMonth (can not be NULL)
				insert into bJCCI (JCCo, Contract, Item, Description, Department, TaxGroup,
						TaxCode, UM, RetainPCT, OrigContractAmt, OrigContractUnits, OrigUnitPrice, BillType, StartMonth)
				select @destjcco, @contract, @contractitem, @contractdesc, bJCCM.Department, bJCCM.TaxGroup, 
						bJCCM.TaxCode,'LS', bJCCM.RetainagePCT, 0, 0, 0,bJCCM.DefaultBillType, StartMonth
				from bJCCM with (nolock) where JCCo=@destjcco and Contract=@contract
				and not exists(select 1 from bJCCI where JCCo=@destjcco and Contract=@contract and Item=@contractitem)

			end
    	end
    

    -- insert destination job into bJCJM
    insert into dbo.bJCJM (JCCo, Job, Description, Contract, JobStatus, BidNumber, LockPhases, ProjectMgr, JobPhone, JobFax,
   		MailAddress, MailCity, MailState, MailZip, MailAddress2, ShipAddress, ShipCity, ShipState, ShipZip, ShipAddress2,
   		LiabTemplate, TaxGroup, TaxCode, InsTemplate, MarkUpDiscRate,  PRLocalCode, PRStateCode, Certified,
   		EEORegion, SMSACode, CraftTemplate, ProjMinPct, SLCompGroup, POCompGroup, VendorGroup,
    	OTSched, PriceTemplate, HaulTaxOpt, GeoCode, BaseTaxOn, Notes, UpdatePlugs, ContactCode, ClosePurgeFlag,
   		ArchEngFirm, OurFirm, AutoAddItemYN, WghtAvgOT, HrsPerManDay, AutoGenSubNo, SecurityGroup, RateTemplate,
		RevGrpInv, MailCountry, ShipCountry, UseTaxYN)
    select 	@destjcco, @destjob, @jobdesc, @contract, @contractstatus, j.BidNumber, j.LockPhases,
           	ProjectMgr = case when @jccoyn='Y' then j.ProjectMgr else null end, j.JobPhone, j.JobFax,
           	j.MailAddress, j.MailCity, j.MailState, j.MailZip, j.MailAddress2, j.ShipAddress, j.ShipCity, j.ShipState,
           	j.ShipZip, j.ShipAddress2, @liabtemplate, @taxgroup,
           	TaxCode = case when @taxgrpyn='Y' then j.TaxCode else null end,
           	InsTemplate = case when @jccoyn='Y' then j.InsTemplate else null end, j.MarkUpDiscRate,
           	PRLocalCode = case when @prcoyn='Y' then j.PRLocalCode else null end,
           	@prstate, j.Certified,
           	EEORegion = case when @prcoyn='Y' then j.EEORegion else null end,
           	SMSACode = case when @prcoyn='Y' then j.SMSACode else null end,
           	CraftTemplate = case when @prcoyn='Y' then j.CraftTemplate else null end,
    	    j.ProjMinPct,
            SLCompGroup = case when @vendgrpyn='Y' then j.SLCompGroup else null end,
            POCompGroup = case when @vendgrpyn='Y' then j.POCompGroup else null end, @vendorgroup, 
           	OTSched = case when @prcoyn='Y' then j.OTSched else null end, j.PriceTemplate, j.HaulTaxOpt,
           	GeoCode = case when @prcoyn='Y' then j.GeoCode else null end, j.BaseTaxOn, j.Notes,
   		j.UpdatePlugs, j.ContactCode, 'N', 
   		ArchEngFirm = case when @vendgrpyn='Y' then j.ArchEngFirm else null end,
   		OurFirm = case when @vendgrpyn='Y' then j.OurFirm else null end,
   		j.AutoAddItemYN, j.WghtAvgOT, j.HrsPerManDay, j.AutoGenSubNo, j.SecurityGroup, j.RateTemplate,
		j.RevGrpInv, j.MailCountry, j.ShipCountry, j.UseTaxYN
   from dbo.bJCJM j where j.JCCo=@jcco and j.Job=@srcjob
   if @@rowcount <> 0 and @jcjmud_flag = 'Y'
   	begin
	-- build joins and where clause
	select @joins = ' from JCJM join JCJM z on z.JCCo = ' + convert(varchar(3),@jcco) + ' and z.Job = ' + CHAR(39) + @srcjob + CHAR(39)
	select @where = ' where JCJM.JCCo = ' + convert(varchar(3),@destjcco) + ' and JCJM.Job = ' + CHAR(39) + @destjob + CHAR(39)
	-- execute user memo update
	exec @rcode = dbo.bspPMProjectCopyUserMemos 'JCJM', @joins, @where, @msg output
   	end
    
   
    
   --  -- insert phases into bJCJP if missing in destination project - only if phase groups match
    if @phasegrpyn = 'Y' and @phases = 'Y'
        begin
   
   	select @insert = null, @select = null
   	if @jcjpud_flag = 'Y'
   		begin
   		exec @rcode = dbo.bspPMProjectCopyUDBuild 'JCJP', 'p', @insert output, @select output, @msg output
   		end

	----#143523
	select @sql = 'insert into JCJP (JCCo, Job, PhaseGroup, Phase, Description, Contract, Item, ProjMinPct, ActiveYN, InsCode, Notes'
   
   	if isnull(@insert,'') <> '' select @sql = @sql + @insert
   
   	select @sql = @sql + ') select ' + convert(varchar(3),@destjcco) + ', ' + CHAR(39) + @destjob + CHAR(39) + ', ' +
   		convert(varchar(3),@phasegroup) + ', p.Phase, p.Description, ' + CHAR(39) + @contract + CHAR(39) + ', '
   		if @subcontractyn = 'Y' 
   			select @sql = @sql + 'p.Item'
   		else
   			select @sql = @sql + CHAR(39) + @contractitem + CHAR(39)
		
		----#143523
   		select @sql = @sql + ', p.ProjMinPct, ' + CHAR(39) +  'Y' + CHAR(39) + ', p.InsCode, p.Notes'
   
   		if isnull(@insert,'') <> '' select @sql = @sql + @select
   
   		select @sql = @sql + ' from JCJP p where p.JCCo = ' + convert(varchar(3),@jcco) + ' and p.Job = ' + CHAR(39) + @srcjob + CHAR(39) +
   		' and not exists(select Phase from JCJP a where a.JCCo = ' + convert(varchar(3),@destjcco) + ' and a.Job = ' + CHAR(39) + @destjob + CHAR(39) +
   		' and a.Phase=p.Phase)'
   
   		exec (@sql)
   
  	
   		-- -- -- they will copy CostType if they copy Phases
   		-- insert phase cost type into bJCCH if missing in destination project
   	select @insert = null, @select = null
   	if @jcchud_flag = 'Y'
   		begin
   		exec @rcode = dbo.bspPMProjectCopyUDBuild 'JCCH', 'h', @insert output, @select output, @msg output
   		end
   
   	select @sql = 'insert into JCCH (JCCo, Job, PhaseGroup, Phase, CostType, UM, BillFlag, ItemUnitFlag, PhaseUnitFlag, ' +
   				  'BuyOutYN, Plugged, ActiveYN, OrigHours, OrigUnits, OrigCost, SourceStatus, Notes'
   
   	if isnull(@insert,'') <> '' select @sql = @sql + @insert
   
   	select @sql = @sql + ') select ' + convert(varchar(3),@destjcco) + ', ' + CHAR(39) + @destjob + CHAR(39) + ', ' +
   			convert(varchar(3),@phasegroup) + ', h.Phase, h.CostType, h.UM, h.BillFlag, h.ItemUnitFlag, h.PhaseUnitFlag, ' +
   			'h.BuyOutYN, ' + CHAR(39) + 'N' + CHAR(39) + ', ' + CHAR(39) + 'Y' + CHAR(39) + ', ' +
   			'OrigHours = case when ' + CHAR(39) + @origestim + CHAR(39) + ' = ' + CHAR(39) + 'N' + CHAR(39) + ' then 0 else h.OrigHours end, ' +
   			'OrigUnits = case when ' + CHAR(39) + @origestim + CHAR(39) + ' = ' + CHAR(39) + 'N' + CHAR(39) + ' then 0 else h.OrigUnits end, ' +
   			'OrigCost = case when ' + CHAR(39) + @origestim + CHAR(39) + ' = ' + CHAR(39) + 'N' + CHAR(39) + ' then 0 else h.OrigCost end, ' +
   			CHAR(39) + 'J' + CHAR(39) + ', h.Notes'
   
   	if isnull(@insert,'') <> '' select @sql = @sql + @select
   
   	select @sql = @sql + ' from JCCH h where h.JCCo = ' + convert(varchar(3),@jcco) + ' and h.Job = ' + CHAR(39) + @srcjob + CHAR(39) +
   		' and not exists(select CostType from JCCH a where a.JCCo = ' + convert(varchar(3),@destjcco) + ' and a.Job = ' + 
   		CHAR(39) + @destjob + CHAR(39) + ' and a.Phase=h.Phase and a.CostType=h.CostType)'
   
   	exec (@sql)

   		end
    
    
   -- -- insert approved CO headers
    if @changeorders = 'Y'
        	begin
   
   	select @insert = null, @select = null
   	if @jcohud_flag = 'Y'
   		begin
   		exec @rcode = dbo.bspPMProjectCopyUDBuild 'JCOH', 'h', @insert output, @select output, @msg output
   		end
   
   
   	select @sql = 'insert into JCOH (JCCo, Job, ACO, Description, ACOSequence, Contract, ChangeDays, '
   	select @sql = @sql + 'NewCmplDate, IntExt, ApprovalDate, ApprovedBy, BillGroup, Notes'
   
   	if isnull(@insert,'') <> '' select @sql = @sql + @insert
   
   	select @sql = @sql + ') select ' + convert(varchar(3),@destjcco) + ', ' + CHAR(39) + @destjob + CHAR(39) + ', ' +
   			'h.ACO, h.Description, h.ACOSequence, ' + CHAR(39) + @contract + CHAR(39) + ', ' +
   			'h.ChangeDays, h.NewCmplDate, h.IntExt, h.ApprovalDate, h.ApprovedBy, h.BillGroup, h.Notes'
   
   	if isnull(@insert,'') <> '' select @sql = @sql + @select
   
   	select @sql = @sql + ' from JCOH h where h.JCCo = ' + convert(varchar(3),@jcco) + ' and h.Job = ' + CHAR(39) + @srcjob + CHAR(39) +
   		' and not exists(select ACO from JCOH a where a.JCCo = ' + convert(varchar(3),@destjcco) + ' and a.Job = ' + CHAR(39) + @destjob + CHAR(39) +
   		' and a.ACO=h.ACO)'
   
   	exec (@sql)

    
   	-- insert change order items if missing in destination job
   	select @insert = null, @select = null
   	if @jcoiud_flag = 'Y'
   		begin
   		exec @rcode = dbo.bspPMProjectCopyUDBuild 'JCOI', 'i', @insert output, @select output, @msg output
   		end
   
   	select @sql = 'insert into JCOI (JCCo, Job, ACO, ACOItem, Contract, Item, Description, ApprovedMonth, ContractUnits, '
   	select @sql = @sql + 'ContUnitPrice, ContractAmt, BillGroup, Notes, ChangeDays '
   
   	if isnull(@insert,'') <> '' select @sql = @sql + @insert
   
   	select @sql = @sql + ') select ' + convert(varchar(3),@destjcco) + ', ' + CHAR(39) + @destjob + CHAR(39) + ', ' +
   			'i.ACO, i.ACOItem, ' + CHAR(39) + @contract + CHAR(39) + ', ' +
   			'i.Item, i.Description, i.ApprovedMonth, i.ContractUnits, i.ContUnitPrice, i.ContractAmt, i.BillGroup, i.Notes, i.ChangeDays '
   
   	if isnull(@insert,'') <> '' select @sql = @sql + @select
   
   	select @sql = @sql + ' from JCOI i where i.JCCo = ' + convert(varchar(3),@jcco) + ' and i.Job = ' + CHAR(39) + @srcjob + CHAR(39) +
   		' and not exists(select ACOItem from JCOI a where a.JCCo = ' + convert(varchar(3),@destjcco) + ' and a.Job = ' + 
   		CHAR(39) + @destjob + CHAR(39) + ' and a.ACO=i.ACO and a.ACOItem=i.ACOItem)'
   
   	exec (@sql)
    
            -- insert change order detail if missing in destination project - only if phase groups match
            if  @phasegrpyn = 'Y' and @phases = 'Y'
                begin
                insert into bJCOD (JCCo, Job, ACO, ACOItem, PhaseGroup, Phase, CostType, MonthAdded,
                        UM, UnitCost, EstHours, EstUnits, EstCost)
                select @destjcco, @destjob, l.ACO, l.ACOItem, @phasegroup, l.Phase, l.CostType,l.MonthAdded,
   
                        l.UM, l.UnitCost, l.EstHours, l.EstUnits, l.EstCost
                from bJCOD l where l.JCCo=@jcco and l.Job=@srcjob
                and not exists(select * from bJCOD a where a.JCCo=@destjcco and a.Job=@destjob
                        and isnull(a.ACO,'')=isnull(l.ACO,'') and isnull(a.ACOItem,'')=isnull(l.ACOItem,'')
                        and a.Phase=l.Phase and a.CostType=l.CostType)

			   	if @jcodud_flag = 'Y'
			   		begin
			   		exec @rcode = dbo.bspPMProjectCopyUDBuild 'JCOD', 'i', @insert output, @select output, @msg output
			   		end

                end
        end


--Issue 135571
if @CopyJobReviewers = 'Y'
begin
	insert into dbo.bJCJR (JCCo, Job, Seq, Reviewer, Memo, ReviewerType)
	select @destjcco, @destjob, j.Seq, j.Reviewer, j.Memo, j.ReviewerType 
	from dbo.bJCJR j with (nolock)	
	where j.JCCo=@jcco and j.Job=@srcjob 
		and not exists(select top 1 1 from dbo.bJCJR r with (nolock) where r.JCCo=@destjcco and r.Job=@destjob and r.Reviewer=j.Reviewer)
end

--Issue 135527
if @CopyJobRoles = 'Y'
BEGIN
	----TK-13879
	insert dbo.vJCJobRoles(JCCo, Job, VPUserName, Role, Notes, Lead, Active)
	select @destjcco, @destjob, VPUserName, Role, Notes, Lead, Active
		from dbo.vJCJobRoles with (nolock) where JCCo=@jcco and Job=@srcjob
end	
	
if @CopyJobPhaseRoles = 'Y'
begin		
	insert dbo.vJCJPRoles(JCCo, Job, PhaseGroup, Phase, Process, Role, Notes)
	select @destjcco, @destjob, r.PhaseGroup, r.Phase, r.Process, r.Role, r.Notes
		from dbo.vJCJPRoles r with (nolock) where r.JCCo=@jcco and r.Job=@srcjob
		and exists(select top 1 1 from dbo.JCJP p where p.JCCo=@destjcco and p.Job=@destjob and r.PhaseGroup=p.PhaseGroup and r.Phase=p.Phase) 
end	

----	-- -- -- Setup default security group to have access if securing bJob
----	select @jobsecure = Secure, @jobdefaultsecurity = DfltSecurityGroup
----	from dbo.DDDTShared with (nolock) where Datatype = 'bJob'
----	If @@rowcount = 1 and @jobsecure <> 'N'
----		begin
----		-- if no security group entry exists then set to default
----		if not exists (select top 1 1 from dbo.vDDDS with (nolock) where Datatype = 'bJob'
----						 and Qualifier = @destjcco and Instance = @destjob)
----			begin
----			if @jobdefaultsecurity is not null
----				begin
----				Insert vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
----				values ('bJob', @destjcco, @destjob, @jobdefaultsecurity)  
----				end
----			end
----		end
----   
----	-- -- -- Setup default security group to have access if securing bContract
----	select @contractsecure = Secure, @contractdefaultsecurity = DfltSecurityGroup
----	from dbo.DDDTShared with (nolock) where Datatype = 'bContract'
----	If @@rowcount = 1 and @contractsecure <> 'N'
----		begin
----
----		-- if no security group entry exists then set to default
----		if not exists (select top 1 1 from dbo.vDDDS with (nolock) where Datatype = 'bContract' 
----						and Qualifier = @destjcco and Instance = @contract)
----			begin
----			if @contractdefaultsecurity is not null
----				begin
----				Insert vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
----				values ('bContract', @destjcco, @contract, @contractdefaultsecurity)
----				end                 
----			end
----		end



bspexit:
	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspJCJobCopy] TO [public]
GO
