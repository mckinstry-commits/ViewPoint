SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspJBContractLimitVal]
   /****************************************************************************
   * Created:   RM 02/07/01
   *		kb 7/24/1 - issue #13454
   *		kb 9/26/1 - issue #14664
   *		TJL 07/17/02 - Issue #17144, Get proper MarkupRates when field changes
   *		TJL 10/29/02 - Issue #18907, Correct LimitOpt Check and Warning Code
   *		TJL 06/16/03 - Issue #21322, Return error message if Contract Item not Valid
   *		TJL 09/30/04 - Issue #25612, Add MarkupOpt (H - Rate by Hour) to Detail Addons, Fix @markuprate bUnitCost
   *		TJL 05/26/06 - Issue #28227, 6x Rewrite:  OverLimitYN flag set based upon this bill and earlier.  same as Backend
   *
   *
   * Usage:
   *	This is used to get the Limit option for the contract item
   *	and validate the contract item.
   *
   *******************************************************************************/
   (@jbco bCompany, @mth bMonth, @billnum Int, @contract bContract,
   	@contractitem bContractItem, @source char(1), @invdate bDate, @template varchar(10),
   	@templateseq int,
   	@markuprate bUnitCost output, @taxgroup bGroup output, @taxcode bTaxCode output, @taxrate bRate output, 
   	@OverLimit bYN output,  @msg varchar(255) output)
   as
   
   declare @rcode int,@LimitOpt char(1),@JBITbilledamt bDollar,@contractamt bDollar,
   	@taxinterface bYN, @payterms bPayTerms, @discrate bPct, @retgpct bPct,
   	@billtype char(1) 
   
   /***** Procedure never runs for Non-Contract Bills since Item does not exist or change *****/
   
   /* Get Discount Rate */
   select @payterms = PayTerms
   from bJBIN with (nolock)
   where JBCo = @jbco and BillMonth = @mth and BillNumber = @billnum
   
   select @discrate = DiscRate from bHQPT with (nolock) where PayTerms = @payterms
   
   /* Get TaxCode and RetainPct from Contract.Item */
   select @taxgroup = TaxGroup, @taxcode = TaxCode, @retgpct = RetainPCT 
   from bJCCI with (nolock)
   where JCCo = @jbco and Contract = @contract and Item = @contractitem
   if @@rowcount = 0
   	begin
   	select @msg = 'This is not a valid Item for Contract: ' + @contract, @rcode = 1
   	goto bspexit
   	end
   
   /* Get Tax Rate */
   if @taxcode is not null
   	begin
   	exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,	@taxrate output, @msg = @msg output
   	end
   
   /* Send appropriate rate back for this MarkupOpt */
   select @markuprate = case MarkupOpt
   	when 'T' then case when @taxcode is not null then
       	isnull(@taxrate,0) else MarkupRate end
   	when 'R' then case MarkupRate when 0 then isnull(@retgpct,MarkupRate)
   			else MarkupRate end
   	when 'D' then case when isnull(@discrate,0)<>0 then
   		case MarkupRate when 0 then @discrate else MarkupRate end
   		else MarkupRate end
   		else MarkupRate end
   from bJBTS with (nolock) 
   where JBCo = @jbco and Template = @template and Seq = @templateseq 
   
   /* Begin OverLimit Checks - Because this is used by TMBillLines, which are Item oriented,
      we only need to perform the check if OverLimitOpt = 'I'.  This will cause an error to
      display on the TMBillLines form for any Item which is currently over limit.  This 
      error is determined, on the fly, and is NOT saved in a Table.  (In this way, it differs
      from how JBTMBillEdit Form works which saves this error to bJBBE).  In addition, 
      OverLimit by Contract will display only on the Header form JBTMBillEdit. */
   select @OverLimit = 'N'
   
   select @LimitOpt = JBLimitOpt, @taxinterface = TaxInterface
   from JCCM with (nolock)
   where JCCo = @jbco and Contract = @contract
   
   if @LimitOpt <> 'I'		
   goto bspexit
   
   /* As user selects a JBTMBill Line, if Item changes, we need to get up to the moment 
      Item values for all Current Bills to be compared with the current ContractAmt 
      (including ChangeOrders) for this Item.  To keep it simple, we only need to look
      in bJBIT for the sum(AmtBilled) for this Contract/Item (Current Billed amounts) and
      compare it to bJCCI.ContractAmt (Current Contract amount, including Change Orders 
      for this Item). */
   
   /* Get Total Billed Amount for this Item */
   select @JBITbilledamt = sum(t.AmtBilled) + 
   	case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end
   from bJBIT t with (nolock)
   join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   where t.JBCo = @jbco and t.Contract = @contract and t.Item = @contractitem
	and n.InvStatus <> 'D'
	and (t.BillMonth < @mth or (t.BillMonth = @mth and t.BillNumber <= @billnum))
   
   /* Get Current Contract Amount for this Item */
   select @billtype = BillType, @contractamt = ContractAmt		--Includes Change Orders
   from bJCCI with (nolock)
   where JCCo = @jbco and Contract = @contract and Item = @contractitem
   
   if @billtype in ('B', 'T')
   	begin
   	if @JBITbilledamt > @contractamt
   		begin
   		select @OverLimit = 'Y'
   		end
   	end
   else
   	begin
   	select @msg = 'This Item is not BillType (B) or (T). Item may not be added.', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBContractLimitVal] TO [public]
GO
