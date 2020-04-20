SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspJBTandMProcessAmtforInit    Script Date: 8/28/99 9:32:34 AM ******/
   CREATE proc [dbo].[bspJBTandMProcessAmtforInit]
   /***********************************************************
   * CREATED BY	: kb 12/7/00
   * MODIFIED BY	: kb 8/22/1 - issue #14367
   *  		kb 9/7/1 - issue #14367
   *		TJL 08/25/03 - Issue #20471, Place Amount Addon Value on a specified item
   *		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure 
   *		TJL 03/31/04 - Issue #24189, Check for invalid Template Seq Item
   *		TJL 09/23/04 - Issue #25622, Remove TempTable (#JBIDTemp), use permanent table bJBIDTMWork
   *		TJL 10/05/05 - Issue #29082, Contract Bill when T&M template has 2 "A" sequences, both show on Bill Item #1
   *		TJL 09/25/06 - Issue #121269 (5x - #121253), Correct JCTransactions being place on two bills when initialized simultaneously
   *		EN/KK 7/12/2011 - D-01887 / TK-06698 / #143971  if init'ing by bill group get orig/curr contract amounts from JCCI rather than JCCM
   *
   * USED IN:
   *	bspJBTandMInit
   *
   * USAGE:
   *
   * INPUT PARAMETERS
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs
   *
   * RETURN VALUE
   *   0		Success
   *   1		Not Valid at this time
   *	10		bJBCE logged LineKey/Line Number Failure
   *	11		bJBCE logged Invalid Template Seq Item Failure
   *	99		bJBCE logged 10, 11, 12 Undetermined Failure
   *
   *****************************************************/
   
   (@co bCompany,  @template varchar(10), @contract bContract,
   @item bContractItem, @itembillgroup bBillingGroup, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @tempseq int, @jbflatbillingamt bDollar, @flatamtopt char(1),
   	@basis bDollar, @currentcontract bDollar, @origcontractamt bDollar,
   	@markupopt char(1), @markuprate bRate, @newline int, @tempseqgroup int,
   	@seqdesc varchar(128), @linekey varchar(100),
   	@addlmarkup bDollar, @tempseqitem bContractItem,
   	@seqitemrcode int, @seqitemerrmsg varchar(255), @linercode int, @lineerrmsg varchar(255)
   
   select @rcode = 0
   
   select @jbflatbillingamt = JBFlatBillingAmt, @origcontractamt = OrigContractAmt,
   	@currentcontract = ContractAmt
   from bJCCM with (nolock)
   where JCCo = @co and Contract = @contract

  /* New Code */
  if @itembillgroup is not null
        begin
        select @origcontractamt = sum(i.OrigContractAmt), @currentcontract = sum(i.ContractAmt)
        from bJCCI i
        join bJBBG g on g.JBCo = i.JCCo and g.Contract = i.Contract and g.BillGroup = i.BillGroup
        where g.JBCo = @co and g.Contract = @contract and g.BillGroup = @itembillgroup
        end
 
   select @tempseq = min(Seq) 
   from bJBTS with (nolock)
   where JBCo = @co and Template = @template and Type = 'A'
   
   while @tempseq is not null
   	begin
       if exists (select 1 from bJBIDTMWork with (nolock) where TemplateSeq = @tempseq and JBCo = @co and VPUserName = SUSER_SNAME()) goto Next
       select @flatamtopt = FlatAmtOpt,
       	@addlmarkup = case FlatAmtOpt when 'A' then 0 else AddonAmt end, 
   		@markupopt = MarkupOpt,
       	@basis = case FlatAmtOpt 
   			when 'F' then @jbflatbillingamt
         		when 'O' then @origcontractamt 
   			when 'C' then @currentcontract
         		when 'A' then AddonAmt else 0 end, 
   		@markuprate = MarkupRate, @seqdesc = Description, @tempseqgroup = GroupNum,
   		@tempseqitem = ContractItem
    	from bJBTS with (nolock)
   	where JBCo = @co and Template = @template and Seq = @tempseq
   
   	/* If Template Seq Item is NULL, process as always. (Place 'A' on first JCJP Item)
   	   If Template Seq Item is NOT NULL and JCJP Item is equal then Place 'A' on this JCJP Item
   	   If Template Seq Item is NOT NULL but JCJP Item is not equal then skip. 
   
   	   ****** NOTE ******
   	   This procedure only runs for Items associated with a Job Phase or for Field Centrix related
   	   transactions therefore:
   
   	   For reoccuring Flat Amount Charges against a particular Item, user should consider using a
   	   Total Addon, No Markup with Addon Amount.  In this way, Item does not have to be associated
   	   with a phase. */
   	if @tempseqitem is not null
   		begin
   		/* Need to check if Template Seq Item is not valid for this contract. */
   		if not exists(select 1 from bJCCI with (nolock) 
   				where JCCo = @co and Contract = @contract and Item = @tempseqitem) 
   			begin
   			select @seqitemerrmsg = 'The specified Contract Item: ' + @tempseqitem + ', on seq#: '  
   			select @seqitemerrmsg = @seqitemerrmsg + convert(varchar(10), @tempseq) + ', is invalid for Contract: ' 
 
   			select @seqitemerrmsg = @seqitemerrmsg + @contract + ', and the Amount sequence was not processed.'
   			select @seqitemrcode = 11
   			goto Next
   			end
   
   		/* If Template Seq Item is valid but not same as Contract Item from bJCJP or
   		   bJCCI (For No-Cost Contracts), move on to next sequence. */
   		if @item <> @tempseqitem goto Next
   		end
   
       exec @rcode = bspJBTandMGetLineKey @co, null, null,
      		null, @item, @template, @tempseq, null, null, @tempseqgroup,
       	'N', @linekey output, @msg output
   	if @rcode <> 0
   		begin
   		/* Log an error in bJBCE, skip this Amount sequence but keep going to next. */
   		select @lineerrmsg = 'Failed to retrieve LineKey and therefore Amount for seq#: '
   		select @lineerrmsg = @lineerrmsg + convert(varchar(10), @tempseq)
   		select @lineerrmsg = @lineerrmsg + ', was skipped for Contract: ' + @contract
   		select @linercode = 10
   		end
   	else
   		begin
   	    insert bJBIDTMWork (JBCo, VPUserName, Contract, Item, TemplateSeq, TemplateSeqType, StdPrice,
   	      Units, UnitPrice, Hours,
   	      SubTotal,
   	      MarkupOpt, MarkupRate,
   	      MarkupAddl, MarkupTotal,  Retainage,
   	      Total,
   	      Template, TemplateSeqGroup,
   	      LineKey, AppliedToSeq, LineType ,Discount, DetailKey)
   	    select  @co, SUSER_SNAME(), @contract, @item, @tempseq, 'A', 0,
   	      0, 0, 0,
   	      /*amt*/@basis,
   	      @markupopt, @markuprate,
   	      @addlmarkup, 0,0,
   	      /*total*/@basis + @addlmarkup,
   	      @template, @tempseqgroup,
   	      @linekey, @tempseq, 'A', 0, 'none'
   		end
  
   Next:
       select @tempseq = min(Seq) 
   	from bJBTS with (nolock)
   	where JBCo = @co and Template = @template and Type = 'A' and Seq > @tempseq
       	--and not exists(select 1 from bJBIDTMWork with (nolock) where TemplateSeq = @tempseq and JBCo = @co and VPUserName = SUSER_SNAME())	Iss#29082
       end
   
   bspexit:
   /* Reset @rcode to one of the special rcodes for logging into bJBCE error log.  The 
      Amount sequence process is not interrupted for one of these errors, the sequence is simply
      skipped.  It is unlikely that multiple errors will occur but if they do we will 
      record only "One" based upon a priority system.  User should resolve the problem
      and re-initialize this Contract. */
   if @seqitemrcode is not null or @linercode is not null
   	begin
   	select @rcode = isnull(@linercode, isnull(@seqitemrcode, 99))
   	select @msg = case @rcode when @linercode then isnull(@lineerrmsg, 'Error text missing.')
   				when @seqitemrcode then isnull(@seqitemerrmsg, 'Error text missing.') else 'Unknown Error.' end
   	end
   
   /* The returned @rcode may be 0 - Success, 
      10 - Line Numbering Failure, 11 - Invalid Seq Item Failure, 
      99 - Unknown but related to 10, 11 Failure. */
   return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBTandMProcessAmtforInit] TO [public]
GO
