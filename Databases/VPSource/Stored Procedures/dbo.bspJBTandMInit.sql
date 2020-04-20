SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMInit Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBTandMInit]
/***********************************************************
* CREATED BY  : kb 3/15/00
* MODIFIED BY : kb 11/7/00 issue #11226
* 		kb 11/16/00 - issue for separate inv per billgroup
*     	kb 11/27/00 - add code to process misc dist
*    	GG 11/27/00 - changed datatype from bAPRef to bAPReference
*     	kb 2/7/01 - issue #12222
*   	kb 5/8/01 - issue #13341
*     	bc 06/04/01 - issue #
*     	kb 7/23/01 - issue #13319
*     	kb 8/13/1 - issue #13963
*     	kb 9/24/1 - issue #14440
*     	kb 9/24/1 - issue #10811 - this is a 5.7 issue
*    	kb 9/26/1 - issue #12377
*    	kb 10/20/1 - issue #14911
*   	kb 10/23/1 - issue #14971
*     	kb 12/17/1 - issue #12377
*   	kb 1/22/2 - issue #15979
*     	kb 2/6/2 - issue #16195
*    	kb 2/19/2 - issue #16147
*     	kb 2/19/2 - issue #16250
*     	kb 3/6/2 - issue #16496
*    	bc 3/14/2 - issue #16686
*     	kb 4/9/2 - issue #16870
*     	kb 4/29/2 - issue #17094
*    	kb 5/1/2 - issue #17095
*		TJL 07/3/02 - Issue #17701, Many Corrections to Non-Contract Bill initialization
*		SR 07/09/02 - 17738 passing @phasegroup to bspJCVCOSTTYPE
*		TJL 07/16/02 - Issue #17144, Pass in BillMth and BillNum to Detail Processing Proc
*		 kb 07/18/02 - issue #17948 allow missing payterms, no error in JBCE
*		TJL 08/20/02 - Issue #17472, MSTicket to JBID
*		TJL 09/03/02 - Issue #18346, LiabilityType to JBID
*		TJL 09/05/02 - Issue #17948, If PayTerms missing then DueDate = InvDate
*		TJL 09/05/02 - Issue #17414, Change APRef in #JBIDTemp from varchar(10) to varchar(15)
*		TJL 09/06/02 - Issue #18434, Correct retrieval of BillAddress info from Contract or Customer
*		TJL 09/09/02 - Issue #17620, Correct Source MarkupOpt when 'U' use Rate * Units
*  		bc  09/17/02 = Issue #18525
*		TJL 09/18/02 - Issue #18623, Correct 'JBIN RecType may not be NULL' error for Non-Contract Init
*		TJL 11/12/02 - Issue #18940, Add Contract to 'where' clause for 'AP PreBill' check
*		TJL 01/16/03 - Issue #19764, Correct Usage of Material Rates
*		TJL 02/26/03 - Issue #19765, Category returning as NULL for Material from HQMT. Fix bspJBTandMGetCategory
*		TJL 03/19/03 - Issue #19765, Not calling bspJBTandMGetCategory when JCTransType = 'MS'
*		TJL 04/02/03 - Issue #20911, Initialize for Contract, No Cost Detail Exists, using 'A'mount Sequence
*		TJL 05/28/03 - Issue #21280, PR Source, L ctcategory: 0 hours * Labor Rates must equal 0 not actualcost
*		TJL 06/24/03 - Issue #21388, Use PostedUnits for all sources, correct usage of MatlRate value.
*		TJL 07/31/03 - Issue #21714, Use Markup rate from JCCI if available else use Template markup.
*		TJL 08/25/03 - Issue #20471, Combine Total Addon Values for ALL Items under a single Item
*		TJL 09/19/03 - Issue #22442, Use PostedUM for all sources
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 10/06/03 - Issue #17897, Corrected MiscDistCode references to datatype char(10) (Consistent w/AR and MS)
*		TJL 12/08/03 - Issue #23222, Corrected LS @actualunits
*		TJL 12/29/03 - Issue #23416, Correct Separate Invoice for each Item BillGroup when all BillGroups = NULL
*		TJL 01/22/04 - Issue #23561, Correct @actualcost, @actualunitcost determined by the use of Equip Rates
*		TJL 03/12/04 - Issue #23089, Dont include Closed Contracts unless JCCO.PostClosedJobs = 'Y'
*		TJL 03/16/04 - Issue #24031, Call bspJBGetLastInvoice to get default Invoice Numbers
*		TJL 03/17/04 - Issue #18413,  Allow Invoice #s greater than 4000000000
*		TJL 03/23/04 - Issue #24048, Return and then Use correct ECM value from proper sources
*		TJL 03/31/04 - Issue #24189, Check for invalid Template Seq Item
*		TJL 04/05/04 - Issue #24234, Correct #JBIDTemp.StdPrice dimension.  Change to numeric(16,5)
*		TJL 04/07/04 - Issue #24240, Correct Divide by 0.00 error
*		TJL 04/08/04 - Issue #24194, Correct a problem with SeqSummaryOpt = 99, PR SeqSummaryOpt 12
*		TJL 04/30/04 - Issue #24472, Add AR Receipt to list of Sources in JCCD to pull from (MiscReceipts, Job)
*		TJL 05/04/04 - Issue #24499, Do Not run bspJBTandMProcessMiscDist when no JBIN BillNumber exists
*		TJL 05/04/04 - Issue #18944, Add Invoice Description to JBTMBills and JBProgressBillHeader forms
*		TJL 05/14/04 - Issue #22526, Accurately accumulate JBID UM, Units, UnitPrice, ECM.  Phase #1
*		TJL 06/11/04 - Issue #24809, Related to problem induced by Issue #24304. Set @matlrate errmsg
*		TJL 06/24/04 - Issue #24915, Increase Accuracy of JBID.SubTotal
*		TJL 08/10/04 - Issue #25314, Separate PR Burden by Category if desired
*		TJL 09/23/04 - Issue #25622, Remove TempTable (#JBIDTemp), use permanent table bJBIDTMWork, remove 14 psuedos
*		TJL 12/14/04 - Issue #26392, Do not Restrict using bspJBTandMGetEquipRate based upon RevCode values
*		TJL 01/10/05 - Issue #17896, Add EffectiveDate to JBTM and NewRate/NewSpecificPrice to JBLR, JBLO, JBER, JBMO
*		TJL 08/22/05 - Issue #29612, Use separate @linephasegroup, @linephase variable when updating JBIL to avoid @phasegroup null
*		TJL 09/29/05 - Issue #29638, Only Items in BillGroup should be initialized in Progress Bill when initializing by SeparateInv or BillGroup
*       JRE 05/20/06 - Issue #121063, 120700 Add Indexes, begin tran commit tran, to help prevent deadlocks & performance
*		TJL 09/25/06 - Issue #121269 (5x - #121253), Correct JCTransactions being place on two bills when initialized simultaneously
*		TJL 11/17/06 - Issue #123160 (5x - #123160), Correct Bill not in correct Template Sort Order problem
*		TJL 10/08/07 - Issue #125078, TransTypes 'IC' from 'JC CostAdj' need to be processed as JCTransTypes 'JC'
*		TJL 10/22/07 - Issue #29193, Address Defaults JCCM vs ARCM returned on single field basis
*		TJL 11/05/07 - Issue #124185, Add Invoice Description default on to and passed in from JBTandMInit form
*		 GF 12/17/07 - Issue #25569 separate post closed job flags in JCCO enhancement
*		TJL 12/20/07 - Issue #125982, Don't show IN Material Committed JCCD transactions on JB Bill
*		TJL 01/11/08 - Issue #123452, TransTypes 'MI' from 'JC MatlUse' need to be processed as JCTransTypes 'JC'
*		TJL 03/06/08 - Issue #127077, International Addresses
*		TJL 03/18/08 - Issue #126836, Add Pre-Bill warning to manual JC Transaction entry
*		TJL 06/30/08 - Issue #128850, Rounding problem when EM transaction using Rates by TimeUM
*		TJL 07/29/08 - Issue #128962, JB International Sales Tax
*		TJL 12/04/08 - Issue #131219, Related to #125982 - Committed or not based on ActualCost and ActualUnits
*		TJL 01/05/09 - Issue #120173, Combine Progress and T&M Auto-Initialization
*		TJL 01/21/08 - Issue #131622, Should have been part of Issue #123452.  Call bspJBTandMGetCategory for JC Matl
*		TJL 03/19/09 - Issue #120614, Add ability to include Rate value in summarization of PR Sources
*		TJL 09/25/09 - Issue #135094, When init option is set to 'B' and Template is not on Contract, do NOT initialize Progress or T&M.
*		TJL 11/17/09 - Issue #136331, When Separate Invoice is set for each Item Bill Group, separate invoices are not be created.
*		TJL 11/18/09 - Issue #136478, Duplicate Key error logging Contract Error in JBCE
*		GF  06/25/2010 - issue #135813 expanded SL to varchar(30)
*		TJL 08/20/10 - Issue #140764, TaxRate calculations accurate to only 5 decimal places.  Needs to be 6
*		EN/KK 7/12/2011 - D-01887 / TK-06698 / #143971  pass billgroup to bspJBTandMProcessAmtforInit to use when init'ing by billgroup
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*		KK  10/05/2011 - TK-08355 #142979 Pass billgroup to bspJBTandMProcessTotAddons to initialize by billgroup
*		DAN SO 05/29/2012 - TK-15229 integrating SM WorkOrders
*		
*
* USED IN:
*
* USAGE:
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/

(@co bCompany, @mth bMonth, @billinitopt char(1), @initopt char(1), @sendprocgroup varchar(10),
	@begincont bContract, @endcont bContract, @restrictbillgroupYN bYN,
	@billgroup bBillingGroup, @separateinvYN bYN, @invdate bDate,
	@begindate bDate, @enddate bDate, @endmonth bMonth, @laborenddate bDate,
	@assigninvYN bYN, @acothrudate bDate, @invdescription bDesc = null, 
	@progbillbegindate bDate, @progbillenddate bDate, @errorsexist tinyint output,
	@msg varchar(255) output)
as

set nocount on

declare @rcode int, @template varchar(10), @tempsortorder char(1),
	@laborrateopt char(1), @linedate bDate, @custgroup bGroup, @customer bCustomer,
	@equiprateopt char(1), @postdate bDate, @contract bContract, @billtype char(1),
	@equiphrlyum bUM, @laborcatyn bYN, @equipcatyn bYN, @matlcatyn bYN, @linedesc varchar(128),
	@seqtype char(1), @seqgroup int, @apyn bYN, @emyn bYN, @subtot numeric(15,5),
	@tempseq int, @inyn bYN, @jcyn bYN, @pryn bYN, @seqcategory varchar(10),
	@seqsummaryopt tinyint, @seqsortlevel tinyint,  @markupopt char(1), @arco bCompany,
	@seqmiscdistcode char(10), @seqmarkupopt char(1), @detailkey varchar(500),
	@seqmarkuprate bUnitCost, @seqaddonamt bDollar, @phasegroup bGroup, @markuprate numeric(17,6),
	@item bContractItem, @job bJob, @phase bPhase, @jccdmonth bMonth, @jccdtrans bTrans,
	@prco bCompany, @employee bEmployee, @craft bCraft, @class bClass, @addonline int,
	@earntype bEarnType, @factor bRate, @shift tinyint, @vendorgroup bGroup, @vendor bVendor,
	@apref bAPReference, @matlgroup bGroup, @material bMatl, @loc bLoc, @inco bCompany, @apco bCompany,
	@postedum bUM, @stdprice bUnitCost, @ctlabor bYN, @ctburden bYN, @ctmatl bYN,
	@ctsub bYN, @ctequip bYN, @ctother bYN, @sl VARCHAR(30), @slitem bItem, @emgroup bGroup,
	@equip bEquip, @revcode bRevCode, @actualdate bDate, @liabtype bLiabilityType,
	@jccddesc bDesc, @postedunitcost bUnitCost, @total bDollar, @markuptot numeric(15,5),
	@actualunitcost bUnitCost, @actualhours bHrs, @actualcost numeric(15,5), @actualecm bECM,
	@postedecm bECM, @ctcategory char(1), @jbilline int, @line int, @addonamt bDollar,
	@category varchar(10), @seqdesc varchar(128), @emco bCompany, @jbidseq int, @actualunits bUnits,
	@whatsource varchar(20), @linekey varchar(100), @addontype char(1), @equiprate bUnitCost,
	@addonseq int, @jbidsource char(2), @errmsg varchar(255), @currentcategory varchar(10),
	@transct bJCCType, @sequserates char(1), @laborrate bUnitCost, @equipoverrideyn bYN,
	@subtotal numeric(15,5), @jcchum bUM, @jcchbillflag char(1), @um bUM, @markupaddl bDollar,
	@addonmarkuprate bUnitCost, @SorAlineaddon bDollar, @addonmarkupopt char(1),
	@billnum int, @billaddress varchar(60), @billaddress2 varchar(60), @billcity varchar(20),
	@billstate varchar(4), @billzip bZip, @billcountry char(2), @invoice varchar(10), @invflag char(1), @discrate bPct,
	@jcglco bCompany, @arglco bCompany, @taxgroup bGroup, @postclosedjobs bYN, @ARrectype tinyint,
	@payterms bPayTerms, @rectype tinyint, @duedate bDate, @discdate bDate,
	@appliedtoseq int, @linetype char(1), @po varchar(30), @poitem bItem, @procgroup varchar(10),
	@retainage bDollar, @groupnum int, @HrsPerTimeUM bHrs, @billedunits bUnits,
	@billflag char(1), @datetouse bDate, @lineforaddon int, @jctranstype varchar(2),
	@matlrate bUnitCost, @matlecm bECM, @priceopt char(1), @usepostedYN bYN,
	@itembillgroup bBillingGroup, @notemplate tinyint, @skippedcontracts smallint,
	@errornumber int, @errordesc varchar(255), @contracterrors tinyint,
	@contractRecType tinyint, @flatamtopt char(1), @taxcode bTaxCode, @procgroupseq int,
	@basis bDollar, @discount bDollar, @linetaxcode bTaxCode,
	@prebillmonth bMonth, @prebillnum int, @prebillline int, @prebilllineseq int,
	@prebillmthstr varchar(20), @application smallint, @MSticket bTic, @contnocost bYN,
	@jccimarkuprate bRate, @taxrate bRate, @ecmfactor smallint, @stdecm bECM,
	@emrcbasis char(1), @jccdmatlgrp bGroup, @jccdmaterial bMatl, @jccdinco bCompany,
	@jccdloc bLoc, @jccdemgroup bGroup, @jccdequip bEquip, @jccdemrevcode bRevCode,
	@customerref bDesc, @invappdesc bDesc, @laboreffectivedate bDate, @equipeffectivedate bDate, 
	@matleffectivedate bDate, @linephasegroup bGroup, @linephase bPhase,
	@custbilladdress varchar(60), @custbilladdr2 varchar(60), @custbillcity varchar(30),
	@custbillstate varchar(4), @custbillzip bZip, @custbillcountry char(2), @custpayterms bPayTerms,
	@custrectype tinyint, @postsoftclosedjobs bYN, @billtypefortminit char(1),
	@progcontracterrors tinyint, @progsinglecontracterror tinyint
  
declare @openitemcursor tinyint, @openjobphasecursor tinyint, @openjcmthtranscursor tinyint, 
  	@openlinekeycursor tinyint,	@opendetailkeycursor tinyint, @opendetaddoncursor tinyint, 
  	@opentotaddoncursor tinyint, @openlinecursor tinyint, @openjbidseqcursor tinyint, 
  	@opencontractcursor tinyint, @openncprocgrpseqcursor tinyint, @opennctempseqcursor tinyint
  
select @rcode = 0, @errorsexist = 0, @notemplate = 0, @contracterrors = 0,
  	@openitemcursor = 0, @openjobphasecursor = 0, @openjcmthtranscursor = 0, 
  	@openlinekeycursor = 0,	@opendetailkeycursor = 0, @opendetaddoncursor = 0, 
  	@opentotaddoncursor = 0, @openlinecursor = 0, @openjbidseqcursor = 0, 
  	@opencontractcursor = 0, @openncprocgrpseqcursor = 0, @opennctempseqcursor = 0,
  	@progcontracterrors = 0, @progsinglecontracterror = 0

/* Used only during the T&M initialization cycle to limit Items cursor to specific item billtypes.  
   Bill Initialization Option will be only T or B. */
select @billtypefortminit = case @billinitopt when 'T' then 'T' when 'B' then 'B' end
 
/* Get company information. */
select @invflag = b.InvoiceOpt,
  	@jcglco = c.GLCo, @arco = c.ARCo, @postclosedjobs = c.PostClosedJobs,
  	@arglco = a.GLCo, @ARrectype = a.RecType,
  	@taxgroup = h.TaxGroup, @phasegroup = h.PhaseGroup, @postsoftclosedjobs = c.PostSoftClosedJobs
from bJBCO b with (nolock)
join bJCCO c with (nolock) on c.JCCo = b.JBCo
join bARCO a with (nolock) on a.ARCo = c.ARCo
join bHQCO h with (nolock) on h.HQCo = b.JBCo
where b.JBCo = @co
if @@rowcount = 0
  	begin
  	select @msg = 'Invalid JB Company.', @rcode = 1
  	goto bspexit
  	end
  
/* NON-CONTRACT BILLS:  If initopt = 'P' then first create bills for stuff in process group without a contract */
if @initopt = 'P'
  	begin	/* Begin Option 'P' loop */
  	declare bcNCProcGrpSeq cursor local fast_forward for
 	select Seq
 	from JBGC with (nolock)
 	where JBCo = @co and ProcessGroup = @sendprocgroup and Contract is null
  	group by Seq
  
  	open bcNCProcGrpSeq
  	select @openncprocgrpseqcursor = 1
  
  	fetch next from bcNCProcGrpSeq into @procgroupseq
  	while @@fetch_status = 0
  		begin	/* Begin Processing Group Seq loop */
      	select @custgroup = CustGroup, @customer = Customer, @template = Template
       	from JBGC with (nolock)
       	where JBCo = @co and ProcessGroup = @sendprocgroup and Seq = @procgroupseq
  
  		/* Need to retrieve BillAddress info from ARCM since this is Non-Contract at this
  		   point. */
  		select @billaddress = BillAddress, @billaddress2 = BillAddress2,
  	     	@billcity = BillCity, @billstate = BillState, @billzip = BillZip, @billcountry = BillCountry,
  			@payterms = PayTerms, @rectype = RecType
  	   	from bARCM	with (nolock)
  	   	where CustGroup = @custgroup and Customer = @customer
  	   	if @@rowcount = 0
  	     	begin
  	     	select @msg = isnull(convert(varchar(10),@customer),'') + ' - Invalid Customer', @rcode = 1
  			goto bspexit
  	     	end
  
  		/* Determine Dates from PayTerms if PayTerms is available else use InvDate */
  		if @payterms is not null
  			begin
  			exec @rcode = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @duedate output, @discrate output, @errmsg output
  			end
  	   	if @duedate is null select @duedate = @invdate		--DATEADD(day,30,@invdate)
  
  		/* Determine RecType to use either from Customer or ARCo */
  		if @rectype is null select @rectype = @ARrectype
  
  		/* Get Template info */
       	if @template is not null 	-- gotta have a template
     		begin
     		select @tempsortorder = SortOrder
     		from bJBTM with (nolock)
  			where JBCo = @co and Template = @template
  
			select @billtype = 'T'
  			Begin Tran --121063, 120700
          	select @billnum = isnull(max(BillNumber),0) + 1
          	from bJBIN
          	where JBCo = @co and BillMonth = @mth
  
          	insert bJBIN (JBCo,BillMonth,BillNumber,Invoice,Contract,CustGroup,
  	        	 Customer,InvStatus,Application,ProcessGroup,RestrictBillGroupYN,
  	             BillGroup,RecType,DueDate,InvDate,PayTerms,DiscDate,FromDate,
  	             ToDate,BillAddress,BillAddress2,BillCity,BillState,BillZip,BillCountry,
  	             ARTrans,InvTotal,InvRetg,RetgRel,InvDisc,TaxBasis,InvTax,
  	             InvDue,PrevAmt,PrevRetg,PrevRRel,PrevTax,PrevDue,ARRelRetgTran,
  	             ARRelRetgCrTran,ARGLCo,JCGLCo,CurrContract,PrevWC,WC,PrevSM,
  	             Installed,Purchased,SM,SMRetg,PrevSMRetg,PrevWCRetg,WCRetg,
  	             PrevChgOrderAdds,PrevChgOrderDeds,ChgOrderAmt,AutoInitYN,
  	             InUseBatchId,InUseMth,Notes,BillOnCompleteYN,BillType,Template,
  	             CustomerReference,CustomerJob,ACOThruDate,Purge,
  	             OverrideGLRevAcctYN,OverrideGLRevAcct,InvDescription,AuditYN,
				 TMUpdateAddonYN,CreatedBy,CreatedDate)
          	select @co, @mth, @billnum,@invoice,null,@custgroup,@customer,
         		'A',null,@procgroup,@restrictbillgroupYN,@billgroup, @rectype,
             	@duedate,@invdate,@payterms,@discdate,
             	@begindate,@enddate,@billaddress,@billaddress2,@billcity,
             	@billstate,@billzip,@billcountry,null, 0,0,0,0,0,
             	0,0,0,0,0,0,0,
             	null,null,@arglco,@jcglco,0,
             	0,0,0,0,0,0,0,0,
             	0,0,0,0,0,
             	'Y',null,null,null,'N',@billtype/*'T'*/,@template,null,
             	null,null,'N','N',null,isnull(@invdescription, 'JB T&M'),'Y',
				'N',SUser_Name(),convert(varchar, GetDate(), 1)
  			commit tran --121063, 120700

  			declare bcNCTempSeq cursor local fast_forward for
          	select Seq
          	from bJBTS with (nolock)
          	where JBCo = @co and Template = @template and Type = 'A'
  			group by Seq
  
  			open bcNCTempSeq
  			select @opennctempseqcursor = 1
  
  			fetch next from bcNCTempSeq into @tempseq
  			while @@fetch_status = 0
  				begin	/* Begin Template Seq loop */
        		select @seqtype = Type, @seqgroup = GroupNum, @seqdesc = Description,
          			@seqmiscdistcode = MiscDistCode, @markupopt = MarkupOpt,
          			@markuprate = MarkupRate, @flatamtopt = FlatAmtOpt, @markupaddl = AddonAmt
        		from bJBTS with (nolock)
        		where JBCo = @co and Template = @template and Seq = @tempseq
  
  		  		/* Get LineKey for this Line.  Detail Addons depend upon it. */
        		exec bspJBTandMGetLineKey @co, null, null, null, null, @template, @tempseq ,
        			null, @invdate, @seqgroup, 'N', @linekey output, @msg output

        		select @basis = @markupaddl, @total = @markupaddl	--, @markuptot = @markupaddl
  					
				Begin Tran --121063, 120700
        		select @line = isnull(max(Line),0) + 10
        		from bJBIL
        		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum

        		insert bJBIL (JBCo, BillMonth, BillNumber, Line, Item, Contract, Job, PhaseGroup,
            		Phase, Date, Template, TemplateSeq, TemplateSortLevel, TemplateSeqSumOpt,
            		TemplateSeqGroup, LineType, Description, TaxGroup, TaxCode, MarkupOpt,
            		MarkupRate, Basis, MarkupAddl, MarkupTotal, Total, Retainage, Discount,
            		NewLine, ReseqYN, LineKey, Notes, TemplateGroupNum, LineForAddon, AuditYN)
          		select @co, @mth, @billnum, @line, null, null, null, null,
            		null, null, @template, @tempseq, null, null,
              		@seqgroup, @seqtype, @seqdesc, @taxgroup, @taxcode, @markupopt,
             		0, isnull(@basis,0), 0, 0, isnull(@total,0), 0, 0,
             		null, 'N', @linekey, null, @seqgroup, null,'N'
				commit tran --121063, 120700

				exec @rcode = bspJBTandMProcessDetAddonsNC @co, @mth, @billnum, @template, @line, 0, @msg output
  
  				fetch next from bcNCTempSeq into @tempseq
				end		/* End Template Seq loop */
  
  			if @opennctempseqcursor = 1
  				begin
  				close bcNCTempSeq
  				deallocate bcNCTempSeq
  				select @opennctempseqcursor = 0
  				end
          	end
  
  	  	/* Now process total addons.  Skip if no lines currently exist in bJBIL. */
  		if exists(select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @mth
  				and BillNumber = @billnum)
  			begin
  		  	exec @rcode = bspJBTandMProcessTotAddons @co, @template, @billnum, @mth, null, @itembillgroup, @msg output
  			if @rcode <> 0	--(Will be 1)
  				begin
  				select @msg = 'Error creating Total Addon - ' + @msg, @rcode = 1
  				goto bspexit
  				end

			/* Update JBIN Totals */
			exec @rcode = vspJBTandMUpdateJBIT @co, @mth, @billnum, null, null, @msg output
  			if @rcode <> 0	
  				begin
  				select @errordesc = 'Error updating Bill Header amounts - ' + @msg, @rcode = 1
  				goto bspexit
  				end
  			end
  
		/* Reset TMUpdateAddonYN flag so that future manual changes to bill will use JBIL triggers to update 
		   Addons correctly. */
		update bJBIN
		set TMUpdateAddonYN = 'Y'
		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum

  		fetch next from bcNCProcGrpSeq into @procgroupseq
      	end		/* End Processing Group Seq loop */
  
  	if @openncprocgrpseqcursor = 1
  		begin
  		close bcNCProcGrpSeq
  		deallocate bcNCProcGrpSeq
  		select @openncprocgrpseqcursor = 0
  		end 
   	end		/* End Option 'P' loop */
  
/*************************************** CONTRACT PROCESSING BEGINS **************************************/
  
/* This should actually be restricted by the form (and will be in 6x), however for now we will simply abort
 	the initialization process before it begins and user can change processing form inputs.  
 	When both are checked, a bill will be created starting with the value in Item Bill Group input and a 
 	separate bill will get created for each BillGroup greater than that one.  Its a hybrid, I hope no one
 	is using it this way.  */
if @separateinvYN = 'Y' and @restrictbillgroupYN = 'Y'
 	begin
 	select @msg = 'Restrict by Item BillGroup and Add Separate Invoice by Item BillGroup '
 	select @msg = @msg + 'checkboxes may not be both CHECKED at the same time.  Remove one or the other.', @rcode = 1
 	goto bspexit
 	end
 
/* Cycle through contracts with T&M or Progress billing types based on contract range or
   processing group.  (Form does not allow Null BegContract, EndContract, or ProcessGroup) */
declare bcContract cursor local fast_forward for
select Contract
from bJCCM with (nolock)
where JCCo = @co and
	((@initopt = 'C' and (Contract >=@begincont and (Contract <=@endcont or @endcont is null))) or
	(@initopt = 'P' and (ProcessGroup = @sendprocgroup or (@sendprocgroup is null and ProcessGroup is null))))
	and ((ContractStatus = 1) or 
		(ContractStatus = 2 and @postsoftclosedjobs = 'Y') or
		(ContractStatus = 3 and @postclosedjobs = 'Y'))
----(ContractStatus > 1 and @postclosedjobs = 'Y'))
group by Contract
  
open bcContract
select @opencontractcursor = 1
  
fetch next from bcContract into @contract
while @@fetch_status = 0
  	begin	/* Begin Contract Loop */
 	select @billnum = null
  	select @contnocost = 'Y', @customerref = null	
 
 	/* clear out the errors for this contract from the last time it was initialized */
 	delete from bJBCE where JBCo = @co and Contract = @contract
 
  	/* Get template info from JBTM */
  	if @billinitopt in ('T', 'B')
  		begin
 		select @template = c.JBTemplate, @tempsortorder = t.SortOrder, @laborrateopt = t.LaborRateOpt,
  			@equiprateopt = t.EquipRateOpt,
  			@laborcatyn = t.LaborCatYN, @equipcatyn = t.EquipCatYN, @matlcatyn = t.MatlCatYN,
 			@laboreffectivedate = t.LaborEffectiveDate, @equipeffectivedate = t.EquipEffectiveDate, 
 			@matleffectivedate = t.MatlEffectiveDate
 		from bJCCM c with (nolock)
 		join bJBTM t with (nolock) on t.JBCo = c.JCCo and t.Template = c.JBTemplate
 		where c.JCCo = @co and c.Contract = @contract
 		if @@rowcount = 0
       		begin
       		select @errordesc = 'Contract(s) in the specified range were skipped because no template was setup.',
				@errornumber = 108
       		goto BillError
       		end
       	end
       	
	if @billinitopt in ('P', 'X', 'B')
		begin
		select @progsinglecontracterror = 0
			
		exec @rcode = bspJBProgressBillInit @co, @mth, @contract, @billinitopt, @restrictbillgroupYN, @billgroup, 
			@invdate, @progbillbegindate, @progbillenddate, @acothrudate, @assigninvYN, @invdescription, 
			@billnum output, @progsinglecontracterror output, @msg output
		if @rcode <> 0 goto bspexit			--Serious enough error to discontinue initialize process.
		if @progsinglecontracterror = 1
			begin
			/* A Contract error has occured while processing Progress items.  Continue process but inform user
			   when process completes.  Error has already been logged in bJBCE at this point. */
			select @progcontracterrors = 1
			end
			
		if @billinitopt in ('P', 'X') goto NextContract		--For 'B' bill option, continue processing T&M
		end

  	/* If option to use separate invoice for each BillGroup is set, (RestrictByBillGroup should be 'N')
  	   and so we set our STARTING BillGroup to be either NULL or the Minimum 
  	   BillGroup by ContractItem.  BillGroup will be incremented later in the procedure. */
 	if @separateinvYN = 'Y' and @restrictbillgroupYN = 'N'
 	  	begin
 		/* If Null BillGroup exists it becomes our STARTING BillGroup. */
 	  	if exists(select 1
 	            from bJCCI with (nolock)
 	            where JCCo = @co and Contract = @contract 
 						and BillType in ('B','T') and BillGroup is null)
 			begin
 			select @itembillgroup = null
 			end
 	   	else
 			/* If Null BillGroup does not exist, use Minimum as STARTING BillGroup. */
 	   		begin
 	   		select @itembillgroup = min(BillGroup)
 	      	from bJCCI with (nolock)
 	    	where JCCo = @co and BillType in ('B','T') and Contract = @contract
 	   		end
 		select @restrictbillgroupYN = 'Y'	--effectively we will be restricting by BillGroup for each bill
 	  	end
  
  	/* If RestrictByBillGroup = 'Y' (Separate Invoice is not valid and should = 'N')
  	   Set BillGroup to the valid input by user.  If NULL, then only those JCCI
  	   items containing a NULL BillGroup value will get billed. */
  	if @restrictbillgroupYN = 'Y' and @separateinvYN = 'N'
 		begin	
 		select @itembillgroup = @billgroup
 		end
  
  	/* All JCCD transactions for this Contract, and specific JCCI Item BillGroup
  	   will get placed on this BillNumber.  Only one BillGroup per bill!  However
  	   this code gets run multiple times (Generating Multiple bills) if Separate 
  	   Invoice flag is set = 'Y' but still each bill generated is still only
  	   encompassing a single Item Bill Group. */ 
ThisBillGroup:	/* Will get called again if Separate Invoice is set to 'Y' */
  
	/* Get the info from Contract.  In most cases Contract information, when available, takes
       precedence over Customer or AR Company information when setting default values. */
 	select @custgroup = CustGroup, @customer = Customer,
  		@payterms = PayTerms, @billaddress = BillAddress, @procgroup= ProcessGroup,
  		@billaddress2 = BillAddress2, @billcity = BillCity, @billstate = BillState,
  		@billzip = BillZip, @billcountry = BillCountry, @billtype = DefaultBillType, @contractRecType = RecType,
 		@customerref = CustomerReference	
 	from bJCCM with (nolock)
 	where JCCo = @co and Contract = @contract
  
	/* Get the info from Customer.  Default values (Contract vs Customer) determined later. */
	select @custbilladdress = BillAddress, @custbilladdr2 = BillAddress2,
		@custbillcity = BillCity, @custbillstate = BillState, @custbillzip = BillZip, @custbillcountry = BillCountry,
		@custpayterms = PayTerms, @custrectype = RecType
	from bARCM with (nolock)
	where CustGroup = @custgroup and Customer = @customer
   	if @@rowcount = 0
     	begin
     	select @errordesc = isnull(convert(varchar(10),@customer),'') + ' - Invalid Customer', @errornumber = 102, @rcode = 0
     	goto BillError
     	--         goto NextContract
     	end

	/* Any values not returned from JCCM, use those from ARCM. */
	select @payterms = isnull(@payterms, @custpayterms), 
   		@rectype = isnull(@contractRecType, @custrectype),
		@billaddress = isnull(@billaddress, @custbilladdress),
		@billaddress2 = isnull(@billaddress2, @custbilladdr2),
		@billcity = isnull(@billcity, @custbillcity),
		@billstate = isnull(@billstate, @custbillstate),
		@billzip = isnull(@billzip, @custbillzip),
		@billcountry = isnull(@billcountry, @custbillcountry)

	/* If Default RecType still missing, get from ARCO */
  	if @rectype is null select @rectype = @ARrectype
 
 	if @rectype is null
 	  	begin
 	  	select @msg = 'Missing Receivable Type'
 	  	select @errordesc = @msg, @errornumber = 104, @rcode = 0
 	  	goto BillError
 	  	end
 
 	exec @rcode = bspARRecTypeVal @co, @rectype,  @errmsg output
 	if @rcode <> 0
 	  	begin
 	   	select @errordesc = @errmsg, @errornumber = 105 , @rcode = 0
 	   	goto BillError
 	   	end
  
  	if @payterms is not null
  		begin
  	   	exec @rcode = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @duedate output, @discrate output, @errmsg output
  	   	if @rcode <> 0
  	     	begin
  	     	select @errordesc = @errmsg, @errornumber = 106, @rcode = 0
  	     	goto BillError
  	     	end
  		end
  
 	/* If duedate not set from payterms set duedate to be invoice date plus 30 days, works like AR*/
 	if @duedate is null select @duedate = @invdate		--DATEADD(day,30,@invdate)
  
/************ BEGIN JC TRANSACTION PROCESSING. VALUES WILL BE PLACED INTO WORK TABLE INITIALLY *************/
  
  	/**************************************/
  	/* Clear out Work table for this User */
  	/**************************************/
  	delete bJBIDTMWork where JBCo = @co and VPUserName = SUSER_SNAME()
  
/******************************** BEGIN JC TRANSACTION PROCESSING BY ITEM ******************************/
 	/* Cycle through JCJP by item. */
  	declare bcItem cursor local fast_forward for
 	select p.Item
 	from bJCJP p with (nolock)
 	join bJCCI i with (nolock) on i.JCCo = p.JCCo and i.Contract = p.Contract and i.Item = p.Item
 	where p.JCCo = @co and p.Contract = @contract 
  		and p.PhaseGroup = @phasegroup 
		and i.BillType = @billtypefortminit
 		and (isnull(i.BillGroup, '') = case when @restrictbillgroupYN = 'Y' then isnull(@itembillgroup, '') else isnull(i.BillGroup, '') end)
  	group by p.Item
 
  	open bcItem
  	select @openitemcursor = 1
  
  	fetch next from bcItem into @item
  	while @@fetch_status = 0
       	begin	/* Begin JCJP Item Loop */
  		select @contnocost = 'N'
  
       	/* Cycle through job/phases for this item*/
  		declare bcJobPhase cursor local fast_forward for	
       	select Job, Phase
       	from bJCJP with (nolock)
       	where JCCo = @co and Contract = @contract and Item = @item and PhaseGroup = @phasegroup
  		group by Job, Phase		
  
  		open bcJobPhase
  		select @openjobphasecursor = 1
  
  		fetch next from bcJobPhase into @job, @phase
  		while @@fetch_status = 0
       		begin	/* Begin Job/Phase Loop */
       		/* Cycle through JCCD for this job/phase*/
  			declare bcJCMthTrans cursor local fast_forward for
       		select Mth, CostTrans
       		from bJCCD with (nolock)
       		where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and
             		(JBBillStatus is  null or JBBillStatus =0) and
             		Source in ('AP Entry', 'JC CostAdj', 'EMRev', 'PR Entry', 'JC MatUse', 'MS Tickets', 'IN MatlOrd', 'AR Receipt', 'SM WorkOrd') --add in/ms stuff -- TK-15229
             		and ActualDate >= isnull(@begindate,'1/1/50') --(ActualDate >= @begindate or @begindate is null)
             		and (ActualDate <= @enddate or @enddate is null)
             		and (Mth <=@endmonth or @endmonth is null)
  			group by Mth, CostTrans
  
  			open bcJCMthTrans
  			select @openjcmthtranscursor = 1
  
  			fetch next from bcJCMthTrans into @jccdmonth, @jccdtrans
  			while @@fetch_status = 0			
       			begin	/* Begin JC Mth/Trans Loop - First */
       			/* Add billheader if it doesn't already exist, talked to Carol
         			and she said that if the header is added but no detail because
         			all of the detail fell into the error category then it is ok
         			to have headers out there without detail. The reason for this is that
         			the JBJE - error table is in terms of the bill number */
  
  								/***********************************/
  								/*    INSERT BILL HEADER HERE      */
  								/***********************************/


       			if @billnum is null
         			begin	/* Begin BillNum Null Loop */
           			if @assigninvYN = 'Y'
             			begin
  						/* Automatically Assign Invoice number from either JBCO or ARCO */
  						exec @rcode = bspJBGetLastInvoice @co, @invoice output, @msg output
  						if @rcode <> 0
  							begin
  							select @msg = 'Error getting next invoice #.  ' + @msg
           					select @errordesc = @msg, @errornumber = 107, @rcode = 0
  							goto BillError
  							end
             			end
  
--					if exists(select 1 from bJCCI with (nolock) where JCCo = @co and Contract = @contract and BillType = 'B')
--         				begin
--         				select @billtype = 'B'
--         				end
-- 					else
--         				begin
--         				select @billtype = 'T'
--         				end
					select @billtype = 'T'				--'B' bill headers now get initialized from bspJBProgressBillInit

           			if @contract is not null
               			begin
               			select @application = isnull(max(Application),0) + 1
              	 		from bJBIN with (nolock)
                			where JBCo = @co and Contract = @contract
               			end
             		else
               			begin
               			select @application = null
               			end
  
  					if @billtype = 'B' and @application is not null
  						begin
  						select @invappdesc = 'JB App# ' + convert(varchar(5), @application)
  						end
  					else
  						begin
  						select @invappdesc = null
  						end
  					Begin Tran --121063, 120700
           			select @billnum = isnull(max(BillNumber),0) + 1
            		from bJBIN
           			where JBCo = @co and BillMonth = @mth
  
           			insert bJBIN (JBCo,BillMonth,BillNumber,Invoice,Contract,CustGroup,
                        	Customer,InvStatus,Application,ProcessGroup,RestrictBillGroupYN,
                        	BillGroup,RecType,DueDate,InvDate,PayTerms,DiscDate,FromDate,
                        	ToDate,BillAddress,BillAddress2,BillCity,BillState,BillZip,BillCountry,
                        	ARTrans,InvTotal,InvRetg,RetgRel,InvDisc,TaxBasis,InvTax,
                        	InvDue,PrevAmt,PrevRetg,PrevRRel,PrevTax,PrevDue,ARRelRetgTran,
                        	ARRelRetgCrTran,ARGLCo,JCGLCo,CurrContract,PrevWC,WC,PrevSM,
                        	Installed,Purchased,SM,SMRetg,PrevSMRetg,PrevWCRetg,WCRetg,
                        	PrevChgOrderAdds,PrevChgOrderDeds,ChgOrderAmt,AutoInitYN,
                        	InUseBatchId,InUseMth,Notes,BillOnCompleteYN,BillType,Template,
                        	CustomerReference,CustomerJob,ACOThruDate,Purge,AuditYN,
                        	OverrideGLRevAcctYN,OverrideGLRevAcct,
  							InvDescription,TMUpdateAddonYN,CreatedBy,CreatedDate,InitOption)
            		select @co, @mth, @billnum,@invoice,@contract,@custgroup,@customer,
                   		'A',@application,@procgroup,@restrictbillgroupYN, @itembillgroup, @rectype,
                   		@duedate, @invdate, @payterms, @discdate,
                   		@begindate,@enddate,@billaddress,@billaddress2,@billcity,
                   		@billstate,@billzip,@billcountry,null, 0,0,0,0,0,0,0,0,0,0,0,0,
                   		null,null,@arglco,@jcglco,0,
                   		0,0,0,0,0,0,0,0,0,0,0,0,0,
                   		'Y',null,null,null,'N',@billtype/*'T'*/,@template,null,
                   		null,@acothrudate,'N','Y','N',null,
  						case @billtype when 'T' then isnull(@invdescription, isnull(@customerref,'JB T&M'))
  							else isnull(@invdescription, isnull(@invappdesc, isnull(@customerref,'JB T&M'))) end,
 						'N', SUser_Name(), convert(varchar, GetDate(), 1), @billinitopt
					commit tran --121063, 120700
            		end		/* End BillNum Null Loop */
  
				/* Get JCCD info for this CostTrans:  Any changes made in the following steps
				   must also be made in procedurs bspJBTandMAddJCTrans. */
				select @jbidsource = case Source when 'JC MatUse' then 'IN' else left(Source,2) end,
						@jctranstype = case JCTransType when 'CA'then 'JC'
									when 'IC' then 'JC' 
									when 'MI' then 'JC' 
									--when 'MO' then 'IN'
								else JCTransType end,
						/* @usepostedYN = case when Source in ('JC MatUse','MI') then 'Y' else 'N' end, */
						@prco = PRCo, @employee = Employee, @craft = Craft,
						@class = Class, @earntype = EarnType, @factor = EarnFactor,
						@shift = Shift, @apco = APCo,
						@vendorgroup = VendorGroup, @vendor = Vendor,
						@apref = APRef, @inco = INCo, @MSticket = MSTicket,
						@matlgroup = MatlGroup, @material = Material, @loc = Loc,
						@stdprice = ActualUnitCost, @postdate = PostedDate,
						@sl=SL, @slitem = SLItem, @emgroup = EMGroup,
						@equip = EMEquip, @revcode = EMRevCode, @actualdate = ActualDate,
						@jccddesc=Description, @liabtype = LiabilityType,
						@um = UM,
						--@um = case JCTransType when 'AP' then PostedUM else UM end,
						@actualunits = PostedUnits,
						--@actualunits = case when Source in ('JC MatUse','MI') then PostedUnits  ***
						--	else case when JCTransType = 'AP' then									**	Removed Issue #21388, easier to change					
						--    	case when UM <> PostedUM then PostedUnits else ActualUnits end		**	here than to use @postedunits thru-out
						--   	else ActualUnits end end,										  ***
						@postedum = PostedUM,
						@postedunitcost = PostedUnitCost,
						@actualunitcost = PostedUnitCost,
						--@actualunitcost = case when Source in ('JC MatUse','MI') then PostedUnitCost ***
     					--	else case when JCTransType = 'AP' then										 **	Removed Issue #21388, easier to change
						--    	case when UM <> PostedUM then PostedUnitCost else ActualUnitCost end     **	here than to use @postedunitcost thru-out
						--  	else ActualUnitCost end end,                                           ***
						@actualhours = ActualHours,
						@actualcost = ActualCost,
						@actualecm = PostedECM, @stdecm = PerECM,
						@postedecm = PostedECM, @emco = EMCo, @transct = CostType,
						@po = PO, @poitem = POItem
				from bJCCD with (nolock)
				where JCCo = @co and Mth = @jccdmonth and CostTrans = @jccdtrans and
						(JBBillStatus is null or JBBillStatus =0)
  	
  				/* As of 08/30/02, @datetouse was not being used anywhere. */
      			--select @datetouse = case @tempsortorder when 'A' then @actualdate when 'D' then @postdate end

  				/* Separate variables to update bJBIJ and to pass into procedure bspJBTandMUpdateJBIDUnitPrice 
  				   are needed.  Some variables from above get set differently (or Nulled out) in order 
  				   to update bJBID according to Template Summary and Sort options. */
  				select @jccdmatlgrp = @matlgroup, @jccdmaterial = @material, @jccdinco = @inco,
  					@jccdloc = @loc, @jccdemgroup = @emgroup, @jccdequip = @equip, @jccdemrevcode = @revcode

				/***** SPECIAL SETUP of @jctranstype value *****/

				/* AP evaluation: based upon presence of Material or SL */
  				/* This is a different situation where even though the transaction falls under a 
  				   Template Seq source of 'AP', we chose to display the source in the JCDetail Form (JBID)
  				   record as something other (ie. TempSeq Src = AP, JBIDSrc displayed as MT or SL). */  
      			if @jctranstype = 'AP' --@jbidsource = 'AP' --set source for SL and Material types
        				begin
        				if @material is not null select @jctranstype = 'MT'		--@jbidsource = 'MT'
        				if @sl is not null select @jctranstype = 'SL'			--@jbidsource = 'SL'
        				end

      			/* PR, MS evaluation: based upon JBCostTypeCategory */
      			select @ctcategory = JBCostTypeCategory
      			from bJCCT with (nolock)
      			where PhaseGroup = @phasegroup and CostType = @transct

      			if (@jctranstype = 'PR' and @ctcategory = 'E')
  					or (@jctranstype = 'MS' and @ctcategory = 'E') select @jctranstype = 'EM'

				/***** SPECIAL EVALUATION:  Under certain conditions, skip this transaction altogether. *****/

				/* If Transaction ActualDate falls after Labor EndDate passed from form, skip transaction. */
      			if @jctranstype = 'PR'	
         			and @laborenddate is not null and @actualdate > @laborenddate
        			goto NextTrans

				if @jctranstype = 'MO'
					begin
					if @actualcost = 0 and @actualunits = 0
						begin
						/* Material Order Transaction has committed costs but none yet confirmed.  Do Not show on Bill. */
						goto NextTrans
						end
					else
						begin
						/* Material Order/Item Transaction has been Confirmed.  Place Transaction on Bill. */
						select @jctranstype = 'IN'
						end
					end

				/* Check CostType Bill flag.  If set to 'N', skip transaction. */
  				exec bspJCVCOSTTYPE @co, @job, @phasegroup, @phase, @transct, 'N',
  					-- outputs
  			    	null, null, null, @jcchbillflag output, @jcchum output, null, null, 
  					null, null, @msg output
  
      			if @jcchbillflag = 'N'
        				begin
        				exec @rcode = bspJBTandMTransErrors @co, @mth, @billnum, @jccdmonth, @jccdtrans, 9, @msg output
        				goto NextTrans
        				end

				/***** INFORMATION AND RATES *****/
				/* Set a flag determining if rates are used over costs.
				 This is only valid for PR and EM detail and is based on
				 a flag in the template.  The option can be overridden
				 at the category level however and if the source is PR
				 the rates can be overridden at levels lower than the category. 

				@sequserates get changed later on by running bspJBTandMGetLaborRate and
				bspJBTandMGetEquipRate. */
      			select @sequserates = case @jctranstype
                  	when 'PR' then case @ctcategory	
  					when 'L' then @laborrateopt				--C, R
  					when 'B' then @laborrateopt				--C, R
                 	when 'E' then @equiprateopt end			--C, R, T (due to the above, this line NA)
                 	when 'EM' then @equiprateopt			--C, R, T
                    	else 'C' end
  
      			/* Get category. */
      			if (@jctranstype = 'PR' and @ctcategory in ('L','B') and (@laborcatyn = 'Y' or @sequserates='R')) or
         				(@jctranstype = 'PR' and @ctcategory ='E' and (@equipcatyn = 'Y' or @sequserates in('T','R')) or
         					((@jctranstype = 'JC' or @jctranstype = 'MT' or @jctranstype = 'IN'or @jctranstype = 'MS') and @matlcatyn = 'Y') or
         					(@jctranstype = 'EM' and(@sequserates in('T','R') or @equipcatyn = 'Y')))
        			begin
  					/* Much of what is passed into this procedure below is unnessesary. 
  						1) LaborCategory is returned from bJBLX Labor Rate Table
  						2) EquipCategory is returned from bEMEM
  						3) Material Category is return from either bHQMT or bEMEM */	
    					exec @rcode = bspJBTandMGetCategory @co, @prco, @employee, @craft, @class, @earntype,
                  		@factor, @shift, @emco, @equip, @matlgroup, @material, @revcode, @jctranstype, 
  						@template, @ctcategory,	@currentcategory output, @errmsg output
    					if @rcode <> 0
      						begin
  							exec @rcode = bspJBTandMTransErrors @co, @mth, @billnum, @jccdmonth, @jccdtrans, 7, @msg output
      						goto NextTrans
      						end
        			end
       			else
        			begin
        			select @currentcategory = null
  					end
  
    			select @category = @currentcategory
  
      			/* Get template seq for this JCCD record w/categories if used */
      			exec @rcode = bspJBTandMGetTemplateSeq @co, @template, @category, @jbidsource, @earntype, @liabtype,
                    	@phasegroup, @transct, @tempseq output,
                    	@seqsortlevel output, @seqsummaryopt output, @groupnum output,
                    	@seqtype output, @jctranstype, @msg output
      			if @rcode <> 0
       				begin
    				exec @rcode = bspJBTandMTransErrors @co, @mth, @billnum, @jccdmonth, @jccdtrans, 5, @msg output
    				goto NextTrans
    				end
  
     			if @seqtype = 'N'
    				BEGIN
    				exec @rcode = bspJBTandMNonbillableSeq @co, @mth, @billnum, @jccdmonth, @jccdtrans, @msg OUTPUT
    				goto NextTrans
    				end
  
      			/* Get labor rate */
      			if @seqtype <> 'N'
    				begin
    				if @jctranstype /*@jbidsource*/ = 'PR' and @ctcategory = 'L'
      				begin
					select @postedum = null, @actualecm = null

      				if @sequserates = 'R' 	--From the Template (Not 'C'ost)
    					begin
    					exec @rcode = bspJBTandMGetLaborRate @co, @template, @category,
         				@prco, @employee, @craft, @class, @shift, @earntype, @factor, 
						@actualdate, @laboreffectivedate, @sequserates output, @laborrate output,
         				@msg output

    					if @rcode <> 0
          					begin
          					exec @rcode = bspJBTandMTransErrors @co, @mth, @billnum, @jccdmonth, @jccdtrans, 2, @msg output
          					goto NextTrans
          					end
        				end
      				end
  
        			if @jctranstype = 'EM' or (@jctranstype = 'PR' and @ctcategory = 'E') --<--Not really needed, converted above
          				begin
  						/* Need to NULL @postedum and @actualunits if the Equipment RevCode is Hourly based */
  						if @revcode is null
  							begin
  							select @actualunits = 0, /*@actualhours = 0,*/ @postedum = null, @emrcbasis = null
  							end
  						else
  							begin
  							select @emrcbasis = Basis
  							from bEMRC
  							where EMGroup = @emgroup and RevCode = @revcode
  							if @emrcbasis = 'H'
  								begin
  								select @postedum = null, @actualunits = 0
  								end
  							else
  								begin
  								select @actualhours = 0
  								end
  							end
  					
  						if @equiprateopt in ('R','T')		--From the Template (not 'C'ost)
  					    	begin
  							/* if @emrcbasis = 'U'
  								begin
  								select @msg = 'Incorrect Template setup for Units Based EM RevCode'
  								exec @rcode = bspJBTandMTransErrors @co, @mth, @billnum, @jccdmonth, @jccdtrans, 3, @msg output
  								goto NextTrans
  								end
  							if @equiprateopt = 'T' and @emrcbasis is null
  								begin
  								select @msg = 'Incorrect Template setup for Missing EM RevCode'
  								exec @rcode = bspJBTandMTransErrors @co, @mth, @billnum, @jccdmonth, @jccdtrans, 3, @msg output
  								goto NextTrans
  								end	*/
  
            					exec @rcode = bspJBTandMGetEquipRate @co, @jctranstype, @template, @category,
                      			@emco, @emgroup, @equip, @revcode, @actualdate, @equipeffectivedate,
 								@sequserates output, @equiprate output, @HrsPerTimeUM output, @msg output
             				if @rcode <> 0
              					begin
              					exec @rcode = bspJBTandMTransErrors @co, @mth, @billnum, @jccdmonth, @jccdtrans, 3, @msg output
              					goto NextTrans
              					end
  
  							/* @actualunits is primarily material related EXCEPT IN THIS CASE when it becomes
  							   TIMEUNITS.  @actualunits is set here for TIMEUNITS for posting to JBIDTemp
  							   later on.  */
  							if @equiprateopt = 'T' 
  								begin
  								select @postedum = null
  								select @actualunits = case when isnull(@HrsPerTimeUM,0) = 0 then 0 else @actualhours / @HrsPerTimeUM end
  								end
            					end
          				end
        			end
  
      			if @material is not null and @actualunits <> 0
        			begin	/* Begin Material not Null group */
        			exec @rcode = bspJBTandMGetMatlRate @co, @jctranstype, @template, @tempseq, 
 						@actualunitcost, @actualecm, @category, @matlgroup, @material, @inco, @loc, 
 						@postedum, @actualdate, @matleffectivedate,	@matlrate output, @actualecm output, @msg output
  				  	if @rcode = 0
  						/* Issue #12377, If returning a material rate is successful, then proceed to
  						   initialize using the material rate accordingly.  Otherwise ActualCost from 
  						   the JC Transaction will get posted later. */
  				   		begin
  						/* bspJBTandMGetMatlRate establishes a rate based on Template Price Options,
  						   on Override table configurations, on UM comparisons, or on the 
  						   PostedUnitCost directly from JCCD.  If a Material has been used, then a MatlRate 
  						   will get established by now (Otherwise JCCD.ActualCost is used).
  					
  						   In the case of 'JC Adj':
  							MO:		There is NO Material therefore NO rate.  JCCD.ActualCost is used
  							MS:		A) If Material is used, then user should input Units and Amount.
  									   PostedUnitCost is calculated and placed in JCCD. MatlRate will exist.
  									B) If Material is not used then NO rate available.  JCCD.ActualCost is used. */
  					
  						/* Set @actualcost based on laborrates */
  						select @ecmfactor = case @actualecm
  									when 'E' then 1
  									when 'C' then 100
  									when 'M' then 1000 end
  					
  						select @actualunitcost = @matlrate,
  							@actualcost = (@matlrate/isnull(@ecmfactor,1)) * @actualunits
  						end
  					else
      					begin
  						select @msg = 'Material Rate Undefined'
      					exec @rcode = bspJBTandMTransErrors @co, @mth, @billnum, @jccdmonth, @jccdtrans, 5, @msg output
      					goto NextTrans
      					end
  					end		/* End Material not Null group */
  
  				/* Strange code.  As I understand this:
  				   @um = JCCD.UM and is ALWAYS = to JCCH.UM relative to the CostType
  				   in use.  If it isn't, then there is a problem with the module from which the
  				   JCCD transaction got posted. (Another words, @actualunits should never get
  				   set to 0). 
  				
  				   Actually this code is merely and indicator that JCCD.UM is incorrect and 
  				   nothing more.  It really should be removed all together. */
     			if @um <> 'LS' select @actualunits = case @seqsummaryopt when 1 then @actualunits
               		else case when @jcchum = @um then @actualunits else 0 end end
  
  				/* Temp Sortorder: A=Actual Date, D=Post Date, I=Contract Item,
        			   J=Job/Phase,P=Phase, S=Temp Seq*/
     			exec bspJBTandMGetLineKey @co, @phasegroup, @phase, @job, @item, @template, @tempseq ,
                  	@postdate, @actualdate, @groupnum, 'N', @linekey output, @msg output
  
  				/* Set @actualcost based on laborrates */
  				if @jctranstype = 'PR' and @ctcategory = 'L'
  					begin
  					select @actualcost = case @sequserates 			--From bJBLR or bJBLO "C", "F", "R"
  						when 'R' then @actualhours * @laborrate
  						when 'F' then (@actualhours * @laborrate) * isnull(@factor,1) 
  				      	else @actualcost end,
  					@actualunitcost = case @sequserates
  				    	when 'R' then @laborrate
  				    	when 'F' then @laborrate * isnull(@factor,1)
  				    	else case when @actualhours = 0 then 0 else @actualcost / @actualhours end end 
  					end
  
  				/* Set @actualcost based on equiprates */
  				if (@jctranstype = 'EM' and @ctcategory = 'E') or
  					(@jctranstype = 'PR' and @ctcategory = 'E')	 --<--Not really needed, converted above
   					begin
  					select @actualcost = case @equiprateopt		--From Template "C", "R", "T"
  						when 'R' then case 
  							when @sequserates = 'R' 			--From bJBER  "C", "R" only
  								then @actualhours * @equiprate
  							else @actualcost end
  						when 'T' then case 
  							when @sequserates = 'R' 
  								then case when @HrsPerTimeUM = 0 then 0 else @actualunits * @equiprate end
  							else @actualcost end	
  						else @actualcost end,
  				
  					@actualunitcost = case @equiprateopt 		--From Template "C", "R", "T"
  						when 'R' then case
  							when @sequserates = 'R'				--From bJBER  "C", "R" only
  								then @equiprate else case when @actualhours = 0 then 0 else @actualcost / @actualhours end end
  						when 'T' then case
  							when @sequserates = 'R'
  								then @equiprate else case when @actualhours = 0 then 0 else
  									case when @HrsPerTimeUM = 0 then 0 else @actualcost / @actualunits end end end
  						when 'C' then case
  							when @emrcbasis = 'H' 
  								then case when @actualhours = 0 then 0 else @actualcost / @actualhours end
  							when @emrcbasis = 'U' 
  								then case when @actualunits = 0 then 0 else @actualcost / @actualunits end 
  							when @emrcbasis is null
  								then 0 
  							else @actualunitcost end end
  					end
  
   				exec @rcode = bspJBTandMGetDetailKey @co, @jccdmonth, @jccdtrans,
                  	@jctranstype output, @seqsortlevel output, @seqsummaryopt output,
					@category output, @prco output, @employee output,
                 	@craft output, @class output, @earntype output, @factor output,
                  	@ctcategory output, @shift output, @apco output,
					@vendorgroup output, @vendor output, @apref output, @inco output,
                   	@MSticket output, @matlgroup output, @material output, @loc output,
                  	@sl output, @slitem output, @emgroup output, @equip output,
                 	@revcode output, @actualdate output, @liabtype output,
					@jccddesc output, @emco output, @transct output,
                   	@phasegroup output, @po output, @poitem output, @laborrate output, @detailkey output,
  					@postdate output, @msg output
 
				if @rcode <> 0 or @detailkey is null
					begin
					select @rcode = 1, @msg = 'Error setting the detail key'
					goto bspexit
					end

				/* Setup Pre-Bill warning. */
				if @jctranstype in ('AP', 'MT')	
					begin
					select @prebillmonth = d.BillMonth, @prebillnum = d.BillNumber, @prebillline = d.Line, 
						@prebilllineseq = d.Seq
					from bJBID d with (nolock)
					join bJBIN n with (nolock) on n.JBCo = d.JBCo and n.BillMonth = d.BillMonth and n.BillNumber = d.BillNumber
					where d.APCo = @apco and d.VendorGroup = @vendorgroup and d.Vendor = @vendor and d.PreBillYN = 'Y'
						and n.Contract = @contract

					if @@rowcount <> 0
						begin
       					select @prebillmthstr = convert(varchar(2),datepart(mm,@prebillmonth))
              				+ '/' + convert(varchar(5),right(datepart(yy,@prebillmonth),2))
       					select @msg = @prebillmthstr + ' Bill#' + convert(varchar(10),@prebillnum)
                     			+ ' Line#' + convert(varchar(10),@prebillline) + ' Seq#' +
                     			convert(varchar(10),@prebilllineseq)

						exec @rcode = bspJBTandMTransErrors @co, @mth, @billnum, @jccdmonth, 
							@jccdtrans, 10, @msg output
						select @msg = null
						end
    				end
  
  				/* Get Item specific info for item specific Markup values related to 'S'ource lines. 
  				   Issue #21714 */
  				select @taxgroup = TaxGroup, @taxcode = TaxCode, 
  					@jccimarkuprate = MarkUpRate
  				from bJCCI with (nolock)
  				where JCCo = @co and Contract = @contract and Item = @item
  		
  				if @taxcode is not null
  					begin
  				  	exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,
  				    	@taxrate output, @msg = @msg output
  				   	end
  		
  		       	select @markupopt = MarkupOpt, 
  					@markuprate = case MarkupOpt
  						--  when 'R'	(Not valid for 'S' sequences)
  							when 'T' then case when @taxcode is not null then @taxrate 
  								else MarkupRate end 
  							when 'X' then case when @taxcode is not null then @taxrate 
  								else MarkupRate end 
  						--  when 'D'	(Not valid for 'S' sequences)
  							when 'S' then case when isnull(@jccimarkuprate,0) <> 0 then
  								case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
  								else MarkupRate end
  							else MarkupRate end
  		       	from JBTS with (nolock)
  		       	where JBCo= @co and Template = @template and Seq = @tempseq 
  
				if not exists(select 1 from bJBIDTMWork 
					where JBCo = @co and JCMonth = @jccdmonth and JCTrans = @jccdtrans)
					/* Only if this CostTrans Mth/CostTrans is not already in processing by another user. */
					begin
					/* All values have determined for this Source CostTrans.  Insert these values into
					   Work table.  They will be accumulated and inserted into bJBIJ later on. */
					insert bJBIDTMWork (JBCo, VPUserName, Contract, Item, TemplateSeq,
						TemplateSeqType, DetailKey, Source, PhaseGroup, Phase, CostType,
						CostTypeCategory, PRCo, Employee, EarnType, Craft, Class, Factor, Shift,
						LiabilityType, APCo, VendorGroup, Vendor, APRef, INCo, MSTicket, MatlGroup, Material,
						Location, StdUM, StdPrice, StdECM, SL, SLItem, PO, POItem,
						EMCo, EMGroup, Equipment, RevCode,  
						JCMonth, JCTrans, ActualDate,
						PostDate,Category,Description,
						UM, Units,
						UnitPrice,
						ECM, Hours,
						SubTotal,
						MarkupOpt,
						MarkupRate,
						MarkupAddl,
						MarkupTotal, Retainage,
						Total,
						Template, TemplateSortLevel, TemplateSeqSumOpt, TemplateSeqGroup,
						Job, LineKey, AppliedToSeq, LineType,Discount, CustGroup, Customer,
						TemplateSeqPriceOpt, JCCDMatlGrp, JCCDMaterial, JCCDInco, JCCDLoc,
						JCCDEMGroup, JCCDEquip, JCCDRevCode)

					select @co, SUSER_SNAME(), @contract, @item, @tempseq,
						@seqtype, @detailkey, @jctranstype /*@jbidsource*/, @phasegroup, @phase, @transct,
						@ctcategory, @prco, @employee, @earntype, @craft, @class, @factor, @shift,
						@liabtype, @apco, @vendorgroup, @vendor, @apref, @inco, @MSticket, @matlgroup, @material,
						@loc, @um, isnull(@stdprice,0), @stdecm, @sl, @slitem, @po, @poitem,
						@emco, @emgroup, @equip, @revcode, 
						@jccdmonth, @jccdtrans, @actualdate,
						@postdate, @category, @jccddesc,
						@postedum,
							--case @jctranstype when 'IN' then @postedum 
						--					when 'MS' then @postedum	
						--					when 'MT' then @postedum
						--					when 'MI' then @postedum
						--				else @um end, 
						isnull(@actualunits,0),				--either MaterialUnits or TimeUnits
						isnull(@actualunitcost,0),
						@actualecm,
						case @jctranstype when 'PR' then @actualhours when 'EM'then @actualhours else 0 end,
						isnull(@actualcost,0),
						@markupopt,														 -- Issue #21714: Changed from MarkupOpt,
						isnull(@markuprate,0),											 -- Issue #21714: Changed from isnull(MarkupRate,0),
						AddonAmt,
						case @markupopt  												 --	Issue #21714: Changed from MarkupOpt
							when 'S' then (isnull(@markuprate,0)*isnull(@actualcost,0))	 -- Issue #21714: Changed from MarkupRate
						when 'U' then (isnull(@markuprate,0)*isnull(@actualunits,0)) -- Issue #21714: Changed from MarkupRate
							else 0 end,0,
						isnull(@actualcost,0) + case @markupopt  						 -- Issue #21714: Changed from MarkupOpt
						when 'S' then (isnull(@markuprate,0)*isnull(@actualcost,0))  -- Issue #21714: Changed from MarkupRate  
						when 'U' then (isnull(@markuprate,0)*isnull(@actualunits,0)) -- Issue #21714: Changed from MarkupRate  
						else 0 end,
						@template, SortLevel, SummaryOpt, GroupNum,
						@job, @linekey, @tempseq,'S',0, @custgroup, @customer,
						PriceOpt, @jccdmatlgrp, @jccdmaterial, @jccdinco, @jccdloc, 
						@jccdemgroup, @jccdequip, @jccdemrevcode
					from bJBTS with (nolock)
					where JBCo = @co and Template = @template and Seq = @tempseq
					end
				  
       		NextTrans:
  				fetch next from bcJCMthTrans into @jccdmonth, @jccdtrans
     			end		/* End JC Mth/Trans Loop - First */
  
  			if @openjcmthtranscursor = 1
  				begin
  				close bcJCMthTrans
  				deallocate bcJCMthTrans
  				select @openjcmthtranscursor = 0
  				end
			 
  			fetch next from bcJobPhase into @job, @phase
     		end		/* End Job/Phase Loop */
  
  		if @openjobphasecursor = 1
  			begin
  			close bcJobPhase
  			deallocate bcJobPhase
  			select @openjobphasecursor = 0
  			end
  
   		/* Now process Amount lines */
   		exec @rcode = bspJBTandMProcessAmtforInit @co, @template, @contract, @item,	@itembillgroup, @msg output
  		if @rcode <> 0	--(Will be 10, 11, 99)
  			begin
  			select @errordesc = 'Error creating Amount Lines - ' + @msg, @errornumber = 110, @rcode = 0
  			goto BillError
  			end
  
  		fetch next from bcItem into @item
   		end		/* End JCJP Item Loop */
  
  	if @openitemcursor = 1
  		begin
  		close bcItem
  		deallocate bcItem
  		select @openitemcursor = 0
  		end
/******************************** END JC TRANSACTION PROCESSING BY ITEM ******************************/

----  	/********** SPECIAL CODE:  OCCURS WHEN JCCD TRANSACTION DO NOT EXIST. SEE BELOW ***********/
---- REM'D 08/01/08:  Field Centrix (Contract with no Job Cost) IS A DEAD PROJECT
----  	/* If no JC Detail exists for this contract and an 'Amount' sequence does exist on the
----  	   template, then the following code is required in order to generate a bill using the
----  	   'Amount' sequence.  If detail does exist, then this all occurs above and the following
----  	   will be skipped.  (REQUIRED for Field Centrix in Particular) */
----  	if @contnocost = 'Y' and exists(select 1 from bJBTS with (nolock) where JBCo = @co and Template = @template
----  							and Type = 'A')
----  		begin	/* Begin Contract - No Cost loop */
----  		if @billnum is null
----  			begin	
----   			if @assigninvYN = 'Y'
----     			begin
----  				/* Automatically Assign Invoice number from either JBCO or ARCO */
----  				exec @rcode = bspJBGetLastInvoice @co, @invoice output, @msg output
----  				if @rcode <> 0
----  					begin
----  					select @msg = 'Error getting next invoice #.  ' + @msg
----   					select @errordesc = @msg, @errornumber = 107, @rcode = 0
----  					goto BillError
----  					end
----     			end
----  
----			/* Since we cannot retrieve Item from JCJP, get the first item from JCCI
----			   to process this 'Amount' sequence against */
----			select @item = min(Item)
----			from bJCCI with (nolock)
----			where JCCo = @co and Contract = @contract
----  
------   			if exists(select 1 from bJCCI with (nolock) where JCCo = @co and Contract = @contract and BillType = 'B')
------ 				begin
------ 				select @billtype = 'B'
------ 				end
------  			else
------ 				begin
------ 				select @billtype = 'T'
------ 				end
----			select @billtype = 'T'				--'B' bill headers now get initialized from bspJBProgressBillInit
----  
----   			if @contract is not null
----       			begin
----       			select @application = isnull(max(Application),0) + 1
----      	 		from bJBIN with (nolock)
----        		where JBCo = @co and Contract = @contract
----       			end
----     		else
----       			begin
----       			select @application = null
----       			end
----  
----  			if @billtype = 'B' and @application is not null
----  				begin
----  				select @invappdesc = 'JB App# ' + convert(varchar(5), @application)
----  				end
----  			else
----  				begin
----  				select @invappdesc = null
----  				end
----  			Begin Tran --121063, 120700
----   			select @billnum = isnull(max(BillNumber),0) + 1
----   			from bJBIN
----   			where JBCo = @co and BillMonth = @mth
----  
----   			insert bJBIN (JBCo,BillMonth,BillNumber,Invoice,Contract,CustGroup,
----                	Customer,InvStatus,Application,ProcessGroup,RestrictBillGroupYN,
----                	BillGroup,RecType,DueDate,InvDate,PayTerms,DiscDate,FromDate,
----                	ToDate,BillAddress,BillAddress2,BillCity,BillState,BillZip,BillCountry,
----                	ARTrans,InvTotal,InvRetg,RetgRel,InvDisc,TaxBasis,InvTax,
----                	InvDue,PrevAmt,PrevRetg,PrevRRel,PrevTax,PrevDue,ARRelRetgTran,
----                	ARRelRetgCrTran,ARGLCo,JCGLCo,CurrContract,PrevWC,WC,PrevSM,
----                	Installed,Purchased,SM,SMRetg,PrevSMRetg,PrevWCRetg,WCRetg,
----                	PrevChgOrderAdds,PrevChgOrderDeds,ChgOrderAmt,AutoInitYN,
----                	InUseBatchId,InUseMth,Notes,BillOnCompleteYN,BillType,Template,
----                	CustomerReference,CustomerJob,ACOThruDate,Purge,AuditYN,
----                	OverrideGLRevAcctYN,OverrideGLRevAcct,
----  				InvDescription, TMUpdateAddonYN,CreatedBy,CreatedDate,InitOption)
----    		select @co, @mth, @billnum,@invoice,@contract,@custgroup,@customer,
----           		'A',@application,@procgroup,@restrictbillgroupYN, @itembillgroup, @rectype,
----           		@duedate, @invdate, @payterms, @discdate,
----           		@begindate,@enddate,@billaddress,@billaddress2,@billcity,
----           		@billstate,@billzip,@billcountry,null, 0,0,0,0,0,0,0,0,0,0,0,0,
----           		null,null,@arglco,@jcglco,0,
----           		0,0,0,0,0,0,0,0,0,0,0,0,0,
----           		'Y',null,null,null,'N',@billtype/*'T'*/,@template,null,
----
----           		null,@acothrudate,'N','Y','N',null,
----  				case @billtype when 'T' then isnull(@invdescription, isnull(@customerref,'JB T&M'))
----  					else isnull(@invdescription, isnull(@invappdesc, isnull(@customerref,'JB T&M'))) end,
---- 				'N', SUser_Name(), convert(varchar, GetDate(), 1), @billinitopt
----			commit tran --121063, 120700
----    		end		/* End BillNum Null Loop */
----  
----   		/* Now process Amount lines */
----   		exec @rcode = bspJBTandMProcessAmtforInit @co, @template, @contract, @item,	@msg output
----  		if @rcode <> 0	--(Will be 10, 11, 99)
----  			begin
----  			select @errordesc = 'Error creating Amount Lines - ' + @msg, @errornumber = 110, @rcode = 0
----  			goto BillError
----  			end
----  
----  		end		/* End Contract - No Cost loop */
----  		/********************** END SPECIAL CODE, NO COST PROCESSING ******************************/
  
/**************** BEGIN DETAIL ADDON PROCESSING.  STATIC VALUES AND 0.00 DOLLAR VALUES WILL BE PLACED IN WORK TABLE INITIALLY *************/

  	/* Now process 0.00 value detail addons.  This procedure was originally intended to generate Detail
  	   Addon dollar values as well as Static values.  Today however it simply serves to 
  	   populate the bJBIDTMWork table with Static values (ie: Contract, ContractItem and more)
  	   and allows this routine to place zero value 'D'etail Addon Lines into bJBIL later on. 
  
  	   If reviewing this procedure, remember that effectively all dollar values are updated
  	   at the end of this procedure by running bspJBTandMUpdateSeqAddons at the last minute. */
  	exec @rcode = bspJBTandMProcessDetAddons @co, @mth, @billnum, @template, @invdate, 
  		@contract, @msg output
/**************************************** END DETAIL ADDON PROCESSING. ****************************************/ 

/************* BEGIN ADDING INITIAL, ZERO VALUE JBIL RECORD FOR SOURCE, DETAIL AND TOTAL ADDONS ***************/
  
	/* Add JBIL record
       spin thru bJBIDTMWork in linekey order. All bJBIDTMWork records with the same linekey will
       be added as one line*/
  	declare bcLineKey cursor local fast_forward for
 	select LineKey
 	from bJBIDTMWork with (nolock)
 	where TemplateSeq is not null and JBCo = @co and VPUserName = SUSER_SNAME()
  	group by LineKey
	order by LineKey	--Issue #123161, Incorrect Sort Order at Line Level

  	open bcLineKey
  	select @openlinekeycursor = 1
  
  	fetch next from bcLineKey into @linekey
  	while @@fetch_status = 0
       	begin	/* Begin LineKey Loop */
       	select @appliedtoseq = AppliedToSeq, @tempseq = TemplateSeq, @seqtype = LineType
       	from bJBIDTMWork with (nolock)
       	where LineKey = @linekey and LineType in ('S','A') and AppliedToSeq is not null
  			 and JBCo = @co and VPUserName = SUSER_SNAME() 
  		group by LineKey, AppliedToSeq, TemplateSeq, LineType, MarkupAddl
  
  		/* If for some reason JBIN Bill header has not yet been added, then it will be 
  		   added now.  I doubt that this code ever runs. It could probably be removed
  		   though it is harmless. */
       	if @billnum is null
     		begin	/* Begin 2nd BillNum Null Loop */
     		if @assigninvYN = 'Y'
       			begin
 				/* Automatically Assign Invoice number from either JBCO or ARCO */
 				exec @rcode = bspJBGetLastInvoice @co, @invoice output, @msg output
 				if @rcode <> 0
 					begin
 					select @msg = 'Error getting next invoice #.  ' + @msg
 					select @errordesc = @msg, @errornumber = 107, @rcode = 0
 					goto BillError
 					end
       			end
  
--         	if exists(select 1 from bJCCI with (nolock) where JCCo = @co and Contract = @contract and BillType = 'B')
--				begin
--				select @billtype = 'B'
--				end
--			else
--         		begin
--				select @billtype = 'T'
--				end
			select @billtype = 'T'				--'B' bill headers now get initialized from bspJBProgressBillInit
  
         	if @contract is not null
           		begin
           		select @application = isnull(max(Application),0) + 1
          	 	from bJBIN with (nolock)
            		where JBCo = @co and Contract = @contract
           		end
			else
           		begin
           		select @application = null
           		end
  
  			if @billtype = 'B' and @application is not null
  				begin
  				select @invappdesc = 'JB App# ' + convert(varchar(5), @application)
  				end
  			else
  				begin
  				select @invappdesc = null
  				end
  			Begin Tran --121063, 120700
     		select @billnum = isnull(max(BillNumber),0) + 1
     		from bJBIN
     		where JBCo = @co and BillMonth = @mth
  
     		insert bJBIN (JBCo,BillMonth,BillNumber,Invoice,Contract,CustGroup,
 	         	Customer,InvStatus,Application,ProcessGroup,RestrictBillGroupYN,
 	         	BillGroup,RecType,DueDate,InvDate,PayTerms,DiscDate,FromDate,
 	          	ToDate,BillAddress,BillAddress2,BillCity,BillState,BillZip,BillCountry,
 	           	ARTrans,InvTotal,InvRetg,RetgRel,InvDisc,TaxBasis,InvTax,
 	           	InvDue,PrevAmt,PrevRetg,PrevRRel,PrevTax,PrevDue,ARRelRetgTran,
 	           	ARRelRetgCrTran,ARGLCo,JCGLCo,CurrContract,PrevWC,WC,PrevSM,
 	           	Installed,Purchased,SM,SMRetg,PrevSMRetg,PrevWCRetg,WCRetg,
 	          	PrevChgOrderAdds,PrevChgOrderDeds,ChgOrderAmt,AutoInitYN,
 	           	InUseBatchId,InUseMth,Notes,BillOnCompleteYN,BillType,Template,
 	           	CustomerReference,CustomerJob,ACOThruDate,Purge,AuditYN,
 	           	OverrideGLRevAcctYN,OverrideGLRevAcct,
 				InvDescription,TMUpdateAddonYN,CreatedBy,CreatedDate,InitOption)
          	select @co, @mth, @billnum,@invoice,@contract,@custgroup,@customer,
            	'A',@application,@procgroup,@restrictbillgroupYN,@itembillgroup, @rectype,
            	@duedate,@invdate,@payterms,@discdate,
            	@begindate,@enddate,@billaddress,@billaddress2,@billcity,
            	@billstate,@billzip,@billcountry,null, 0,0,0,0,0,
            	0,0,0,0,0,0,0,
            	null,null,@arglco,@jcglco,0,
            	0,0,0,0,0,0,0,0,
            	0,0,0,0,0,
               	'Y',null,null,null,'N',@billtype/*'T'*/,@template,null,
               	null,@acothrudate,'N','Y','N',null,
  				case @billtype when 'T' then isnull(@invdescription, isnull(@customerref,'JB T&M'))
  					else isnull(@invdescription, isnull(@invappdesc, isnull(@customerref,'JB T&M'))) end,
 				'N', SUser_Name(), convert(varchar, GetDate(), 1), @billinitopt
			commit tran --121063, 120700
          	end		/* End 2nd BillNum Null Loop */
  
		Begin Tran --121063, 120700
    	select @line = isnull(max(Line),0) + 10
    	from bJBIL
    	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
  
		/* Insert 0.00 value Source JBIL record. */
    	insert JBIL (JBCo, BillMonth, BillNumber, Line,
       	MarkupRate, Basis, MarkupAddl, MarkupTotal, Total, Retainage, Discount,
        	LineType, Template, TemplateSeq, LineKey, AuditYN)
    	select @co, @mth, @billnum, @line,
        	0,0,0,0,0,0,0,
        	@seqtype /*'S'*/, @template, @tempseq, @linekey, 'N'
		commit tran --121063, 120700

  		/* Get the detailkey for the linekey record and then update bJBIDTMWork with what
  	  	   line it will be in JBIL. This way we can just add the JBID record off of bJBIDTMWork
  	       with the line # the JBID corresponds to with JBIL */
  		declare bcDetailKey cursor local fast_forward for
       	select DetailKey
       	from bJBIDTMWork with (nolock)
       	where LineKey = @linekey and LineType in ('A','S') and JBCo = @co and VPUserName = SUSER_SNAME()
  		group by DetailKey
  
  		open bcDetailKey
  		select @opendetailkeycursor = 1
  
  		fetch next from bcDetailKey into @detailkey
  		while @@fetch_status = 0	
  			begin	/* Begin DetailKey Loop - First */
			update bJBIDTMWork 
  			set Line = @line
       		from bJBIDTMWork with (nolock) 
  			where LineKey = @linekey and DetailKey = @detailkey and LineType in ('A','S')
  				 and JBCo = @co and VPUserName = SUSER_SNAME()
  
  			fetch next from bcDetailKey into @detailkey
         	end		/* End DetailKey Loop - First */
  
  		if @opendetailkeycursor = 1
  			begin
  			close bcDetailKey
  			deallocate bcDetailKey
  			select @opendetailkeycursor = 0
  			end
  
  		/* Begin processing zero value JBIL records for Detail Addons.  This process is best
  		   done at this time in order to maintain Line Number consistency between Source
  		   and Detail Addon Line numbering. */
  		declare bcDetAddon cursor local fast_forward for	
       	select AddonSeq
       	from bJBIDTMWork with (nolock)
  		where LineKey = @linekey and LineType = 'D' and JBCo = @co and VPUserName = SUSER_SNAME()
  		group by AddonSeq
  
  		open bcDetAddon
  		select @opendetaddoncursor = 1
  
  		fetch next from bcDetAddon into @addonseq
  		while @@fetch_status = 0
  			begin	/* Begin Zero value JBIL record for Detail Addon Loop */
			Begin Tran --121063, 120700
     		select @lineforaddon = min(Line)
     		from bJBIL with (nolock)
     		where LineType in ('S','A') and LineKey = @linekey and JBCo = @co and BillMonth = @mth and BillNumber = @billnum

     		select @line = isnull(max(Line),0) + 10
     		from bJBIL
    		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
  
     		/* Insert Zero value JBIL Detail Addon record. */
     		insert JBIL (JBCo, BillMonth, BillNumber, Line,
           		MarkupRate, Basis, MarkupAddl, MarkupTotal, Total, Retainage, Discount,
				LineType, Template, TemplateSeq, LineKey, LineForAddon, AuditYN)
     		select @co, @mth, @billnum, @line,
				0,0,0,0,0,0,0, 'D', @template, @addonseq /*@tempseq*/, @linekey, @lineforaddon, 'N'
 
     		update bJBIDTMWork
     		set Line = @line, LineForAddon = @lineforaddon
     		from bJBIDTMWork with (nolock)
     		where LineKey = @linekey and LineType = 'D' and TemplateSeq = @addonseq		--@tempseq
 				 and JBCo = @co and VPUserName = SUSER_SNAME()
  			commit tran --121063, 120700 

  			fetch next from bcDetAddon into @addonseq
			end		/* End Zero value JBIL record for Detail Addon Loop */
  
  		if @opendetaddoncursor = 1
  			begin
  			close bcDetAddon
  			deallocate bcDetAddon
  			select @opendetaddoncursor = 0
  			end
    
	NextLineKey:
  		fetch next from bcLineKey into @linekey
       	end		/* End LineKey Loop */
  
  	if @openlinekeycursor = 1
  		begin
  		close bcLineKey
  		deallocate bcLineKey
  		select @openlinekeycursor = 0
  		end
/************* END ADDING INITIAL, ZERO VALUE JBIL RECORD FOR SOURCE, DETAIL AND TOTAL ADDONS ***************/
  
/***************** BEGIN UPDATING JBIL NOW WITH VARIOUS VALUES RETRIEVED FROM WORK TABLE ********************/
  
  	declare bcLine cursor local fast_forward for
  	select Line
  	from bJBIDTMWork with (nolock)
  	where JBCo = @co and VPUserName = SUSER_SNAME()
  	group by Line
  
  	open bcLine
  	select @openlinecursor = 1
  
  	fetch next from bcLine into @line
  	while @@fetch_status = 0
  		begin 	/* Begin Line Loop - First */
  		/* Rem'd per Issue #21714 
       	select @tempseq = TemplateSeq 
   		from #JBIDTemp 
   		where Line = @line and JBCo = @co and VPUserName = SUSER_SNAME() */
  
     	/* Get info that will be updated to the line. */
       	select @item = Item, @job = case @tempsortorder when 'J' then Job else null end,
          	@linephasegroup = case when @tempsortorder = 'P' or @tempsortorder = 'J' then PhaseGroup else null end,
          	@linephase = case when @tempsortorder = 'P' or @tempsortorder = 'J' then Phase else null end,
           	@linedate = case @tempsortorder when 'A' then ActualDate when 'D' then PostDate else null end,
			@seqgroup = TemplateSeqGroup,
           	@seqsortlevel = TemplateSortLevel, @seqsummaryopt = TemplateSeqSumOpt,
           	@subtot = sum(SubTotal), @seqtype = TemplateSeqType,
           	@appliedtoseq = AppliedToSeq					--, @retainage  =  sum(Retainage)
      	from bJBIDTMWork with (nolock)
       	where Line = @line and JBCo = @co and VPUserName = SUSER_SNAME()
      	group by Line, Item, Job, PhaseGroup,
          	Phase, ActualDate, PostDate, TemplateSeqGroup, TemplateSortLevel,
           	TemplateSeqSumOpt, TemplateSeqType, AppliedToSeq, LineType
  
  		/* Per Issue #21714: The values retrieved here from bJBTS have either already been placed 
  		   into bJBIDTMWork (In the case of 'S'ource and 'A' sequences ) or will get placed into JBIL 
  		   later (In the case of 'D'etail and 'T'otal addons).  in the case of 'S'ource sequences, to 
  		   update bJBIL with values from bJBTS at this point, may overwrite a desired value with an incorrect one. */
  
  		/* Rem'd Issue #21714.  
  		select @linedesc = Description , @markupopt = MarkupOpt, @markuprate = MarkupRate,
          	@addonamt = AddonAmt
      	from JBTS with (nolock)
       	where JBCo= @co and Template = @template and Seq = @tempseq */
  
      	/* Update JBIL with info from bJBIDTMWork */
       	update bJBIL
      	set Contract = @contract, Description = s.Description,	-- Issue #21714: Changed from @linedesc,
          	MarkupOpt = d.MarkupOpt,				-- Issue #21714: Changed from @markupopt, 
			MarkupRate = d.MarkupRate,				-- Issue #21714: Changed from isnull(@markuprate,0), 
  			MarkupAddl = d.MarkupAddl,				-- Issue #21714: Changed from isnull(@addonamt,0), 
  			MarkupTotal = d.MarkupAddl,				-- Issue #21714: Changed from isnull(@addonamt,0),
  			Total = d.MarkupAddl,					-- Issue #21714: Changed from isnull(@addonamt,0),
  			Item = @item, Job = @job, PhaseGroup = @linephasegroup, Phase = @linephase, Date = @linedate,
           	TemplateSeqGroup = @seqgroup, TemplateSortLevel = @seqsortlevel,
           	TemplateSeqSumOpt = @seqsummaryopt,
           	/*Retainage = @retainage,*/ TaxGroup = d.TaxGroup, TaxCode = d.TaxCode,
  			AuditYN = 'N'
       	from bJBIDTMWork d with (nolock)
       	join bJBIL l with (nolock) on l.Line = d.Line
  		join bJBTS s with (nolock) on s.JBCo = l.JBCo and s.Template = l.Template and s.Seq = l.TemplateSeq
     	where l.JBCo = @co and l.BillMonth = @mth and l.BillNumber = @billnum and d.Line = @line
  			 and d.JBCo = @co and d.VPUserName = SUSER_SNAME()
  
  		fetch next from bcLine into @line
       	end		/* End Line Loop - First */
  
  	if @openlinecursor = 1
  		begin
  		close bcLine
  		deallocate bcLine
  		select @openlinecursor = 0
  		end
/***************** END UPDATING JBIL NOW WITH VARIOUS VALUES RETRIEVED FROM WORK TABLE ********************/

/************ NOW UTILIZING ACCUMULATED VALUES FROM THE WORK TABLE, BEGIN INSERTING RECORDS **************/
/************ INTO JBIJ.  THESE INSERTS WILL CAUSE TRIGGER UPDATES TO JBID, JBIL, JBIT/JBIN ETC. **************/
  
  	declare bcLine cursor local fast_forward for
  	select Line
  	from bJBIDTMWork with (nolock)
  	where LineType not in ('T','D') and JBCo = @co and VPUserName = SUSER_SNAME()
  	group by Line
	order by Line		--Issue #123161, Incorrect Sort Order at Line Level

  	open bcLine
  	select @openlinecursor = 1
  
  	fetch next from bcLine into @line
  	while @@fetch_status = 0
  		begin	/* Begin Line Loop - Second */
  		/* We want JCMonth and JCTrans in JBID ONLY when SeqSumOpt = 1,
  		   Full Detail. Currently this seems to be handled though it is not obvious how.
  		   Left this here Just In Case something shows up. */
  		--select @seqsummaryopt = TemplateSeqSumOpt
  		--from bJBIDTMWork with (nolock)
         	--where Line = @line and JBCo = @co and VPUserName = SUSER_SNAME()		
  		/* TJL, Rough Translation: Set JBIDSeq values for those lines containing a DetailKey.  
  		   Only those lines generated directly from a JCCD transactions get DetailKeys, 
  		   in effect only 'S' linetypes. Multiple JCCD transactions, from different 
  		   sources ('AP', JC' etc.), from different Mths may be part of the same JBIL line
  		   if they were assigned to the same TempSeq.  Also different JBIL Line numbers
  		   may get generated for the same TempSeq dependent upon the Template Sort Order.
  	 	   The result relative to JBID is:
  		   1)  A group of Transactions (Say Source PR for Employee #32, Craft-CARP, Class-JRNY) 
  			   will get a unique JBID LineSeq #10 (And unique DetailKey - both based on 
  			   TemplateSummaryOpt settings) even though it shares
  			   the same JBIL Line #110 with another group of transactions for a different
  			   Employee. (Source PR, Employee #2, Craft, Class)
  		   2)  It is possible for these two groups of transactions to share the same
  			   JBIL line #110 because they fall into the same Template Sort Order and 
  			   Temp Seq#. 
  		   3)  In this example, you ask why give a Unique JBIDSeq# when a Unique DetailKey
  			   already exists for the same group of Transactions?  The answer: JBID LineSeq#
  			   becomes important in both JBID and JBIJ when identifying specific records.
  		   Are we confused yet?? */
  
  		declare bcDetailKey cursor local fast_forward for
      	select DetailKey
     	from bJBIDTMWork with (nolock)
      	where Line = @line and DetailKey <> 'none' and JBCo = @co and VPUserName = SUSER_SNAME()
  		group by DetailKey
		order by DetailKey		--Issue #123161, Incorrect Sort Order at Line Level

  		open bcDetailKey
  		select @opendetailkeycursor = 1
  
  		fetch next from bcDetailKey into @detailkey
  		while @@fetch_status = 0
  			begin	/* Begin DetailKey Loop - Second */
           	select @jbidseq = isnull(max(JBIDSeq),0) + 10	--1 when testing Issue #135506
           	from bJBIDTMWork with (nolock)
           	where Line = @line and JBCo = @co and VPUserName = SUSER_SNAME()
  
  			/* Update work table with JBIDSeq value */
           	update bJBIDTMWork
           	set JBIDSeq = @jbidseq
           	where Line = @line and DetailKey = @detailkey and JBCo = @co and VPUserName = SUSER_SNAME()
  
  			/* TJL, I dont see the value of this code since we are just looping thru
  			   line numbers, looking for DetailKeys (Contract Transactions) and 
  			   setting a JBIDSeq numbers. We then move on to the next DetailKey and
  			   do not use @tempseq before moving on. */         	
  			--select @tempseq = TemplateSeq
           	--from bJBIDTMWork with (nolock)
           	--where Line = @line and DetailKey = @detailkey and JBIDSeq = @jbidseq and JBCo = @co and VPUserName = SUSER_SNAME()
  
  			fetch next from bcDetailKey into @detailkey
           	end		/* End DetailKey Loop - Second */
  
  		if @opendetailkeycursor = 1
  			begin
  			close bcDetailKey
  			deallocate bcDetailKey
  			select @opendetailkeycursor = 0
  			end
 
  		/* TJL, I dont think 'and LineType' is necessary since JBIDSeq# exists only for DetailKeys
  		   which exist only relative to JCCD transactions which can only contain
  		   LineType 'S'. */ 
  		declare bcJBIDSeq cursor local fast_forward for
  		select JBIDSeq
  		from bJBIDTMWork with (nolock)
  		where Line = @line and LineType not in ('T','D','A') and JBCo = @co and VPUserName = SUSER_SNAME()
  		group by JBIDSeq
		order by JBIDSeq		--Issue #123161, Incorrect Sort Order at Line Level

  		open bcJBIDSeq
  		select @openjbidseqcursor = 1
  
  		fetch next from bcJBIDSeq into @jbidseq
  		while @@fetch_status = 0
  			begin	/* Begin JBIDSeq Loop */
  
  					/*********************************************************************/
  					/*  Process each CostTrans in work table - Insert 1 for 1 into bJBIJ */
  					/*********************************************************************/
  
  			declare bcJCMthTrans cursor local fast_forward for	
  			select JCMonth, JCTrans
  			from bJBIDTMWork with (nolock)
  			where JBIDSeq =@jbidseq and Line = @line and JBCo = @co and VPUserName = SUSER_SNAME()
  			group by JCMonth, JCTrans
  			
  			open bcJCMthTrans
  			select @openjcmthtranscursor = 1
  
  			fetch next from bcJCMthTrans into @jccdmonth, @jccdtrans
  			while @@fetch_status = 0
  				begin	/* Begin JC Mth/Trans Loop - Second */	
             	select @actualhours = Hours, @actualunits = Units, @actualunitcost = UnitPrice,
					@subtotal = SubTotal, @total = Total,
					/* @markuptot = MarkupTotal, */ @markuprate = MarkupRate,
					@markupaddl = MarkupAddl, @markupopt = MarkupOpt,
					@jbidseq = JBIDSeq, @linekey = LineKey, 
  					@jctranstype = Source, @ctcategory = CostTypeCategory,
  					@priceopt = TemplateSeqPriceOpt, @postedum = UM, @template = Template,
  					@jccdmatlgrp = JCCDMatlGrp, @jccdmaterial = JCCDMaterial, @jccdinco = JCCDInco,
  					@jccdloc = JCCDLoc, @jccdemgroup = JCCDEMGroup, @jccdequip = JCCDEquip, 
  					@jccdemrevcode = JCCDRevCode
         		from bJBIDTMWork with (nolock)
         		where Line = @line and JBIDSeq =@jbidseq and
					JCMonth = @jccdmonth and JCTrans = @jccdtrans and JBCo = @co and VPUserName = SUSER_SNAME()
  
  				/* TJL, This is alittle confusing.  We need to update bJBID for all transactions
  				   for a given JBIDSeq number.  However, this insert statement will only
  				   effect bJBID on the first transaction for this JBIDSeq Number.  How does
  				   JBID get updated for each subsequent Transaction?  Answer:  As the
  				   following bJBIJ inserts occur, the bJBIJ insert trigger will update
  				   bJBID accordingly.  (bJBIJ maintains a 1 to 1 relationship with bJCCD). 
  
  				   Also values inserted from bJBIDTMWork may be NULL even though their value
  				   coming from bJCCD was not.  This is because, when a DetailKey is retrieved,
  				   at that time, the SeqSummaryOpt is checked. Based on it, the original
  				   value may be reset to NULL before inputting into bJBIDTMWork. */
         		if not exists(select 1
                       from bJBID with (nolock)
                       where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
                             and Line = @line and Seq = @jbidseq)
             		begin
					Begin Tran --121063, 120700
               		insert bJBID (JBCo, BillMonth, BillNumber, Line, Seq, Source,
                  		PhaseGroup, CostType, CostTypeCategory,PRCo,Employee, EarnType,
                       	Craft, Class, Factor, Shift, LiabilityType, APCo, VendorGroup,
						Vendor, APRef, PreBillYN, INCo, MSTicket, MatlGroup, Material,
						Location, StdUM, StdPrice, StdECM, Hours, SL, SLItem,
                       	PO, POItem, EMCo, EMGroup, Equipment, RevCode, 
  						JCMonth,
  						JCTrans, 
  						JCDate,	Category, Description, UM, Units, UnitPrice, ECM,SubTotal,
						MarkupRate, MarkupAddl, MarkupTotal, Total, Template,
                      	TemplateSeq, TemplateSortLevel, TemplateSeqSumOpt,
						TemplateSeqGroup, DetailKey, AuditYN)
               		select @co, @mth, @billnum, Line, @jbidseq,
                      	case when Source in ('SL','MT') then 'AP' else Source end,
                      	PhaseGroup, CostType, CostTypeCategory, PRCo, Employee, EarnType,
                      	Craft, Class, Factor, Shift, LiabilityType, APCo, VendorGroup,
                      	Vendor, APRef, 'N',INCo, MSTicket, MatlGroup, Material,
                      	Location, StdUM, StdPrice, StdECM, 0 /*Hours*/, SL, SLItem,
                      	PO, POItem, EMCo, EMGroup, Equipment, RevCode,
  						--case @seqsummaryopt when 1 then JCMonth else null end, 	-- Seems to work without this.  JIC
  						JCMonth,
  						--case @seqsummaryopt when 1 then JCTrans else null end, 	-- Seems to work without this.  JIC
  						JCTrans, 
  						ActualDate, Category, Description, UM, 0 /*Units*/, 0 /*UnitPrice*/, ECM, 0 /*sum(SubTotal)*/,
                      	isnull(MarkupRate,0), 0 /*sum(MarkupAddl)*/, 0 /*sum(MarkupTotal)*/,
                      	0 /*sum(Total)*/,
                      	Template, TemplateSeq, TemplateSortLevel, TemplateSeqSumOpt,
                      	TemplateSeqGroup, DetailKey,'N' 
  					from bJBIDTMWork with (nolock) 
  					where Line = @line and JBIDSeq = @jbidseq and JCMonth = @jccdmonth
                      	and JCTrans = @jccdtrans and JBCo = @co and VPUserName = SUSER_SNAME()
                		group by Line, Source, PhaseGroup, CostType, CostTypeCategory,
                       	PRCo, Employee, EarnType, Craft, Class, Factor, Shift, LiabilityType, APCo,
                    	VendorGroup, Vendor, APRef, INCo, MSTicket, MatlGroup, Material,
                     	Location, StdUM, StdPrice, StdECM, Hours, SL, SLItem, EMCo,
                    	EMGroup, Equipment, RevCode, JCMonth, JCTrans, ActualDate,
                    	Category, Description, UM, Units, UnitPrice, ECM,
                    	Template, TemplateSeq, TemplateSortLevel, TemplateSeqSumOpt,
                    	TemplateSeqGroup, PO, POItem, DetailKey, MarkupRate
  					commit tran --121063, 120700
					end

  				/* As transactions get added, UM may be different.  Therefore it is necessary to 
  				   Convert/Calculate JBID UM, Units, UnitPrice, ECM to correctly reflect a Mixture
  				   of UMs in bJBIJ.  In some cases, these values cannot be determined and will be set to
  				   NULL/0. */
  				exec @rcode = bspJBTandMUpdateJBIDUnitPrice @co, @mth, @billnum, @line, @jbidseq,
  					@jctranstype, @priceopt, @jccdmatlgrp, @jccdmaterial, @jccdinco, @jccdloc, 
  					@jccdemgroup, @jccdequip, @jccdemrevcode, @actualhours, @actualunits, @postedum, 
  					@template, @ctcategory, @markupopt, @msg output
  				if @rcode <> 0
  					begin
  					select @msg = 'Error Averaging Line/Seq record'
  					exec @rcode = bspJBTandMTransErrors @co, @mth, @billnum, @jccdmonth, @jccdtrans, 5, @msg output
    				goto NextTrans2
  					end	

              	insert bJBIJ (JBCo, BillMonth, BillNumber, Line, Seq, JCMonth, JCTrans, BillStatus,
  					UM, Hours, Units, UnitPrice, Amt, EMGroup, EMRevCode, AuditYN)
  				select @co, @mth, @billnum, @line, @jbidseq, @jccdmonth, @jccdtrans, 1, 
  					@postedum, 
  			    	case @jctranstype  --Same as Source in bJBIDTMWork at this point
  					when 'PR' then
  			      		case @ctcategory when 'L' then @actualhours else 0 end
  					when 'EM' then @actualhours 
  					else 0 end, 
  					@actualunits, @actualunitcost, @subtotal, @jccdemgroup, @jccdemrevcode, 'N'
  
              	if @@rowcount = 0
            		begin
            		select @msg = 'Error inserting JBIJ', @rcode = 1
            		goto bspexit
            		end
  
              	update bJBIJ
              	set AuditYN = 'Y'
              	from bJBIJ with (nolock)
              	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
					and Line = @line and Seq = @jbidseq and JCMonth = @jccdmonth
					and JCTrans = @jccdtrans
  
  
  				/* Get next Transaction from work Table */
			NextTrans2:
  				fetch next from bcJCMthTrans into @jccdmonth, @jccdtrans
              	end		/* End JC Mth/Trans Loop - Second */
  
  			if @openjcmthtranscursor = 1
  				begin 
  				close bcJCMthTrans
  				deallocate bcJCMthTrans
  				select @openjcmthtranscursor = 0
  				end
    
  			/* Get next 'S'ource and start again. */
  			fetch next from bcJBIDSeq into @jbidseq
           	end
  
  		if @openjbidseqcursor = 1
  			begin
  			close bcJBIDSeq
  			deallocate bcJBIDSeq
  			select @openjbidseqcursor = 0
  			end
 
		/* Handle amt type lines.  No bJBIJ or bJBID involved. */
     	select @subtotal = sum(SubTotal), @markuptot = sum(MarkupTotal),
			@markupaddl = sum(MarkupAddl), @total = sum(Total),
           	@markuprate = sum(MarkupRate)
		from bJBIDTMWork with (nolock)
		where LineType = 'A' and Line = @line and JBCo = @co and VPUserName = SUSER_SNAME()
    
		update bJBIL
		set Basis = @subtotal,
           	MarkupTotal = @markuptot, MarkupRate = @markuprate,
			Total =  @total, AuditYN = 'N'
		from bJBIL with (nolock)
       	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line and LineType = 'A'
  
   		fetch next from bcLine into @line
       	end		/* End Line loop - Second */
  
  	if @openlinecursor = 1
  		begin
  		close bcLine
  		deallocate bcLine
  		select @openlinecursor = 0
  		end
/************************************END INSERTING RECORDS INTO JBIJ.  **************************************/


/*********************** UPDATE DETAIL ADDONS, SET VALUES - WORK TABLE IS NOT USED HERE **********************/
  	
  	/* When running bspJBTandMInit, the procedure bspJBTandMUpdateSeqAddons will NOT get run by the
 	   JBIL insert or update triggers as normal (It gets suspended by the use of the TMUpdateAddonYN = 'N' flag)
 	   Rather we will update Detail Addons only one time using the following code. */
  	declare bcLine cursor local fast_forward for
  	select Line, TemplateSeq, LineKey 
  	from bJBIL with (nolock)
  	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
  		--and LineType = 'S'
		and LineType in ('S', 'D')				--Adding 'D' here now allows Detail Addons against other Detail Addons
  	group by Line, TemplateSeq, LineKey			--without also applying it against any Source sequences.
  
  	open bcLine
  	select @openlinecursor = 1
  
  	fetch next from bcLine into @line, @tempseq, @linekey
  	while @@fetch_status = 0
  		begin 	/* Begin Line Loop - Third */ 
  		/* Update Detail Addons for this Line. - (Total Addons don't get processed using this
  		   procedure yet because, at this moment, JBIL Total Addon Lines do not yet exist. */
  		exec @rcode = bspJBTandMUpdateSeqAddons @co,  @mth, @billnum, null,
  	    	null, null, @template, @tempseq, @linekey, null, null, null, @errmsg output		
  
  		fetch next from bcLine into @line, @tempseq, @linekey
  		end		/* End Line Loop - Third */
  
  	if @openlinecursor = 1
  		begin
  		close bcLine
  		deallocate bcLine
  		select @openlinecursor = 0
  		end

  /******************************* PROCESS TOTAL ADDONS - WORK TABLE IS NOT USED HERE ************************/
  
	/* Now process total addons.  Again, no bJBIJ or bJBID involved. Skip if no lines
  	   currently exist in bJBIL. */
  	if exists(select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @mth
  		and BillNumber = @billnum)
  
  		begin
  	  	exec @rcode = bspJBTandMProcessTotAddons @co, @template, @billnum, @mth, @contract, @itembillgroup, @msg output
  		if @rcode <> 0	--(Will be 10, 11, 12, 99)
  			begin
  			select @errordesc = 'Error creating Total Addon - ' + @msg, @errornumber = 109, @rcode = 0
  			goto BillError
  			end

  /******************************* PROCESS JBIT UPDATE - WORK TABLE IS NOT USED HERE ************************/
		exec @rcode = vspJBTandMUpdateJBIT @co, @mth, @billnum, @contract, null, @msg output
  		if @rcode <> 0	
  			begin
  			select @errordesc = 'Error updating Bill Item amounts - ' + @msg, @errornumber = 109, @rcode = 0
  			goto BillError
  			end
  		end
  
  /******************************* PROCESS MISC DIST - WORK TABLE IS NOT USED HERE ************************/
  
   	/* Now process misc distributions*/
  	if @billnum is not null
  		begin
   		exec @rcode = bspJBTandMProcessMiscDist @co,  @template, @mth, @billnum, @msg output
  		end
  
	/* If @separateinv = 'Y' then we need to cycle thru items by bill group and
       init separate inv per bill group*/
	if @separateinvYN = 'Y'
       	begin	/* Begin Separate Invoice Processing */
  		/* NULL BillGroup Invoice has already been created above.  Now get first
  		   Non-null BillGroup for next invoice and start the process again. */
       	if @itembillgroup is null
			begin
          	select @itembillgroup = min(BillGroup)
           	from bJCCI with (nolock)
          	where JCCo = @co and Contract = @contract and BillType in ('B','T')
  
  			if @itembillgroup is null goto NextContract
          	end
		else
  		/* Get Next BillGroup and goto start of process for next bill. */
         	begin
          	select @itembillgroup = min(BillGroup)
          	from bJCCI with (nolock)
           	where JCCo = @co and Contract = @contract and BillType in ('B','T') and BillGroup > @itembillgroup
           	if @itembillgroup is null goto NextContract
           	end
  
 		/* This BillNumber has completed processing for this BillGroup/Item.  Reset TMUpdateAddonYN
 		   flag so that future manual changes to bill will use JBIL triggers to update 
 		   Addons correctly. */
 		update bJBIN
 		set TMUpdateAddonYN = 'Y'
 		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
 
		/* Reset BillNum to NULL.  This will force the next BillNum to be generated for the next Item BillGroup */
		select @billnum = null			--#136331
		
  		/* Start entire process over again for next BillGroup.  New Bill gets created. */
       	goto ThisBillGroup
		end		/* End Separate Invoice Processing */
  
  	/* Get next contract from range. */
NextContract:
 	/* This BillNumber has completed processing for this Contract.  Reset TMUpdateAddonYN
 	   flag so that future manual changes to bill will use JBIL triggers to update 
 	   Addons correctly. */
 	update bJBIN
 	set TMUpdateAddonYN = 'Y'
 	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
 
	if exists(select 1
           	from bJBJE with (nolock)
			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum)
  	select @errorsexist = 1
  
  	fetch next from bcContract into @contract
  	end		/* End Contract Loop */
  
if @opencontractcursor = 1
  	begin
  	close bcContract
  	deallocate bcContract
  	select @opencontractcursor = 0
  	end
  
  goto bspexit
  
BillError:
if not exists(select top 1 1 from bJBCE with (nolock) where JBCo = @co and Contract = @contract and ErrorNumber = @errornumber)  --#136478
	begin
	insert bJBCE (JBCo, Contract, ErrorNumber, ErrorDesc, ErrorDate)
	select @co, @contract, @errornumber, @errordesc, convert(smalldatetime,CURRENT_TIMESTAMP)
	end
	
select @contracterrors = 1
  
/* Close all cursors except Contract. We will continue with next Contract */
if @openitemcursor = 1
  	begin
  	close bcItem
  	deallocate bcItem
  	select @openitemcursor = 0
  	end
if @openjobphasecursor = 1
  	begin
  	close bcJobPhase
  	deallocate bcJobPhase
  	select @openjobphasecursor = 0
  	end
if @openjcmthtranscursor = 1
  	begin
  	close bcJCMthTrans
  	deallocate bcJCMthTrans
  	select @openjcmthtranscursor = 0
  	end
if @openlinekeycursor = 1
  	begin
  	close bcLineKey
  	deallocate bcLineKey
  	select @openlinekeycursor = 0
  	end
if @opendetailkeycursor = 1
  	begin
  	close bcDetailKey
  	deallocate bcDetailKey
  	select @opendetailkeycursor = 0
  	end
if @opendetaddoncursor = 1
  	begin
  	close bcDetAddon
  	deallocate bcDetAddon
  	select @opendetaddoncursor = 0
  	end
if @opentotaddoncursor = 1
  	begin
  	close bcTotAddon
  	deallocate bcTotAddon
  	select @opentotaddoncursor = 0
  	end
if @openlinecursor = 1
  	begin
  	close bcLine
  	deallocate bcLine
  	select @openlinecursor = 0
  	end
if @openjbidseqcursor = 1
  	begin
  	close bcJBIDSeq
  	deallocate bcJBIDSeq
  	select @openjbidseqcursor = 0
  	end
 
/* This BillNumber has errored during processing for this Contract .  Reset TMUpdateAddonYN
flag so that future manual changes to bill will use JBIL triggers to update 
Addons correctly. */
Begin Tran --121063, 120700
update bJBIN
set TMUpdateAddonYN = 'Y'
where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
Commit Tran --121063, 120700
goto NextContract

bspexit:
/* This BillNumber may have completed successfully for this Contract and this flag
may have already be reset but in the event of an abnormal exit, we need to make
sure to reset TMUpdateAddonYN flag so that future manual changes to bill will use 
JBIL triggers to update Addons correctly. */
update bJBIN
set TMUpdateAddonYN = 'Y'
where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
 
if @rcode is null select @rcode = 0
if @contracterrors = 1 or @progcontracterrors = 1
  	begin
  	if @errorsexist = 0		--No bJBJE errors exist, Yes bJBCE errors exist
     	begin
      	select @errorsexist = 2
       	end
   	else					--Yes bJBJE errors exist, and Yes bJBCE errors exist
       	begin
        	select @errorsexist = 3
     	end
	end
  
/* Clear out Work table for this User */
delete bJBIDTMWork where JBCo = @co and VPUserName = SUSER_SNAME()	
  
/* Close all cursors */
if @opencontractcursor = 1
  	begin
  	close bcContract
  	deallocate bcContract
  	select @opencontractcursor = 0
  	end
if @openitemcursor = 1
  	begin
  	close bcItem
  	deallocate bcItem
  	select @openitemcursor = 0
  	end
if @openjobphasecursor = 1
  	begin
  	close bcJobPhase
  	deallocate bcJobPhase
  	select @openjobphasecursor = 0
  	end
if @openjcmthtranscursor = 1
  	begin
  	close bcJCMthTrans
  	deallocate bcJCMthTrans
  	select @openjcmthtranscursor = 0
  	end
if @openlinekeycursor = 1
  	begin
  	close bcLineKey
  	deallocate bcLineKey
  	select @openlinekeycursor = 0
  	end
if @opendetailkeycursor = 1
  	begin
  	close bcDetailKey
  	deallocate bcDetailKey
  	select @opendetailkeycursor = 0
  	end
if @opendetaddoncursor = 1
  	begin
  	close bcDetAddon
  	deallocate bcDetAddon
  	select @opendetaddoncursor = 0
  	end
if @opentotaddoncursor = 1
  	begin
  	close bcTotAddon
  	deallocate bcTotAddon
  	select @opentotaddoncursor = 0
  	end
if @openlinecursor = 1
  	begin
  	close bcLine
  	deallocate bcLine
  	select @openlinecursor = 0
  	end
if @openjbidseqcursor = 1
  	begin
  	close bcJBIDSeq
  	deallocate bcJBIDSeq
  	select @openjbidseqcursor = 0
  	end
/* Non-Contract */
if @openncprocgrpseqcursor = 1
  	begin
  	close bcNCProcGrpSeq
  	deallocate bcNCProcGrpSeq
  	select @openncprocgrpseqcursor = 0
  	end 
if @opennctempseqcursor = 1
  	begin
  	close bcNCTempSeq
  	deallocate bcNCTempSeq
  	select @opennctempseqcursor = 0
  	end
  
return @rcode












GO
GRANT EXECUTE ON  [dbo].[bspJBTandMInit] TO [public]
GO
