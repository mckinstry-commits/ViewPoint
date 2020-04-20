SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARFinanceChgCalcManual    Script Date: 8/28/99 9:36:43 AM ******/
   CREATE proc [dbo].[bspARFinanceChgCalcManual]
   /***********************************************************
   * CREATED BY	: CJW 07/17/97
   * MODIFIED By	: CJW 07/17/97
   * MODIFIED BY	: GR 07/29/99 For Invoice Type - Invoice Num not required
   *                  				Added parameter to return AmtDue if type is Account
   *                        		For Invoice Type to create a record at line level - added an additional check is AmtDue>0
   * 		GR 11/16/99 changed to get the Receivable Type from ARCO instead of ARRT
   *     	GR 11/19/99 corrected the where clause for calculating the
   *                 	Exisiting Finance Charges if the flag in company parameters is
   *                 	set not to include exisiting finance charges
   *     	GR 11/22/99 Added duedate in the where clause to calculate exisiting finance
   *                	charges if flag is set to no
   *     	GR 01/20/00 Record is created in Batch table only if Amount due  is greater than zero
   *     	GR 06/27/00 Corrected the default of GLAcct if FCLevel in ARCO is calculate finance charges,
   *                 	but no job cost update and also when there is no contract use finance charge
   *                  	GL Account based on receivable type not the Accounts Receivable GL Account issue 7206
   *     	GR 07/3/00 For Invoice type, got the invoice number from ARTH based on ARTrans and Month to insert
   *                     	into header
   *      	GR 07/05/00 Added an input parameter duedatecutoff to bspARFCAmtDueLineForInvoice stored procedure
   *     	GG 07/07/00 Fixed isnull on GL Finance Charge Account assignment
   *     	GR 10/13/00 Added to skip the line if amount due is less than FCMinBal for invoice type
   *      	bc 05/14/01 - corrected the select statement that fills the temp table to join
   *                 	ARRT.RecType = ARCO.FCRecType instead of equal to ARCO.RecType.
   *                 	incorrect gl accts was what brought this to our attention
   *		TJL 05/30/01 - Overhaul.  Calculate Finance charges correctly based on DueDateCutOff, PaidDateCutOff,
   *					correct calculations based on adjustments, credits, writeoffs, retainage and payments and
   *					to include or not include FC in the calculations.  To properly calculate or clear existing FC
   *					already in batch.
   *		TJL 06/13/01 - Modify to use Invoice Number passed in from Manual Form when AUTONUM set to 'N' and
   *					to allow multiple manual FC records for the same Customer.
   *		TJL 06/27/01 - This is a reproduction of bspARFinanceChgCalc with modifications to process Finance Charges
   *					on a single Account or Invoice.  ***ALL PREVIOUS mods came from original stored procedure ***
   *		TJL 06/28/01 - Modify to bring in BatchSeq from form as well as to allow updates to an existing sequence.
   *		TJL 07/30/01 - Fixed 'On Invoice' with Contract, to bring the correct GLCo for the Contract Company if 'JC Update YES or NO'
   *		TJL 08/01/01 - Fixed so when MinFCBal = 0.00, program gets next Customer or ARTrans.  (No Calculations)
   *		TJL 03/05/02 - Issue #14171, Add BY RECTYPE option, Exclude by Contract and by
   *					Invoice option, and performance mods.
   *		TJL 06/04/02 - Issue #17549,  Add Invoice, Mth, Transaction to Line Description.
   *		TJL 02/17/03 - Issue #20107,  "If exist(select 1 ...) & On Acct - update bARBL set FinanceChg = ...
   *		TJL 07/21/03 - Issue #21888, Performance Mods - Add (with (nolocks)
   *		TJL 02/04/04 - Issue #23642, Insert TaxGroup into bARBL where necessary
   *		TJL 05/19/05 - Issue #28741, 6x rewrite.  Add MatlGroup, Material to ARBL Insert on FCType "I"
   *		TJL 10/15/07 - Issue #125729, Add INCo, Loc information for FCTypes "I" and "R"
   *			
   *			
   *
   * USAGE:
   * Calculate finance charges for use in ARFinChg program
   *
   * INPUT PARAMETERS
   *   ARCo
   *   Month
   *   BatchId
   *   Beginning Customer
   *   Ending Customer
   *   Options from Calculation form (S)kip customer - or (R)ecalculate)
   *   Transaction Date
   *   DueDate Cutoff
   *   Paid date cutoff
   * OUTPUT PARAMETERS
   *   @errmsg
   *
   * RETURN VALUE
   *   returns - 
   *
   *****************************************************/
   (@arco bCompany=null, @armth bMonth=null, @batchid bBatchID, @batchseq int,
   	@transdate bDate, @duedatecutoff bDate = null, @paiddatecutoff bDate = null,
	@Customer bCustomer = Null, @options varchar(1), @manual varchar(1) = null, 
   	@ARTrans bTrans = null, @applymth bDate = null, @InvoiceNum varchar(10) = null,
   	@findrectype int = null, @errmsg varchar(255) output)
   as
   set nocount on
   declare @rcode int, @CustGroup bGroup, @FCType char(1), @FCPct bPct,  
   	@GLCo int, @GLARAcct bGLAcct, @GLFinChgAcct bGLAcct, @FCMinBal bDollar, @FCMinChrg bDollar,
   	@FCCalcOnFC bYN, @AutoNumYN bYN, @RecType int, @newrectype int, @oldrectype int,
   	@originv varchar(10), @Num int, @nextseq int, @payterms bPayTerms,
   	@AmtDue bDollar, @originvamt bDollar, @currinvamt bDollar, @FCFinOrServ varchar(1),
   	@duedate bDate, @discdate bDate, @discrate bPct, @validcnt int, @validcnt2 int,
   	@Mth bDate, @ARLine int, @FCLevel tinyint, @excludecontract char(1),
   	@opentranscursor tinyint, @openlinecursor tinyint, @numrows smallint, 
   	@linedesc varchar(30), @taxgroup bGroup, @linetaxgroup bGroup, @linetaxcode bTaxCode, 
   	@matlgroup bGroup, @material bMatl, @inco bCompany, @loc bLoc, @um bUM, @ecm bECM, @msg varchar(60)
   
   /* declare Contract related variables */
   declare  @JCCo int, @Contract bContract, @ContractItem bContractItem 
   --	@placeholder1 bTaxCode, @placeholder2 bPct, @placeholder3 bUnitCost,
   --	@InvRTGLCo bCompany, @InvRTFinChgAcct bGLAcct, @UM bUM,
    
   select @opentranscursor = 0, @openlinecursor = 0, @rcode = 0 
   
   IF @arco is null
   	begin
      	select @rcode=1,@errmsg='ARCo is missing'
      	goto error
      	end
   IF @armth is null
      	begin
      	select @rcode=1,@errmsg='Mth is missing'
      	goto error
      	end
   If @duedatecutoff is null
   	begin
   	select @duedatecutoff = getdate()
   	end
   If @paiddatecutoff is null
   	begin
   	select @paiddatecutoff = getdate()
   	end
   
   /* Get Finance Charge level and AutoNum option from AR Company */
   select @FCLevel = a.FCLevel, @AutoNumYN = a.InvAutoNum, @taxgroup = h.TaxGroup
   from bARCO a with (nolock)
   join bHQCO h with (nolock) on h.HQCo = a.ARCo
   where a.ARCo = @arco
   
   /* If the option passed in is 'R' then clear out batch in order to do a recalculation on it */
   IF @options = 'R'
   	begin
    	delete bARBL from bARBL where Co = @arco and Mth = @armth and BatchId = @batchid
      	delete bARBH from bARBH where Co = @arco and Mth = @armth and BatchId = @batchid
      	end
   
   /********************************************************************************/
   /* Get required Customer information.  All conditions cannot be 				*/
   /* checked here, so some will be checked at a later time						*/
   /*																				*/
   /* Conditions checked here are as follows:										*/
   /* 	Finance charge level is 2	(Calc Finance Charges for this customer)		*/
   /*	Finance charge type is on (A)ccount or by (I)nvoice	or by (R)ecType			*/
   /*	Customers FC % or Company FC % > 0											*/
   /*																				*/
   /********************************************************************************/
   
   select distinct @CustGroup =  ARCM.CustGroup, @FCType = ARCM.FCType, @excludecontract = ARCM.ExclContFromFC,
             	@FCPct = case ARCM.FCPct when 0 then ARCO.FCPct else ARCM.FCPct end,
             	@GLCo = ARRT.GLCo, @GLARAcct = ARRT.GLARAcct, @GLFinChgAcct = ARRT.GLFinChgAcct, 
   			@FCMinChrg = ARCO.FCMinChrg, @FCCalcOnFC = ARCO.FCCalcOnFC, 
   			@FCMinBal = ARCO.FCMinBal,
            	@RecType = isnull(ARCO.FCRecType, isnull(ARCM.RecType, ARCO.RecType)),
   			@payterms = ARCM.PayTerms, @FCFinOrServ = ARCO.FCFinOrServ
   from ARCO with (nolock)
   join HQCO with (nolock) on HQCO.HQCo = ARCO.ARCo
   join ARCM with (nolock) on ARCM.CustGroup = HQCO.CustGroup
   join ARRT with (nolock) on ARRT.ARCo = ARCO.ARCo and ARRT.RecType = isnull(ARCO.FCRecType, isnull(ARCM.RecType, ARCO.RecType))
   where ARCO.FCLevel > 1 
   	and (ARCM.FCType ='A' or ARCM.FCType = 'I' or ARCM.FCType = 'R') 
   	and (ARCM.FCPct > 0 or ARCO.FCPct > 0)
      	and ARCM.Customer = @Customer and ARCO.ARCo = @arco
      	and exists (select 1 
   				from bARTH h with (nolock)
    		   		where h.ARCo = @arco and h.CustGroup = ARCM.CustGroup and h.Customer = isnull(@Customer,ARCM.Customer) )
      	and exists (select 1 
   				from bARMT m with (nolock)
      		      	where m.ARCo = @arco and m.CustGroup = ARCM.CustGroup and m.Customer = isnull(@Customer,ARCM.Customer) )
   
   /* Need to calculate due date based on invoice date and payterms*/
   exec @rcode = bspHQPayTermsDateCalc @payterms, @transdate, @discdate output, @duedate output,
         		@discrate output, @msg output
   
   /*************************/
   /* Start ON ACCOUNT type */
   /*************************/
   if @FCType = 'A'  /* ON ACCOUNT Finance Charges */
   	begin	/* Begin ON ACCOUNT Loop */
      	/* Calculate current amount due for this Account */
    	exec bspARFCAmtDue @arco, @armth, NULL, @CustGroup, @Customer, @duedatecutoff, @paiddatecutoff,
   		NULL, @FCType, @originvamt output, @AmtDue output, @currinvamt output
   
      	/* If the overdue balance is less than MinBal in ARCO then skip this customer */
      	if @AmtDue < @FCMinBal or @AmtDue = 0
      		begin
   		select @errmsg = 'Account Balance Due is less than the FC'
   		select @errmsg = @errmsg + ' Minimum Balance. No Finance Charges calculated!'
      	   	goto bspexit
      	   	end
   
      	/* If the FC is less than MinFC in ARCO then set to MinFC */
     	if @AmtDue * @FCPct < @FCMinChrg
      	  	begin
      	 	select @AmtDue = @FCMinChrg
      	  	end
     	else
       	begin
         	select @AmtDue = @AmtDue * @FCPct
          	end
   
    	/********************************************************/
     	/* After all conditions are met, then we need to 		*/
      	/* enter one line for finance charge ON ACCOUNT			*/
      	/* for this customer.									*/
      	/********************************************************/
   
   	if isnull(@AmtDue, 0) <> 0
     		begin
   		update bARBL
   		set RecType = @RecType, GLCo = @GLCo, GLAcct = @GLFinChgAcct, Amount = @AmtDue,
   			FinanceChg = @AmtDue
   		where Co = @arco and Mth = @armth and BatchId = @batchid and BatchSeq = @batchseq
   		select @numrows = @@rowcount
   		if @numrows = 0
   			begin
      	    	insert into bARBL(Co, Mth, BatchId, BatchSeq, TransType, ARLine, RecType, LineType, Description,
      				GLCo, GLAcct, TaxGroup, Amount, FinanceChg)
      			values (@arco, @armth, @batchid, @batchseq, 'A', 1, @RecType, 'F', case @FCFinOrServ when 'F' then 'Finance Charge' else 'Service Charge' end,
      				@GLCo, @GLFinChgAcct, @taxgroup, @AmtDue, @AmtDue)
   			end
         	end
      	end  /* End ON ACCOUNT Loop */
   
   /*************************/
   /* Start BY INVOICE type */
   /*************************/
   if @FCType = 'I'   /* BY INVOICE Finance Charges */
   	begin	/* Begin BY INVOICE Loop */
   	/* Begin manual processing of Finance Charge for this Invoice */
   
   	/* Retrieve GL Account information from this invoices RecType. Though 
   	   it was previously set for this Customer, if we are here, then we need
   	   this same information specifically from the RecType of this invoice. */
    	select @RecType = h.RecType, @GLFinChgAcct = t.GLFinChgAcct,	
     		@GLCo = t.GLCo, @GLARAcct = t.GLARAcct,
   		@JCCo = h.JCCo, @Contract = h.Contract 	 	  		
   	from bARTH h with (nolock)
   	join bARRT t with (nolock) on h.ARCo = t.ARCo and h.RecType = t.RecType
   	where h.ARCo = @arco and h.Mth=@applymth and h.ARTrans = @ARTrans
   
   	/* We will first get total amount due for this Invoice so we can compare against the Min Balance. 
   	   Since this customer is by 'I' then the Min Bal set in ARCo represents Min Invoice Balance 
          If total amt due is less than min bal then get next Invoice */
   	exec bspARFCAmtDue @arco, @armth, @ARTrans, @CustGroup, @Customer, NULL,
   		@paiddatecutoff,  @applymth, @FCType, @originvamt output, @AmtDue output, @currinvamt output
   
   	/* If the overdue balance of this invoice is less than MinBal in ARCO then skip this ARTrans/Invoice */
   
   	if @AmtDue < @FCMinBal or @AmtDue = 0
		begin
   		select @errmsg = 'Invoice Balance Due is less than the FC'
   		select @errmsg = @errmsg + ' Minimum Balance. No Finance Charges calculated!'
		goto bspexit
		end
   
   	/* If existing lines exist for this Sequence, delete all lines before processing at the line level. */
   	select @numrows = count(*)
   	from bARBL
   	where Co = @arco and Mth = @armth and BatchId = @batchid and BatchSeq = @batchseq
   	if @numrows > 0
   		begin
   		delete bARBL
   		where Co = @arco and Mth = @armth and BatchId = @batchid and BatchSeq = @batchseq
   		end
   
   	/************************************************************************************/
   	/* We now need to spin through all of the lines of the header and calculate 		*/
   	/* the Finance Charge for each line.  Will create a cursor to do this.		  		*/
   	/************************************************************************************/
   	declare bcARLine cursor local fast_forward for
   	select l.ARLine, l.Item, l.TaxGroup, l.TaxCode, l.MatlGroup, l.Material, 
		l.INCo, l.Loc, l.UM, l.ECM
   	from bARTL l with (nolock)
   	where l.ARCo = @arco and l.ApplyMth = @applymth and l.ApplyTrans = @ARTrans
   		and l.Mth = l.ApplyMth and l.ARTrans = l.ApplyTrans
   
   	open bcARLine
   	select @openlinecursor = 1
   
   	fetch next from bcARLine into @ARLine, @ContractItem, @linetaxgroup, @linetaxcode, @matlgroup, @material,
		@inco, @loc, @um, @ecm
   	while @@fetch_status = 0
   		begin	/* Begin ARLine Loop */
   
        	/* Need to calculate due date based on invoice date and payterms*/
        	--exec @rcode = bspHQPayTermsDateCalc @payterms, @transdate, @discdate output, 
   		--	@duedate output, @discrate output, @msg output
   
        	/*Need to get Contract Open Revenue GL Account and Company if it's a Contract type */
      	 	--if @FCLevel = 3 and (@JCCo is not null) and (@Contract is not null) 
   		--		and (@ContractItem is not null)
      	 		--begin
      		  	--exec bspJCCIValWithInfo @JCCo, @Contract, @ContractItem, @placeholder1 output, @placeholder2 output,
      				--@GLFinChgAcct output, @GLCo output, @UM output, @placeholder3 output, @msg output
      		 	--end
   
        	/* We need to calculate current amount due for this line */
       	exec bspARFCAmtDueLineForInvoice @arco, @CustGroup, @Customer, @applymth, @ARTrans, 
   			@ARLine, @duedatecutoff, @paiddatecutoff, null, @AmtDue output, @linedesc output
   
   		/* Begin Inserting Lines */
  		insert into bARBL(Co, Mth, BatchId, BatchSeq, TransType, ARLine, JCCo, Contract, 
			Item, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode, Amount, FinanceChg,
			ApplyMth, ApplyTrans, ApplyLine, MatlGroup, Material, INCo, Loc, UM, ECM)
  		values (@arco, @armth, @batchid, @batchseq, 'A', @ARLine, @JCCo, @Contract, 
			@ContractItem, @RecType, 'F', 
			case @FCFinOrServ when 'F' then 'Finance Charge' else 'Service Charge' end,
			@GLCo, @GLFinChgAcct, @linetaxgroup, @linetaxcode, (@FCPct * @AmtDue), (@FCPct * @AmtDue),
			@applymth, @ARTrans, @ARLine, @matlgroup, @material, @inco, @loc, @um, @ecm)
   
   		/* get the next line to calculate */
    nextARLine:
   		fetch next from bcARLine into @ARLine, @ContractItem, @linetaxgroup, @linetaxcode, @matlgroup, @material,
			@inco, @loc, @um, @ecm
		end  	/* End ARLine loop */
   
   		if @openlinecursor = 1
   			begin
   			close bcARLine
   			deallocate bcARLine
   			select @openlinecursor = 0
   			end
   	end	/* End BY INVOICE Loop */
   
   /*************************/
   /* Start BY RECTYPE type */
   /*************************/
   if @FCType = 'R'   /* BY RECTYPE Finance Charges */
   	begin
   	select @ARLine = 1
   	/* For each Customer, get all original ARTrans whos DueDate in ARTH is less
   	   than the DueDateCutOff. Though the cursor will contain all invoices for this
   	   customer, they will be processed in such a manner as to create a single header
   	   per RECTYPE and it's detail lines will be represented by a single line, per
   	   invoice, containing the total FC amount for the invoice. */
   
   	/* Declare Cursor to Keep track of original ARTrans for this Customer that are
   	   1)	Equal to or earlier than the DueDateCutOff
   	   2)	Exclude Contract Invoices if ARCM.ExclContFromFC is set to 'Y'
   	   3)	Exclude any Invoices if ARTH.ExcludeFC is set to 'Y' 
   	   4)	For User Input RecType only */
   	declare bcGetARTrans cursor local fast_forward for
   	select h.ARTrans, h.Mth, h.Invoice
   	from bARTH h with (nolock)
   	where h.ARCo = @arco and h.CustGroup = @CustGroup and h.Customer = @Customer
   		and h.Mth = h.AppliedMth and h.ARTrans = h.AppliedTrans 
   		and h.DueDate <= @duedatecutoff
   		and	h.ExcludeFC = 'N'
   		and isnull(h.Contract, '') = isnull((case when @excludecontract = 'N' then h.Contract else Null end), '')
   		and h.RecType = @findrectype
   	order by h.Invoice, h.Mth, h.ARTrans
   
   	open bcGetARTrans
   	select @opentranscursor = 1
   
   	/* spin through the record set of past due invoices for this customer */
   	fetch next from bcGetARTrans into @ARTrans, @applymth, @originv
   		while @@fetch_status = 0
   			begin	/* Begin Transaction Loop */
   			/* Retrieve GL Account information from this invoices RecType. Though 
   			   it was previously set for this Customer, if we are here, then we need
   			   this same information specifically from the RecType of this invoice. */
      		select @RecType = h.RecType, @GLFinChgAcct = t.GLFinChgAcct,	
     			@GLCo = t.GLCo, @GLARAcct = t.GLARAcct,
   				@JCCo = h.JCCo, @Contract = h.Contract,
				@inco = (select top 1 l.INCo from bARTL l with (nolock) where l.ARCo = @arco and l.Mth=@applymth and l.ARTrans = @ARTrans),
				@loc = (select top 1 l.Loc from bARTL l with (nolock) where l.ARCo = @arco and l.Mth=@applymth and l.ARTrans = @ARTrans)	 	 	  		
   			from bARTH h with (nolock)
   			join bARRT t with (nolock) on h.ARCo = t.ARCo and h.RecType = t.RecType
      		where h.ARCo = @arco and h.Mth=@applymth and h.ARTrans = @ARTrans
   
   			/* We will first get total amount due for this Invoice so we can compare against the Min Balance. 
   			   Since this customer is by 'I' then the Min Bal set in ARCo represents Min Invoice Balance 
      	       If total amt due is less than min bal then get next Invoice */
      		exec bspARFCAmtDue @arco, @armth, @ARTrans, @CustGroup, @Customer, NULL,
      		@paiddatecutoff,  @applymth, @FCType, @originvamt output, @AmtDue output, @currinvamt output
   
  	  		/* If the overdue balance of this invoice is less than MinBal in ARCO then skip this ARTrans/Invoice */
  	    	if @AmtDue < @FCMinBal or @AmtDue = 0
  	     		begin
  	    		goto nextARTrans
  	       		end
   
   			/* Insert one line for each invoice Finance Charge */
  			insert into bARBL(Co, Mth, BatchId, BatchSeq, TransType, ARLine, JCCo, Contract, 
				RecType, LineType, Description, GLCo, GLAcct, TaxGroup, Amount, FinanceChg,
				rptApplyMth, rptApplyTrans, INCo, Loc)
  			values (@arco, @armth, @batchid, @batchseq, 'A', @ARLine, @JCCo, @Contract, 
				@RecType, 'F', 
				@originv + ',  ' + convert(varchar(8), @applymth, 1) + ',  ' + convert(varchar(6), @ARTrans),
				@GLCo, @GLFinChgAcct, @taxgroup, (@FCPct * @AmtDue), (@FCPct * @AmtDue),
				@applymth, @ARTrans, @inco, @loc)
   
   			/* increment ARLine count now, after a line has been inserted. */
   			select @ARLine = @ARLine + 1
   
      		/*get next transaction */
		nextARTrans:
   			fetch next from bcGetARTrans into @ARTrans, @applymth, @originv
   			end	/*End ARTrans Loop */
   
		if @opentranscursor = 1
			begin
			close bcGetARTrans
			deallocate bcGetARTrans
			select @opentranscursor = 0
			end
   	
   	end   /* End FCTYPE of R */
   
   select @rcode = 0
   select @errmsg = 'Finance charge calculations complete!'
   error:
   if @rcode<>0 select @errmsg=@errmsg		--+ char(13) + char(10) + '[bspARFinanceChgCalcManual]'
   
   bspexit:
   if @openlinecursor = 1
   	begin
   	close bcARLine
   	deallocate bcARLine
   	end
   if @opentranscursor = 1
   	begin
   	close bcGetARTrans
   	deallocate bcGetARTrans
   	select @opentranscursor = 0
   	end
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARFinanceChgCalcManual] TO [public]
GO
