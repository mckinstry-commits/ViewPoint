SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMAddJCTrans Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBTandMAddJCTrans]
/***********************************************************
* CREATED BY: kb 7/24/00
* MODIFIED BY:  bc 08/24/00
* 		GG 11/27/00 - changed datatype from bAPRef to bAPReference
*  		kb 5/8/01 - issue #13341
*		AllenN 06/18/01 - issue #13034
*    	kb 8/13/1 - issue #13963
*     	kb 2/8/2 - issue #16068
*     	kb 2/19/2 - issue #16147
*    	kb 2/21/2 - issue #16250
*      	kb 4/29/2 - issue #17094
*     	kb 5/1/2 - issue #17095
*		TJL 07/09/02 - Issue #17701, Modified 'exec bspJBTandMAddSeqAddons' call 
*						and exec bspJBTandMAddLineTwo call.
*		kb 8/5/2 - issue #18055 - fixed so if no matl rate it will not exit program with error
*		TJL 08/21/02 - Issue #17472,  Additional MSTicket Input/Output for bspJBTandMGetDetailKey
*		TJL 08/30/02 - Issue #18346, Reorganized the section to retrieve rates. Now exact same as bspJBTandMInit. 
*						Actually the content did not change at all, just the look.
*		TJL 09/09/02 - Issue #17620, Correct Source MarkupOpt when 'U' use Rate * Units
*		TJL 01/16/03 - Issue #19764, Correct Usage of Material Rates
*		TJL 02/26/03 - Issue #19765, Category returning as NULL for Material from HQMT. Fix bspJBTandMGetCategory
*		TJL 03/19/03 - Issue #19765, Not calling bspJBTandMGetCategory when JCTransType = 'MS'
*		TJL 03/27/03 - Issue #20550, Friendly Error on LineType 'N', non-billable
*		TJL 05/28/03 - Issue #21280, PR Source, L ctcategory: 0 hours * Labor Rates must equal 0 not actualcost
*		TJL 06/24/03 - Issue #21388, Use PostedUnits for all sources, correct usage of MatlRate value.
*		TJL 07/31/03 - Issue #21714, Use Markup rate from JCCI if available else use Template markup.
*		TJL 09/15/03 - Issue #22126, Perfomance enhancements, added NoLocks in this procedure
*		TJL 09/19/03 - Issue #22442, Use PostedUM for all sources
*		TJL 09/24/03 - Issue #22551, Get DetailKey after establishing Rates
*		TJL 12/08/03 - Issue #23222, Corrected LS @actualunits
*		TJL 01/22/04 - Issue #23561, Correct @actualcost, @actualunitcost determined by the use of Equip Rates
*		TJL 03/23/04 - Issue #24048, Return and then Use correct ECM value from proper sources
*		TJL 03/31/04 - Issue #24189, Check for invalid Template Seq Item
*		TJL 04/07/04 - Issue #24240, Correct Divide by 0.00 error
*		TJL 04/12/04 - Issue #24304, Use errmsg directly from bspJBTandMGetCategory proc, REM 2nd bspJBTandMGetCategory
*		TJL 05/14/04 - Issue #22526, Accurately accumulate JBID UM, Units, UnitPrice, ECM.  Phase #1
*		TJL 06/11/04 - Issue #24809, Related to problem induced by Issue #24304. Set @matlrate errmsg
*		TJL 06/24/04 - Issue #24915, Increase Accuracy of JBID.SubTotal
*		TJL 08/10/04 - Issue #25314, Separate PR Burden by Category if desired
*		TJL 12/14/04 - Issue #26392, Do not Restrict using bspJBTandMGetEquipRate based upon RevCode values
*		TJL 01/10/05 - Issue #17896, Add EffectiveDate to JBTM and NewRate/NewSpecificPrice to JBLR, JBLO, JBER, JBMO
*		TJL 05/10/06 - Issue #28227, 6x Rewrite.  Return NULL output in bspJBTandMAddLineTwo call and 
*							Remove @actualunits from call to bspJBTandMAddSeqAddons and add NULL output
*		TJL 10/08/07 - Issue #125078, TransTypes 'IC' from 'JC CostAdj' need to be processed as JCTransTypes 'JC'
*		TJL 12/20/07 - Issue #125982, Don't show IN Material Committed JCCD transactions on JB Bill
*		TJL 01/11/08 - Issue #123452, TransTypes 'MI' from 'JC MatlUse' need to be processed as JCTransTypes 'JC'
*		TJL 03/18/08 - Issue #126836, Add Pre-Bill warning to manual JC Transaction entry
*		TJL 06/30/08 - Issue #128850, Rounding problem when EM transaction using Rates by TimeUM
*		TJL 07/29/08 - Issue #128962, JB International Sales Tax
*		TJL 12/04/08 - Issue #131219, Related to #125982 - Committed or not based on ActualCost and ActualUnits
*		TJL 01/21/08 - Issue #131622, Should have been part of Issue #123452.  Call bspJBTandMGetCategory for JC Matl
*		TJL 03/19/09 - Issue #120614, Add ability to include Rate value in summarization of PR Sources
*		GF  06/25/2010 - issue #135813 expanded SL to varchar(30)
*		TJL 08/20/10 - Issue #140764, TaxRate calculations accurate to only 5 decimal places.  Needs to be 6
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
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
   
(@co bCompany, @billmth bMonth, @billnum int, @jcmonth bMonth, @jctrans bTrans,
   	@line int output, @jbidseq int output, @postedum bUM output, @actualhours bHrs output, 
   	@actualunits bUnits output, @actualunitcost bUnitCost output, @actualcost numeric(15,5) output, 
   	@jccdemgroup bGroup output, @jccdemrevcode bRevCode output, @msg varchar(275) output)
as

set nocount on
   
declare @rcode int, @template varchar(10), @sortorder char(1), @phasegroup bGroup,
   	@phase bPhase, @job bJob, @actualdate bDate, @postdate bDate, @item bContractItem,
   	@source char(2), @costtype bJCCType, @prco bCompany, @employee bEmployee,
   	@craft bCraft, @class bClass, @earntype bEarnType, @factor bRate,
   	@shift tinyint, @apco bCompany, @vendorgroup bGroup, @vendor bVendor,
   	@apref bAPReference, @inco bCompany, @MSticket bTic, @matlgroup bGroup, @material bMatl, @loc bLoc,
   	@stdprice bUnitCost, @equip bEquip, @revcode bRevCode, @jccddesc bDesc,
   	@sl VARCHAR(30), @slitem bItem, @emgroup bGroup, @liabtype bLiabilityType,
   	@um bUM, @jctranstype char(2),
   	@postedunitcost bUnitCost, @ctcategory char(1), @linekey varchar(100),
   	@detailkey varchar(500),
   	@actualecm bECM, @seqsortlevel tinyint, @seqsummaryopt tinyint,
   	@postedecm bECM, @emco bCompany, @templateseq int, @date bDate,
   	@laborrateopt char(1), @laboroverrideyn bYN, @equiprateopt char(1),
   	@laborcatyn bYN, @equipcatyn bYN, @contract bContract,
   	@matlcatyn bYN, @category varchar(10), @currentcategory varchar(10), @po varchar(30),
   	@poitem bItem, @groupnum int, @seqtype char(1), @sequserates char(1),
   	@equiprate bUnitCost, @HrsPerTimeUM bHrs, @laborrate bUnitCost,
   	@matlrate bUnitCost, @jcchum bUM, @jcchbillflag char(1),
   	@jccimarkuprate bRate, @taxgroup bGroup, @taxcode bTaxCode, @taxrate bRate,
   	@invdate bDate, @markupopt char(1), @markuprate numeric(17,6), @ecmfactor smallint,
   	@stdecm bECM, @priceopt char(1), @emrcbasis char(1), 
   	@jccdmatlgrp bGroup, @jccdmaterial bMatl, @jccdinco bCompany,
   	@jccdloc bLoc, @jccdequip bEquip, @laboreffectivedate bDate, @equipeffectivedate bDate,
   	@matleffectivedate bDate, @prebillmonth bMonth, @prebillnum int, @prebillline int, @prebilllineseq int, 
	@prebillmthstr varchar(255)

   --	@jbidum bUM, @jbidmaterial bMatl, @priceopt char(1), @hqmtum bUM, 
   --	@conversion bUnitCost
   
select @rcode = 0

/*  if exists(select * from bJBIJ where JBCo = @co and BillMonth = @billmth and
BillNumber = @billnum and JCMonth = @jcmonth and JCTrans = @jctrans)
goto bspexit*/
   
select @template = Template, @contract = Contract, @invdate = InvDate
from bJBIN with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   
if @template is null
   	begin
   	select @msg = 'Template missing for this bill', @rcode = 1
   	goto bspexit
   	end
   
select @sortorder = SortOrder, @laborrateopt = LaborRateOpt,
   	@laboroverrideyn = LaborOverrideYN, @equiprateopt = EquipRateOpt,
   	@laborcatyn = LaborCatYN, @equipcatyn = EquipCatYN,
   	@matlcatyn = MatlCatYN, @laboreffectivedate = LaborEffectiveDate, 
   	@equipeffectivedate = EquipEffectiveDate, @matleffectivedate = MatlEffectiveDate
from bJBTM with (nolock)
where JBCo = @co and Template = @template
   
if @@rowcount  = 0
   	begin
   	select @msg = 'Invalid template', @rcode = 1
   	goto bspexit
   	end
   
select @source = case d.Source when 'JC MatUse' then 'IN' else left(d.Source,2) end,
   	@jctranstype = case d.JCTransType when 'CA' then 'JC' 
			when 'IC' then 'JC'
   			when 'MI' then 'JC'
   			--when 'MO' then 'IN'
          		else d.JCTransType end,
   	/*@usepostedYN = case when d.Source in ('JC MatUse','MI') then 'Y'
                      else 'N' end,*/
   	@prco = d.PRCo, @employee = d.Employee, @craft = d.Craft,
   	@class = d.Class, @earntype = d.EarnType, @factor = d.EarnFactor,
   	@shift = d.Shift, @apco = d.APCo,
   	@vendorgroup = d.VendorGroup, @vendor = d.Vendor,
   	@apref = d.APRef, @inco = d.INCo, @MSticket = d.MSTicket, 
	@matlgroup = d.MatlGroup, @material = d.Material, @loc = d.Loc,
   	@stdprice = d.ActualUnitCost, @postdate = d.PostedDate,
   	@sl=d.SL, @slitem = d.SLItem, @emgroup = d.EMGroup,
   	@equip = d.EMEquip, @revcode = d.EMRevCode, @actualdate = d.ActualDate,
   	@jccddesc=d.Description, @liabtype = d.LiabilityType,
   	@um = d.UM,
   	--@um = case d.JCTransType when 'AP' then d.PostedUM else d.UM end,
   	@actualunits = d.PostedUnits,
   	--@actualunits = case when d.Source in ('JC MatUse','MI') then						***
   	--	d.PostedUnits else case when d.JCTransType = 'AP' then							  **	Removed Issue #21388, easier to change	
       --     	case when d.UM <> d.PostedUM then d.PostedUnits else d.ActualUnits end	  **	here than to use @postedunits thru-out
       --     	else d.ActualUnits end end,												***								
   	@postedum = d.PostedUM,
   	@postedunitcost = d.PostedUnitCost,
   	@actualunitcost = d.PostedUnitCost,
   	--@actualunitcost = case when d.Source in ('JC MatUse','MI') then					***
       --	d.PostedUnitCost else case when d.JCTransType = 'AP' then					  **	Removed Issue #21388, easier to change
       --     	case when d.UM <> d.PostedUM then d.PostedUnitCost else d.ActualUnitCost  **	here than to use @postedunitcost thru-out
       --     	end  else d.ActualUnitCost end end ,									***
   	@actualhours = d.ActualHours,
   	@actualcost = d.ActualCost,
   	@actualecm = d.PostedECM, @stdecm = d.PerECM,
   	@postedecm = d.PostedECM, @emco = d.EMCo, @costtype = d.CostType,
   	@po = d.PO, @poitem = d.POItem,
   	@phasegroup = d.PhaseGroup, @phase = d.Phase, @job = d.Job,
   	@item = p.Item
from bJCCD d with (nolock)
join  bJCJP p with (nolock) on p.JCCo = d.JCCo and p.Job = d.Job and
   	p.PhaseGroup = d.PhaseGroup and p.Phase = d.Phase 
where d.JCCo = @co and d.Mth = @jcmonth and d.CostTrans = @jctrans
   
if @@rowcount = 0
   	begin
   	select @msg = 'JC Month/JC Trans combination does not exist', @rcode = 1
   	goto bspexit
   	end
   
/* Separate variables to update bJBIJ and to pass into procedure bspJBTandMUpdateJBIDUnitPrice 
  are needed.  Some variables from above get set differently (or Nulled out) in order 
  to update bJBID according to Template Summary and Sort options. */
select @jccdmatlgrp = @matlgroup, @jccdmaterial = @material, @jccdinco = @inco,
   	@jccdloc = @loc, @jccdemgroup = @emgroup, @jccdequip = @equip, @jccdemrevcode =@revcode

/***** SPECIAL SETUP of @jctranstype value *****/

/* AP evaluation: based upon presence of Material or SL */
if @jctranstype = 'AP'		--set source for SL and Material types
   	begin
   	if @material is not null select @jctranstype = 'MT'		--@source = 'MT'
   	if @sl is not null select @jctranstype = 'SL'			--@source = 'SL'
   	end

/*get costtype category*/
select @ctcategory = JBCostTypeCategory 
from bJCCT with (nolock)
where PhaseGroup = @phasegroup and CostType = @costtype
   
/* PR, MS evaluation: based upon JBCostTypeCategory */
if (@jctranstype = 'PR' and @ctcategory = 'E') 
   	or (@jctranstype = 'MS' and @ctcategory = 'E') select @jctranstype = 'EM'

/***** SPECIAL EVALUATION:  Under certain conditions, skip this transaction altogether. *****/

if @jctranstype = 'MO'
	begin
	if @actualcost = 0 and @actualunits = 0
		begin
		/* Material Order Transaction has committed costs but none yet confirmed.  Do Not show on Bill. */
		select @msg = 'Material Order Transaction has committed costs but none yet confirmed.', @rcode = 1
		goto bspexit
		end
	else
		begin
		/* Material Order/Item Transaction has been Confirmed.  Place Transaction on Bill. */
		select @jctranstype = 'IN'
		end
	end

/* Get CostType Info.  Because user is inputting transactions manually, BillFlag is ignored.
   User must want to bill the transaction else user would not be entering it now. */
exec bspJCVCOSTTYPE @co, @job, @phasegroup, @phase, @costtype, 'N',
    -- outputs
   	null, null, null, @jcchbillflag output, @jcchum output, null, null, 
   	null, null, @msg output

/***** INFORMATION AND RATES *****/
/* @sequserates get changed later on by running bspJBTMGetLaborRate and
   bspJBTMGetEquipRate. */
select @sequserates = case @jctranstype --@jbidsource
   	when 'PR' then case @ctcategory 
   		when 'L' then @laborrateopt			--C, R
   		when 'B' then @laborrateopt			--C, R
   		when 'E' then @equiprateopt end		--C, R, T (due to the above, this line NA)
   	when 'EM' then @equiprateopt			--C, R, T
   	else 'C' end
   
/* Get category */
if (@jctranstype = 'PR' and @ctcategory in ('L','B') and (@laborcatyn = 'Y' or @sequserates='R')) or
   	(@jctranstype = 'PR' and @ctcategory ='E' and (@equipcatyn = 'Y' or	@sequserates in('T','R')) or 
   		((@jctranstype = 'JC' or @jctranstype = 'MT' or @jctranstype = 'IN' or @jctranstype = 'MS') and @matlcatyn = 'Y') or
   		(@jctranstype = 'EM' and(@sequserates in('T','R') or @equipcatyn = 'Y')))
   	begin
   	/* Much of what is passed into this procedure below is unnessesary. 
   		1) LaborCategory is returned from bJBLX Labor Rate Table
   		2) EquipCategory is returned from bEMEM
   		3) Material Category is return from either bHQMT or bEMEM */	
   	exec @rcode = bspJBTandMGetCategory @co, @prco, @employee, @craft, @class, @earntype, 
   		@factor, @shift, @emco, @equip, @matlgroup, @material,
   		@revcode, @jctranstype, @template, @ctcategory,
		@currentcategory output, @msg output
   	if @rcode <> 0 goto bspexit
   	end
else
   	begin
     	select @currentcategory = null
   	end
   
select @category = @currentcategory
   
/*get template seq*/
exec @rcode = bspJBTandMGetTemplateSeq @co, @template, @category, @source,
   	@earntype, @liabtype, @phasegroup, @costtype, @templateseq output,
   	@seqsortlevel output, @seqsummaryopt output, @groupnum output,
   	@seqtype output, @jctranstype, @msg output
if @rcode <> 0 goto bspexit
   
exec @rcode = bspJBTandMGetLineKey @co,
	@phasegroup, @phase, @job, @item, @template, @templateseq ,
   	@postdate, @actualdate, @groupnum, 'N', @linekey output, @msg output
if @rcode<> 0 goto bspexit
   
/* Get Item specific info for item specific Markup values related to 'S'ource lines. 
   We need to get this info now.  We need it when inserting a JBIL line, or if one exists
   when inserting JBID records.  */
select @taxgroup = TaxGroup, @taxcode = TaxCode, 
	@jccimarkuprate = MarkUpRate
from bJCCI with (nolock)
where JCCo = @co and Contract = @contract and Item = @item
   
if @taxcode is not null
	begin
 	exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,	@taxrate output, @msg = @msg output
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
   		else MarkupRate end,
   	@priceopt = PriceOpt
from bJBTS with (nolock)
where JBCo= @co and Template = @template and Seq = @templateseq 

select @line = Line 
from bJBIL with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
	and LineKey = @linekey and LineType = 'S'
if @@rowcount <> 0 goto AddSeq
   
exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @linekey,
   	@template, @templateseq, null, @line output, null, @msg output
   
if @rcode <> 0 goto bspexit
   
insert bJBIL (JBCo,BillMonth,BillNumber,Line,Item,Contract,Job,
   	PhaseGroup,Phase,Date,Template,TemplateSeq,TemplateSortLevel,
   	TemplateSeqSumOpt,TemplateSeqGroup,LineType,Description,TaxGroup,
   	TaxCode,MarkupOpt,MarkupRate,Basis,MarkupAddl,MarkupTotal,Total,
   	Retainage,Discount,NewLine,ReseqYN,LineKey,Notes)
select @co, @billmth, @billnum, @line, @item, @contract,
   	case @sortorder  when 'J' then @job else null end,
	@phasegroup, 
   	case when @sortorder in ('P','J') then @phase else null end, 
   	case @sortorder when 'A' then @actualdate when 'D' then @postdate else null end, 
   	@template, @templateseq, @seqsortlevel,
   	@seqsummaryopt, GroupNum, 'S', Description, null,
   	null, @markupopt, @markuprate, 0, AddonAmt, AddonAmt, AddonAmt /*0*/,	-- Issue #21714 chg from MarkupOpt, MarkupRate,
   	0, 0, null, 'N', @linekey, null
from bJBTS with (nolock)
where JBCo = @co and Template = @template and Seq = @templateseq
   
AddSeq:
   -- if (@jctranstype = 'PR' and @ctcategory ='L' and (@laborcatyn = 'Y' or @sequserates='R')) or
   -- 	(@jctranstype = 'PR' and @ctcategory ='E' and (@equipcatyn = 'Y' or @sequserates in('T','R')) or
   -- 	((@jctranstype = 'MT' or @jctranstype = 'IN' or @jctranstype = 'MS') and @matlcatyn = 'Y') or
   -- 	(@jctranstype = 'EM' and (@sequserates in('T','R') or @equipcatyn = 'Y')))
   -- 	begin
   -- 	/* Much of what is passed into this procedure below is unnessesary. 
   -- 		1) LaborCategory is returned from bJBLX Labor Rate Table
   -- 		2) EquipCategory is returned from bEMEM
   -- 		3) Material Category is return from either bHQMT or bEMEM */	
   -- 	exec @rcode = bspJBTandMGetCategory @co, @prco, @employee, @craft, @class, @earntype, 
   -- 		@factor, @shift, @emco,	@equip, @matlgroup, @material,
   -- 		@revcode, @jctranstype, @template, @ctcategory, 
   -- 		@category output, @msg output
   --  	end

/* NOTE: As of 08/30/02, I have compared code in bspJBTandMInit
  and this procedure relative to getting rate information.  All work exactly the
  same as of this date.  See 'GetMatlRate' section below for slight diff. */
   
if @jctranstype /*@jbidsource*/ = 'PR' and @ctcategory = 'L'
   	begin
   	select @postedum = null, @actualecm = null
   
   	if @sequserates = 'R' 	--From the Template (Not 'C'ost)
       	begin
		exec @rcode = bspJBTandMGetLaborRate @co, @template, @category,
           	@prco, @employee, @craft, @class, @shift,
           	@earntype, @factor, @actualdate, @laboreffectivedate, @sequserates output, 
   			@laborrate output, @msg output
   
		if @rcode <> 0
           	begin
         	select @msg = 'Error getting labor rate', @rcode = 1
         	goto bspexit
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
   			select @msg = 'Incorrect Template setup for Units Based EM RevCode', @rcode = 1
   			goto bspexit
   			end
   		if @equiprateopt = 'T' and @emrcbasis is null
   			begin
   			select @msg = 'Incorrect Template setup for Missing EM RevCode', @rcode = 1
   			goto bspexit
   			end	*/	
   
		exec @rcode = bspJBTandMGetEquipRate @co, @jctranstype, @template, @category,
			@emco, @emgroup, @equip, @revcode, @actualdate, @equipeffectivedate, @sequserates output,
   			@equiprate output, @HrsPerTimeUM output, @msg output
         	if @rcode <> 0 			-- and @equiprateopt = 'R' (same as bspJBTandMInit)
           		begin
        		select @msg = 'Error getting equipment rate', @rcode = 1
            	goto bspexit
             	end
   
   		/* @actualunits is primarily material related EXCEPT IN THIS CASE when it becomes
   		   TIMEUNITS.  */
		if @equiprateopt = 'T' 
   			begin
   			select @rcode = 0 
   			select @postedum = null
   			select @actualunits = case when isnull(@HrsPerTimeUM,0) = 0 then 0 else @actualhours / @HrsPerTimeUM end
   			end
       	end
   	end
   
if @material is not null and @actualunits <> 0
   	begin	/* Begin Material not Null group */
   	exec @rcode = bspJBTandMGetMatlRate @co, @jctranstype,
       	@template, @templateseq, @actualunitcost, @actualecm, @category,
		@matlgroup, @material, @inco, @loc, @postedum, @actualdate, @matleffectivedate,
   		@matlrate output, @actualecm output, @msg output
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
		select @msg = 'Error getting material rate', @rcode = 1
    	goto bspexit
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
   
/* Getting DetailKey may not occur before this time because some values (ie. @material which
  is used to determine Material Rates above) will get set to NULL by this process inorder to 
  correctly place the transaction and Display summarized JBID values.  */
exec @rcode = bspJBTandMGetDetailKey @co, @jcmonth, @jctrans, @jctranstype output,
	@seqsortlevel output, @seqsummaryopt output, @category output, @prco output,
  	@employee output, @craft output, @class output, @earntype output,
 	@factor output, @ctcategory output, @shift output, @apco output,
  	@vendorgroup output, @vendor output, @apref output, @inco output,
 	@MSticket output, @matlgroup output, @material  output, @loc output,
  	@sl output, @slitem output, @emgroup output, @equip output, @revcode output,
 	@actualdate  output, @liabtype output,@jccddesc output,
  	@emco output, @costtype output, @phasegroup output, @po output,
 	@poitem output, @laborrate output, @detailkey output, @postdate output, @msg output
   
if @rcode <> 0 or @detailkey is null
   	begin
   	select @rcode = 1, @msg = 'Error setting detail key'
   	goto bspexit
   	end

select @rcode = 0

exec @rcode = bspJBTandMAddLineSeq @co, @billmth, @billnum, @detailkey,  @line,
   	@jbidseq output, @msg output
   
if @jbidseq is null
   	begin
   	select @rcode = 1, @msg = 'Cannot get a JBID Sequence'
   	goto bspexit
   	end
   
/* insert JBID as required. */
if exists(select 1 from bJBID with (nolock) where JBCo = @co and BillMonth = @billmth and
	BillNumber = @billnum and Line = @line and Seq = @jbidseq)
   	begin
	goto AddTrans
 	end
   
insert bJBID (JBCo,BillMonth,BillNumber,Line,Seq,
   	Source,
   	PhaseGroup,CostType,CostTypeCategory,PRCo,Employee,EarnType,Craft,Class,
   	Factor,Shift,LiabilityType, APCo,VendorGroup,Vendor,APRef,PreBillYN,
   	INCo,MSTicket,MatlGroup,Material, Location, StdUM, StdPrice,
   	StdECM,SL,SLItem,PO,POItem,EMCo,EMGroup,Equipment,RevCode,
   	JCMonth,
   	JCTrans,
   	JCDate,Category,Description,
  	UM,Units,UnitPrice,ECM,Hours,SubTotal,MarkupRate,
  	MarkupAddl,MarkupTotal,Total,Template,TemplateSeq,
  	TemplateSortLevel,TemplateSeqSumOpt,TemplateSeqGroup,DetailKey,Notes, AuditYN)
select @co, @billmth, @billnum, @line, @jbidseq,
   	case when @jctranstype in ('SL','MT') then 'AP' else @jctranstype end,
   	@phasegroup, @costtype, @ctcategory, @prco, @employee, @earntype, @craft, @class,
   	@factor, @shift, @liabtype, @apco, @vendorgroup, @vendor, @apref, 'N',
   	@inco, @MSticket, @matlgroup, @material, @loc, @um, isnull(@stdprice,0),
   	@stdecm, @sl, @slitem, @po, @poitem, @emco, @emgroup, @equip, @revcode,
   	--case @seqsummaryopt when 1 then @jcmonth else null end,	-- Seems to work without this.  JIC
   	@jcmonth,
   	--case @seqsummaryopt when 1 then @jctrans else null end,	-- Seems to work without this.  JIC
   	@jctrans, 
   	@actualdate, @category, @jccddesc,
   	@postedum,
   	--case @jctranstype when 'IN' then @postedum 
   	--					when 'MS' then @postedum	
   	--					when 'MT' then @postedum
   	--					when 'MI' then @postedum
   	--				else @um end,
   	0 /*@actualunits*/, 0 /*isnull(@actualunitcost,0)*/, @actualecm, 0 /*@actualhours*/,
   	0 /*@actualcost*/, @markuprate,								-- Issue #21714 changed from MarkupRate, 
   	0 /*AddonAmt*/, 0 /*AddonAmt*/, 0 /*AddonAmt*/, @template, @templateseq,
   	@seqsortlevel, @seqsummaryopt, GroupNum, @detailkey, null,'N'
from bJBTS with (nolock)
where JBCo = @co and Template = @template and Seq = @templateseq
   
update bJBID 
set AuditYN = 'Y' 
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   	and Seq = @jbidseq
   
AddTrans:
/* Remember, as with bspJBTandMInit, most updates to bJBID will occur as a result of an
  insert to bJBIJ.  The following is the exception. */

/* As transactions get added, UM may be different.  Therefore it is necessary to 
  Convert/Calculate JBID UM, Units, UnitPrice, ECM to correctly reflect a Mixture
  of UMs in bJBIJ.  In some cases, these values cannot be determined and will be set to
  NULL/0. */
exec @rcode = bspJBTandMUpdateJBIDUnitPrice @co, @billmth, @billnum, @line, @jbidseq,
   	@jctranstype, @priceopt, @jccdmatlgrp, @jccdmaterial, @jccdinco, @jccdloc, 
   	@jccdemgroup, @jccdequip, @jccdemrevcode, @actualhours, @actualunits, @postedum, 
   	@template, @ctcategory, @markupopt, @msg output
   if @rcode <> 0 goto bspexit
   
exec @rcode = bspJBTandMAddSeqAddons @co,  @billmth, @billnum, @template, @line, @msg output
if @rcode <> 0 goto bspexit
   
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
			+ '/' + convert(varchar(5),right(datepart(yy,@prebillmonth),2)) + '  '
		select @msg = 'Possibly prebilled on ' + @prebillmthstr + ' Bill#: ' + convert(varchar(10),@prebillnum)
			+ '  Line#: ' + convert(varchar(10),@prebillline) + '  Seq#' + convert(varchar(10),@prebilllineseq)
		select @rcode = 7
		end
	end

bspexit:
if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[bspJBTandMAddJCTrans]'

return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspJBTandMAddJCTrans] TO [public]
GO
