SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMGetDetAddLineKey    Script Date: 07/12/02 9:32:34 AM ******/
CREATE proc [dbo].[bspJBTandMGetDetAddLineKey]
/**************************************************************************************
* CREATED BY: TJL 07/12/02	- Issue #17701
* MODIFIED BY: TJL 07/17/02 - Issue #17144, Return correct MarkupRate based on MarkupOpt
*		TJL 05/12/06 - Issue #28227, 6x Rewrite.  Complete rework.
*		
*
* USED IN:
*	Called from Form JBTMBillLines when entering at the grid
*
* USAGE:
*	To find the first LineKey associated with this Detail Addon
*
* INPUT PARAMETERS
*	@co bCompany, @billmth bMonth, @billnum int,
*	@template varchar(10), @templateseq int,
*
* INPUT/OUTPUT PARAMETERS
*	@job bJob output, @phase bPhase output,  
*	@date bDate output,	@item bContractItem = output, 
*
* OUTPUT PARAMETERS
*	@linekey	
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
********************************************************************************/
   
(@co bCompany, @billmth bMonth, @billnum int, @template varchar(10), @templateseq int,
	@job bJob, @phase bPhase, @date bDate, @item bContractItem, @returndefaultsyn bYN, 	
	@jobdefault bJob output, @phasedefault bPhase output, @datedefault bDate output, @itemdefault bContractItem  output, 
	@markuprate bPct output, @linekey varchar(100) output,  
	@msg varchar(255) output)
   
as

set nocount on

declare @rcode int, @sortorder char(1), 
	@retgpct bPct, @payterms bPayTerms, @discrate bPct, @taxcode bTaxCode,
	@taxgroup bGroup, @taxrate bRate, @custgroup bGroup, @customer bCustomer,
	@invdate bDate, @contract bContract
   
select @rcode = 0, @markuprate = 0
   
/* Determine if there is enough information to perform a reduced search */
select @sortorder = SortOrder
from bJBTM with (nolock)
where JBCo = @co and Template= @template

If @returndefaultsyn = 'Y'
	/* Begin Default value search - Return Defaults. */
	begin
   	/* When user manually adds a DetailAddon TemplateSeq, we initially have no idea what 
	   Source Line it will apply against (There is no SourceLine input on grid).  Therefore
	   we must find the first available Source Line (not already using this Detail Addon) and
	   we will return Date, Job, Phase, and Item defaults to match.

	   User may very well change these and though LineKey is returned as well, it will get
	   returned a 2nd time when saving the record. */
   	select @linekey = min(l.LineKey)
   	from bJBTA a with (nolock)
   	join bJBIL l with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
   	where a.JBCo = @co and a.Template = @template and a.AddonSeq = @templateseq
   		and l.LineType in ('S', 'A')
   	
   	while @linekey is not null
   		begin
   		if exists(select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @billmth
   			and BillNumber = @billnum and LineKey = @linekey and TemplateSeq = @templateseq)
			begin
   			goto NextLineKey2
   			end

   		/* If this Detail Addon doesn't exist for this LineKey, we have our Source Line/LineKey value. 
		   Get Defaults values. */
   		select @itemdefault = l.Item, @datedefault = l.Date, @phasedefault = l.Phase, @jobdefault = l.Job,
   			@contract = l.Contract
   		from bJBIL l with (nolock)
   		where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum 
   			and l.LineKey = @linekey and l.LineType in ('S', 'A')

/********************* Get Markup Rate Default.  NOW HANDLED BY FORM by Normal means ********************/

   		/* Get alternate Discount Percentage from PayTerms */
   		/* Works if Contract or Non-Contract since this info already exists in bJBIN Header */
--   		select @invdate = InvDate, @custgroup = CustGroup, @customer = Customer, @payterms = PayTerms
--   		from bJBIN with (nolock)
--   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
--   	
--   		select @discrate = DiscRate from bHQPT with (nolock) where PayTerms = @payterms
   	
   		/* If both Contract and Item are null then this is a Non-Contract bill and 
   		   we should get TaxCode (Ultimately TaxRate) from bARCM */
--   		if @contract is null and @itemdefault is null
--   			begin
--   	  		select @taxgroup = TaxGroup, @taxcode = TaxCode 
--   			from bARCM with (nolock)
--   			where CustGroup = @custgroup and Customer = @customer
--   			end
   	
   		/* If Both Contract and Item have values then this is a Contract bill and
   		   we should get TaxCode (Ultimately TaxRate) from Contract Item */
--   		if @contract is not null and @itemdefault is not null
--   			begin
--   			select @taxgroup = TaxGroup, @taxcode = TaxCode, @retgpct = RetainPCT 
--   			from bJCCI with (nolock)
--   			where JCCo = @co and Contract = @contract and Item = @itemdefault
--   			end
   	
   		/* Get alternate Tax Percentage from TaxCode */
   		/* TaxCode will be Null only when this is a Contract Bill but No Item yet
   		   exists in the grid.  (ie. when TemplateSeq is validated for the first time) */
--   		if @taxcode is not null
--   			begin
--   			exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate output,
--   	   			@msg = @msg output
--   			end
--   	
--   		select @markuprate = case MarkupOpt
--   	    		when 'T' then case when @taxcode is not null then
--   	    			isnull(@taxrate,0) else MarkupRate end
--   	    		when 'R' then case when @contract is null
--   	    			then MarkupRate else case MarkupRate when 0
--   	    			then isnull(@retgpct,MarkupRate) else MarkupRate end end
--   				when 'D' then case when isnull(@discrate,0)<>0 then
--   					case MarkupRate when 0 then @discrate else MarkupRate end
--   					else MarkupRate end
--   	   			else MarkupRate end
--   		from bJBTS with (nolock)
--   		where JBCo = @co and Template = @template and Seq = @templateseq
/*********************************************************************************************************/
   	
		goto bspexit	--We have what we need

   	NextLineKey2:
   		select @linekey = min(l.LineKey)
   		from bJBTA a with (nolock)
   		join bJBIL l with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
   		where a.JBCo = @co and a.Template = @template and a.AddonSeq = @templateseq
   			and l.LineType in ('S', 'A') and l.LineKey > @linekey
   	
   		end
	end		/* End Default value search */
else
	/* Begin LineKey search - Determine Source Line/LineKey and return */
	begin	
	/* Before saving the record, this routine is called one final time for the purpose
	   of returning the LineKey value relative to this Detail Addon.  By this time, user 
	   has or may have modified the initial default values for Date, Job, Phase and Item.  
	   In so doing, the applicable Source Line will now be found and its LineKey value will
	   be returned back to be used for this Detail Addon LineKey. */

/**************************** REMOVED INPUT CHECKS for the following reason **************************/
/* Source LineKeys are based upon combination of Date, Job, Phase, Item.  If user has 
   manually removed or entered a value (different than defaults), and if there is no match to a Source, 
   Addon will simply not be added and user will be notified of NO MATCH condition.  This is enough. */
--	if @sortorder = 'J'
--		begin
--		if @job is null or @phase is null or @item is null 
--			begin
--			select @msg = 'Job, Phase or Item is missing.', @rcode = 1
--			goto bspexit
--			end
--		end
--	if @sortorder = 'P'
--		begin
--		if @phase is null or @item is null
--			begin
--			select @msg = 'Phase or Item is missing.', @rcode = 1
--			goto bspexit
--			end
--		end
--	if @sortorder in ('A', 'D')
--		begin
--		if @date is null or @item is null
--			begin
--			select @msg = 'Date or Item is missing.', @rcode = 1
--			goto bspexit
--			end
--		end
--	if @sortorder in ('I', 'S')
--		begin
--		if @item is null
--			begin
--			select @msg = 'Item is missing.', @rcode = 1
--			goto bspexit
--			end
--		end
/*********************************************************************************************************/

	/* I believe there will only be one Line matching this combination of Job, Phase, Item and Date
	   for any single Detail Addon being saved.  (It should find the LineKey and the DetailAddon 
	   will either exist or not).  The idea of looking for another Source Line, at this point,
	   may be unnecessary.  (This is legacy code, does no harm, and safer to leave). */
   	select @linekey = min(l.LineKey)
   	from bJBTA a with (nolock)
   	join bJBIL l with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
   	where a.JBCo = @co and a.Template = @template and a.AddonSeq = @templateseq
   		and l.LineType in ('S', 'A')
   		and isnull(l.Job, '') = isnull(@job, '') and isnull(l.Phase, '') = isnull(@phase, '') 
		and isnull(l.Item, '') = isnull(@item, '') and isnull(l.Date, '') = isnull(@date, '')
   	
   	while @linekey is not null
   		begin
   		if exists(select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @billmth
   			and BillNumber = @billnum and LineKey = @linekey and TemplateSeq = @templateseq)
			begin
   			goto NextLineKey
   			end

   		/* If this Detail Addon doesn't exist for this LineKey, we have our Source Line/LineKey value. */
   		goto bspexit
   	
   	NextLineKey:
   		select @linekey = min(l.LineKey)
   		from bJBTA a with (nolock)
   		join bJBIL l with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
   		where a.JBCo = @co and a.Template = @template and a.AddonSeq = @templateseq
   			and l.LineType in ('S', 'A')
   			and isnull(l.Job, '') = isnull(@job, '') and isnull(l.Phase, '') = isnull(@phase, '') 
			and isnull(l.Item, '') = isnull(@item, '') and isnull(l.Date, '') = isnull(@date, '')
			and l.LineKey > @linekey
   	
   		end
	end		/* End LineKey Search */
   
/* If here we either never found a compatible Source for this Detail Addon or 
   this Detail Addon, as input, is already applied to a Source and input parameters may
   need to be changed. */
select @msg = 'This Detail Addon has no Source Line or has already been applied against all applicable '
select @msg = @msg + 'Source sequences in this bill.', @rcode = 1
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMGetDetAddLineKey] TO [public]
GO
