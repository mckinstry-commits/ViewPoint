SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBTemplateSeqVal]
   /****************************************************************************
   * CREATED BY: bc   07/17/00
   * MODIFIED By : bc 10/16/00
   *  		kb 1/17/00 - issue #10987
   *    	kb 2/7/02 - issue #16110
   *		TJL 07/17/02 - Issue #17144, Return DiscRate (MarkupRate) from PayTerms or Template
   *						Also add code to get proper TaxRate.
   *		TJL 07/31/03 - Issue #21714, Use Markup rate from JCCI if available else use Template markup.
   *						  Also default Addon Amount correctly for 'S'ource lines when added manually.
   *		TJL 09/30/04 - Issue #25612, Add MarkupOpt (H - Rate by Hour) to Detail Addons, Fix @markuprate bUnitCost
   *		TJL 05/02/06 - Issue #28227, 6x Rewrite.  Return Template Seq Description to use as Line Default
   *
   * Usage:
   *	DDFI entry for JBTMBillLines Seq #101 (Temp Seq).  Validation.  When a new
   *	Line is entered manually on the Line Grid, this procedure will return various
   *	defaults to the line.
   *
   *
   *****************************************************************************/
   
   @jbco bCompany = 0, @billmth bMonth, @billnum int, @template varchar(10), @seq int, 
   	@contract bContract = null,	@item bContractItem = null, @type char(1) output, 
   	@sortlevel tinyint output, @sumopt tinyint output, @seqgroup int output, 
   	@markupopt char(1) output, @groupnum int output, @flatamtopt char(1) output, 
   	@flatamt bDollar output, @markuprate bUnitCost output, @addlmarkup bDollar output, 
   	@templateseqdesc varchar(128) output, @msg varchar(255) output
   
   as
   set nocount on
   
   declare @rcode int, @retpct bPct, @payterms bPayTerms, @discrate bPct, @taxcode bTaxCode,
   	@taxgroup bGroup, @taxrate bRate, @custgroup bGroup, @customer bCustomer,
   	@invdate bDate, @jccimarkuprate bRate
   
   select @rcode = 0
   
   if @jbco is null
    	begin
    	select @msg = 'Missing JB Company!', @rcode = 1
    	goto bspexit
    	end
   
   if @template is null
    	begin
    	select @msg = 'Missing template!', @rcode = 1
    	goto bspexit
    	end
   
   /* Get alternate Discount Percentage from PayTerms */
   /* Works if Contract or Non-Contract since this info already exists in bJBIN Header */
   select @invdate = InvDate, @custgroup = CustGroup, @customer = Customer, @payterms = PayTerms
   from bJBIN with (nolock)
   where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
   select @discrate = DiscRate from bHQPT where PayTerms = @payterms
   
   /* If both Contract and Item are null then this is a Non-Contract bill and 
      we should get TaxCode (Ultimately TaxRate) from bARCM */
   if @contract is null and @item is null
   	begin
     	select @taxgroup = TaxGroup, @taxcode = TaxCode 
   	from bARCM with (nolock)
   	where CustGroup = @custgroup and Customer = @customer
   	end
   
   /* If Both Contract and Item have values then this is a Contract bill and
      we should get TaxCode (Ultimately TaxRate) from Contract Item */
   if @contract is not null and @item is not null
   	begin
   	select @taxgroup = TaxGroup, @taxcode = TaxCode, @retpct = RetainPCT, 
   		@jccimarkuprate = MarkUpRate
   	from bJCCI with (nolock)
   	where JCCo = @jbco and Contract = @contract and Item = @item
   	end
   
   /* Get alternate Tax Percentage from TaxCode */
   /* TaxCode will be Null only when this is a Contract Bill but No Item yet
      exists in the grid.  (ie. when TemplateSeq is validated for the first time) */
   if @taxcode is not null
   	begin
   	exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate, @taxrate output,
      		@msg = @msg output
   	end
   
   select @templateseqdesc = Description, @type = Type, @sortlevel = SortLevel, @sumopt = SummaryOpt,
   	@seqgroup = GroupNum, @markupopt = MarkupOpt, @groupnum = GroupNum,
   	@flatamtopt = FlatAmtOpt, 
   	@flatamt = case Type when 'A' then 
   		case FlatAmtOpt when 'A' then AddonAmt else 0 end else 0 end,
   	@markuprate = case MarkupOpt
       	when 'T' then case when @taxcode is not null then
       		isnull(@taxrate,0) else MarkupRate end
       	when 'R' then case when @contract is null
       		then MarkupRate else case MarkupRate when 0
       		then isnull(@retpct,MarkupRate) else MarkupRate end end
   		when 'D' then case when isnull(@discrate,0)<>0 then
   			case MarkupRate when 0 then @discrate else MarkupRate end
   			else MarkupRate end
   		when 'S' then case when isnull(@jccimarkuprate,0) <> 0 then
   			case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
   			else MarkupRate end
      		else MarkupRate end,
   	@addlmarkup = case Type 
   		when 'A' then case FlatAmtOpt when 'A' then 0 
   			else AddonAmt end 
   		else AddonAmt end
   from JBTS with (nolock)
   where JBCo = @jbco and Template = @template and Seq = @seq
   if @@rowcount = 0
   	begin
    	select @msg = 'Invalid template sequence!', @rcode = 1
    	goto bspexit
    	end
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTemplateSeqVal] TO [public]
GO
