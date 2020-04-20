SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARFinanceChgCalc    Script Date: 8/28/99 9:36:43 AM ******/
CREATE proc [dbo].[bspARFinanceChgCalc]
/**********************************************************
* CREATED BY	: CJW 07/17/97
* MODIFIED By	: CJW 07/17/97
* 		GR 07/29/99 For Invoice Type - Invoice Num not required
*                          	Added parameter to return AmtDue if type is Account
*                        	For Invoice Type to create a record at line level - added an additional check is AmtDue>0
*      	GR 11/16/99 changed to get the Receivable Type from ARCO instead of ARRT
*    	GR 11/19/99 corrected the where clause for calculating the
*                 	Exisiting Finance Charges if the flag in company parameters is
*                 	set not to include exisiting finance charges
*    	GR 11/22/99 Added duedate in the where clause to calculate exisiting finance
*                 	charges if flag is set to no
*    	GR 01/20/00 Record is created in Batch table only if Amount due  is greater than zero
*     	GR 06/27/00 Corrected the default of GLAcct if FCLevel in ARCO is calculate finance charges,
*               	but no job cost update and also when there is no contract use finance charge
*                	GL Account based on receivable type not the Accounts Receivable GL Account issue 7206
*     	GR 07/3/00 For Invoice type, got the invoice number from ARTH based on ARTrans and Month to insert
*                	into header
*     	GR 07/05/00 Added an input parameter duedatecutoff to bspARFCAmtDueLineForInvoice stored procedure
*    	GG 07/07/00 Fixed isnull on GL Finance Charge Account assignment
*    	GR 10/13/00 Added to skip the line if amount due is less than FCMinBal for invoice type
*     	bc 05/14/01 - corrected the select statement that fills the temp table to join
*             		ARRT.RecType = ARCO.FCRecType instead of equal to ARCO.RecType.
*              		incorrect gl accts was what brought this to our attention
*		TJL 05/30/01 - Overhaul.  Calculate Finance charges correctly based on DueDateCutOff, PaidDateCutOff,
*					correct calculations based on adjustments, credits, writeoffs, retainage and payments and
*					to include or not include FC in the calculations.  To properly calculate or clear existing FC
*					already in batch.
*		TJL 06/13/01 - Modify to use Invoice Number passed in from Manual Form when AUTONUM set to 'N' and
*					to allow multiple manual FC records for the same Customer.
*		TJL 06/29/01 - Modified and removed code related to creating Manual Finance Charges that is now
*					being accomplished in a separate stored procedure.
*		TJL 07/30/01 - Fixed 'On Invoice' with Contract, to bring the correct GLCo for the Contract Company
*					 if 'JC Update YES or NO'
*		TJL 08/01/01 - Fixed so when MinFCBal = 0.00, program gets next Customer or ARTrans.  (No Calculations)
*		TJL 03/05/02 - Issue #14171, Add BY RECTYPE option, Exclude by Contract and by
*					 Invoice option, and performance mods.
*		TJL 06/04/02 - Issue #17549,  Add Invoice, Mth, Transaction to Line Description.
*		TJL 02/17/03 - Issue #20107,  "If exist(select 1 ...)
*		TJL 03/28/03 - Issue #20392, Allow user to use TransDate as DueDate during Calculations
*		TJL 07/21/03 - Issue #21888, Performance Mods - Add (with (nolocks)
*		TJL 02/04/04 - Issue #23642, Insert TaxGroup into bARBL where necessary
*		TJL 03/17/04 - Issue 24064, Do NOT audit (HQMA) ARCO.InvLastNum during normal processes
*		TJL 05/19/05 - Issue #28741, 6x rewrite.  Add MatlGroup, Material to ARBL Insert on FCType "I"
*		TJL 09/07/06 - issue #30287, Correct ContractItem with no Contract on Customers by 'RecType'
*		TJL 10/15/07 - Issue #125729, Add INCo, Loc information for FCTypes "I" and "R"
*
* USAGE:
* 	Calculate finance charges for use in ARFinChg program
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
*
* OUTPUT PARAMETERS
*   @errmsg
*
* RETURN VALUE
*   returns - not sure yet
*
******************************************************************************************/
(@arco bCompany=null, @armth bMonth=null, @batchid bBatchID, 
	@transdate bDate, @duedatecutoff bDate = Null, @paiddatecutoff bDate = null,
   	@Customer bCustomer = Null, @options varchar(1), @findrectype int = null,
   	@transdateYN bYN,	@errmsg varchar(255) output)
as
set nocount on
declare @rcode int, @CustGroup bGroup, @FCType char(1), @FCPct bPct,  
   	@GLCo int, @GLARAcct bGLAcct, @GLFinChgAcct bGLAcct, @FCMinBal bDollar, @FCMinChrg bDollar,
   	@FCCalcOnFC bYN, @AutoNumYN bYN, @RecType int, @newrectype int, @oldrectype int,
   	@InvoiceNum varchar(10), @originv varchar(10), @Num int, @nextseq int, @payterms bPayTerms,
   	@AmtDue bDollar, @originvamt bDollar, @currinvamt bDollar, @FCFinOrServ varchar(1),
   	@duedate bDate, @discdate bDate, @discrate bPct, @validcnt int, @validcnt2 int,
   	@ARTrans bTrans, @Mth bDate, @ARLine int, @FCLevel tinyint, @applymth bDate,
   	@excludecontract char(1), @opencustcursor tinyint, @opentranscursor tinyint,
   	@openlinecursor tinyint, @linedesc varchar(30), 
   	@taxgroup bGroup, @linetaxgroup bGroup, @linetaxcode bTaxCode, 
   	@matlgroup bGroup, @material bMatl, @inco bCompany, @loc bLoc, @um bUM, @ecm bECM, @msg varchar(60)  
   
/* declare Contract related variables */
declare  @JCCo int, @Contract bContract, @ContractItem bContractItem 
--	@placeholder1 bTaxCode, @placeholder2 bPct, @placeholder3 bUnitCost,
--	@InvRTGLCo bCompany, @InvRTFinChgAcct bGLAcct, @UM bUM,
    
select @rcode = 0, @opencustcursor = 0, @opentranscursor = 0, @openlinecursor = 0
   
if @arco is null
  	begin
  	select @rcode=1,@errmsg='ARCo is missing'
  	goto error
  	end
if @armth is null
  	begin
  	select @rcode=1,@errmsg='Mth is missing'
  	goto error
  	end
if @duedatecutoff is null
	begin
	select @duedatecutoff = getdate()
	end
if @paiddatecutoff is null
	begin
	select @paiddatecutoff = getdate()
	end
   
/* Get Finance Charge level and AutoNum option from AR Company */
select @FCLevel = a.FCLevel, @AutoNumYN = a.InvAutoNum, @taxgroup = h.TaxGroup
from bARCO a with (nolock)
join bHQCO h with (nolock) on h.HQCo = a.ARCo
where a.ARCo = @arco
   
/* If the option passed in is 'R' then clear out batch in order to do a recalculation on it */
if @options = 'R'
	begin
	delete bARBL from bARBL where Co = @arco and Mth = @armth and BatchId = @batchid
  	delete bARBH from bARBH where Co = @arco and Mth = @armth and BatchId = @batchid
  	end
   
/********************************************************************************/
/* we first need to create a Customer cursor to store the customers valid for	*/
/* Finance Charges based on input parameters.  All conditions cannot be 		*/
/* checked here, so some will be checked when spinning through the cursor		*/
/*																				*/
/* Conditions checked here are as follows:										*/
/* 	Finance charge level is 2	(Calc Finance Charges for this customer)		*/
/*	Finance charge type is on (A)ccount or by (I)nvoice	or by (R)ecType			*/
/*	Customers FC % or Company FC % > 0											*/
/*	Restrict by customer if necessary											*/
/********************************************************************************/
   
/* create a Customer cursor and fill with all customers and values that are eligible for FC */
declare bcCustomer cursor local fast_forward for
select distinct ARCM.Customer, ARCM.CustGroup, ARCM.FCType, ARCM.ExclContFromFC,
	case ARCM.FCPct when 0 then ARCO.FCPct else ARCM.FCPct end,
	ARRT.GLCo, ARRT.GLARAcct, ARRT.GLFinChgAcct, ARCO.FCMinChrg, ARCO.FCCalcOnFC, ARCO.FCMinBal,
	isnull(ARCO.FCRecType, isnull(ARCM.RecType, ARCO.RecType)), ARCM.PayTerms, ARCO.FCFinOrServ
from ARCO with (nolock)
join HQCO with (nolock) on HQCO.HQCo = ARCO.ARCo
join ARCM with (nolock) on ARCM.CustGroup = HQCO.CustGroup
join ARRT with (nolock) on ARRT.ARCo = ARCO.ARCo and ARRT.RecType = isnull(ARCO.FCRecType, isnull(ARCM.RecType, ARCO.RecType))
where ARCO.FCLevel > 1 
	and (ARCM.FCType ='A' or ARCM.FCType = 'I' or ARCM.FCType = 'R')
	and (ARCM.FCPct > 0 or ARCO.FCPct > 0)
  	and ARCM.Customer = isnull(@Customer,ARCM.Customer) and ARCO.ARCo = @arco
  	and not exists (select 1 
				from bARBH b with (nolock)
  				where b.CustGroup = ARCM.CustGroup and b.Customer = ARCM.Customer and b.Co = @arco
             		and b.Mth = @armth and b.BatchId = @batchid)
  	and exists (select 1 
			from bARTH h with (nolock)
  			where h.ARCo = @arco and h.CustGroup = ARCM.CustGroup and h.Customer = ARCM.Customer)
  	and exists (select 1 
			from bARMT m with (nolock)
  			where m.ARCo = @arco and m.CustGroup = ARCM.CustGroup and m.Customer = ARCM.Customer)
order by ARCM.Customer
    
/* Open cursor */
open bcCustomer
select @opencustcursor = 1
   
/* Get first customer and begin processing Finance Charges */
fetch next from bcCustomer into @Customer, @CustGroup, @FCType, @excludecontract, @FCPct, 
	@GLCo, @GLARAcct, @GLFinChgAcct, @FCMinChrg, @FCCalcOnFC, @FCMinBal, @RecType, 
	@payterms, @FCFinOrServ
   
while @@fetch_status = 0
   	begin	/* Begin customer loop */
	/* Need to calculate due date based on invoice date and payterms*/
   	exec @rcode = bspHQPayTermsDateCalc @payterms, @transdate, @discdate output, @duedate output,
   		@discrate output, @msg output
   
   	/*************************/
   	/* Start ON ACCOUNT type */
   	/*************************/
   	if @FCType = 'A'  /* ON ACCOUNT Finance Charges */
   		begin
   	   	/* Calculate current amount due for entire customer account. */
		exec bspARFCAmtDue @arco, @armth, NULL, @CustGroup, @Customer, @duedatecutoff, @paiddatecutoff,
   			NULL, @FCType, @originvamt output, @AmtDue output, @currinvamt output
   
  		/* If the overdue balance is less than MinBal in ARCO then skip this customer */
  		if @AmtDue < @FCMinBal or @AmtDue = 0
  	   		begin
  	      	goto nextCustomer
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
  		/* enter one header and one line for finance charge		*/
  		/* on account for the customer							*/
  		/********************************************************/
   
  		/* we first need to grab a sequence number */
		select @nextseq = isnull(max(BatchSeq),0)+ 1 
   		from bARBH
		where Co = @arco and Mth = @armth and BatchId=@batchid
   
   		/* Get an invoice number from ARCO. */
		exec @rcode = bspARNextTrans @arco, @InvoiceNum output, @msg output
   		if @rcode <> 0 goto error
   
    	if isnull(@AmtDue, 0) <> 0
			begin
       		insert into bARBH(Co, Mth, BatchId, BatchSeq, TransType, Source, ARTransType, CustGroup, Customer, RecType,
      				Invoice, Description, TransDate, DueDate, PayTerms)
      		values (@arco, @armth, @batchid, @nextseq, 'A', 'ARFinanceC', 'F', @CustGroup, @Customer, @RecType,
      				@InvoiceNum, case @FCFinOrServ when 'F' then 'Finance Charge' else 'Service Charge' end,
      				@transdate, case @transdateYN when 'N' then @duedate else @transdate end, @payterms)

  	    	insert into bARBL(Co, Mth, BatchId, BatchSeq, TransType, ARLine, RecType, LineType, Description,
  					GLCo, GLAcct, TaxGroup, Amount, FinanceChg)
  			values (@arco, @armth, @batchid, @nextseq, 'A', 1, @RecType, 'F', case @FCFinOrServ when 'F' then 'Finance Charge' else 'Service Charge' end,
  					@GLCo, @GLFinChgAcct, @taxgroup, @AmtDue, @AmtDue)
        	end
		end  /* End FCType of A*/
   
	/*************************/
   	/* Start BY INVOICE type */
   	/*************************/
	if @FCType = 'I'   /* BY INVOICE Finance Charges */
   		begin
   		/* For each Customer, get all original ARTrans whos DueDate in ARTH is less than the DueDateCutOff.     
   		   With this, get each ARLine for each ARTrans and calculate AmtDue for each line then multiply by FCPct */
      
   		/* Declare Cursor to Keep track of original ARTrans for this Customer that are
   		   1)	Equal to or earlier than the DueDateCutOff
   		   2)	Exclude Contract Invoices if ARCM.ExclContFromFC is set to 'Y'
   		   3)	Exclude any Invoices if ARTH.ExcludeFC is set to 'Y' */
		declare bcGetARTrans cursor local fast_forward for
   		select h.ARTrans, h.Mth, h.Invoice
   		from bARTH h with (nolock)
   		where h.ARCo = @arco and h.CustGroup = @CustGroup and h.Customer = @Customer
   			and h.Mth = h.AppliedMth and h.ARTrans = h.AppliedTrans 
   			and h.DueDate <= @duedatecutoff
   			and	h.ExcludeFC = 'N'
   			and isnull(h.Contract, '') = isnull((case when @excludecontract = 'N' then h.Contract else Null end), '')
   			and h.RecType = isnull(@findrectype, h.RecType)
   		order by h.Invoice, h.Mth, h.ARTrans
   
   		open bcGetARTrans
   		select @opentranscursor = 1
   
   		/* spin through the record set of past due invoices for this customer */
   		fetch next from bcGetARTrans into @ARTrans, @applymth, @InvoiceNum
   		while @@fetch_status = 0
   			begin	/* Begin Transaction Loop */
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
  	    		goto nextARTrans
  	       		end
   
      		/* After all conditions are met with amount we need to enter a header record */
      		/* we need to grab the next sequence number from this batch   		*/
      		select @nextseq = isnull(max(BatchSeq),0)+1
   			from bARBH
      		where Co = @arco and Mth = @armth and BatchId = @batchid
   
     		/************************************************************************************/
  	  		/* We now need to spin through all of the lines of the header and calculate 		*/
  	  		/* the Finance Charge for each line.  Will create a cursor to do this		  		*/
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
   
           		/* Need to calculate DueDate based on invoice date and payterms*/
         		exec @rcode = bspHQPayTermsDateCalc @payterms, @transdate, @discdate output, 
   					@duedate output, @discrate output, @msg output
   
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
   
   	  			/*  Add a single header entry for Finance Charge */
				select @validcnt = Count(*)
				from bARBH
               	where Co=@arco and Mth=@armth and BatchId=@batchid and BatchSeq=@nextseq
   
            	select @validcnt2 = Count(*)
            	from bARTL l
  				join bARTH h on l.ARCo = h.ARCo and l.Mth = h.Mth and l.ARTrans = h.ARTrans
  				where h.ARCo = @arco and h.Mth = @applymth and h.ARTrans = @ARTrans
 					and l.ARLine = @ARLine and @AmtDue>0
   
             	if @validcnt = 0 and @validcnt2 > 0
    		 		begin
                   	insert into bARBH(Co, Mth, BatchId, BatchSeq, TransType, Source, ARTransType, 
   						CustGroup, Customer, JCCo, Contract, AppliedMth, AppliedTrans, RecType, 
   						Invoice, Description, TransDate, DueDate, PayTerms)
      		           	values (@arco, @armth, @batchid, @nextseq, 'A', 'ARFinanceC', 'F', 
   						@CustGroup, @Customer , @JCCo, @Contract, @applymth, @ARTrans, @RecType, 
   						@InvoiceNum, case @FCFinOrServ when 'F' then 'Finance Charge' else 'Service Charge' end, @transdate, null, @payterms)
   					end
                    	-- end of inserting header
   
  				insert into bARBL(Co, Mth, BatchId, BatchSeq, TransType, ARLine, JCCo, Contract, 
					Item, RecType, LineType, Description, GLCo, GLAcct, TaxGroup, TaxCode, Amount, FinanceChg,
					ApplyMth, ApplyTrans, ApplyLine, MatlGroup, Material, INCo, Loc, UM, ECM)
  				values (@arco, @armth, @batchid, @nextseq, 'A', @ARLine, @JCCo, @Contract, 
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
   
      		/*get next transaction */
		nextARTrans:
   			fetch next from bcGetARTrans into @ARTrans, @applymth, @InvoiceNum
   			end	/*End ARTrans Loop */
   
		if @opentranscursor = 1
			begin
			close bcGetARTrans
			deallocate bcGetARTrans
			select @opentranscursor = 0
   			end
   	
   		end   /* End FCTYPE of I */
   
   	/*************************/
   	/* Start BY RECTYPE type */
   	/*************************/
	if @FCType = 'R'   /* BY RECTYPE Finance Charges */
   		begin
   		/* For each Customer, get all original ARTrans whos DueDate in ARTH is less
   		   than the DueDateCutOff. Though the cursor will contain all invoices for this
   		   customer, they will be processed in such a manner as to create a single header
   		   per RECTYPE and it's detail lines will be represented by a single line, per
   		   invoice, containing the total FC amount for the invoice. */
   
   		/* Declare Cursor to Keep track of original ARTrans for this Customer that are
   		   1)	Equal to or earlier than the DueDateCutOff
   		   2)	Exclude Contract Invoices if ARCM.ExclContFromFC is set to 'Y'
   		   3)	Exclude any Invoices if ARTH.ExcludeFC is set to 'Y' */
		declare bcGetARTrans cursor local fast_forward for
   		select h.ARTrans, h.Mth, h.RecType, h.Invoice
   		from bARTH h with (nolock)
   		where h.ARCo = @arco and h.CustGroup = @CustGroup and h.Customer = @Customer
   			and h.Mth = h.AppliedMth and h.ARTrans = h.AppliedTrans 
   			and h.DueDate <= @duedatecutoff
   			and	h.ExcludeFC = 'N'
      		and isnull(h.Contract, '') = isnull((case when @excludecontract = 'N' then h.Contract else Null end), '')
   			and h.RecType = isnull(@findrectype, h.RecType)
   		order by h.RecType, h.Invoice, h.Mth, h.ARTrans
   
   		open bcGetARTrans
   		select @opentranscursor = 1
   		select @oldrectype = -1
   
   		/* spin through the record set of past due invoices for this customer */
   		fetch next from bcGetARTrans into @ARTrans, @applymth, @newrectype, @originv
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
   			   Since this customer is by 'R' then the Min Bal set in ARCo represents Min Invoice Balance 
      	       If total amt due is less than min bal then get next Invoice */
      		exec bspARFCAmtDue @arco, @armth, @ARTrans, @CustGroup, @Customer, NULL,
      			@paiddatecutoff,  @applymth, @FCType, @originvamt output, @AmtDue output, @currinvamt output
   
      		/* If the overdue balance of this invoice is less than MinBal in ARCO then skip this ARTrans/Invoice */
  	    	if @AmtDue < @FCMinBal or @AmtDue = 0
  	     		begin
  	    		goto nextARTrans2
  	       		end
   
      		/* After all conditions are met with amount, we need to enter a header record 
   			   Enter only one header record per RecType. */
   			if @oldrectype <> @newrectype and @newrectype > @oldrectype
   				begin
      			/* we need to grab the next sequence number from this batch   		*/
      			select @nextseq = isnull(max(BatchSeq),0)+1
   				from bARBH
      			where Co = @arco and Mth = @armth and BatchId = @batchid
   
   				/* Get an invoice number from ARCO. */
      			exec @rcode = bspARNextTrans @arco, @InvoiceNum output, @msg output
   				if @rcode <> 0 goto error
   
              	insert into bARBH(Co, Mth, BatchId, BatchSeq, TransType, Source, ARTransType, 
					CustGroup, Customer, RecType, Invoice, Description, TransDate, DueDate, PayTerms)
  		      	values (@arco, @armth, @batchid, @nextseq, 'A', 'ARFinanceC', 'F', 
					@CustGroup, @Customer, @RecType, @InvoiceNum,
					case @FCFinOrServ when 'F' then 'Finance Charge' else 'Service Charge' end, 
					@transdate, case @transdateYN when 'N' then @duedate else @transdate end, @payterms)
   				
   				select @oldrectype = @newrectype
   				select @ARLine = 1	-- Reset ARLine number with each new header
   				end
				-- end of inserting header
   
   			/* Insert one line for each invoice Finance Charge */
      		insert into bARBL(Co, Mth, BatchId, BatchSeq, TransType, ARLine, JCCo, Contract, 
   				RecType, LineType, Description, GLCo, GLAcct, TaxGroup, Amount, FinanceChg,
   				rptApplyMth, rptApplyTrans, INCo, Loc)
			values (@arco, @armth, @batchid, @nextseq, 'A', @ARLine, @JCCo, @Contract, 
   				@RecType, 'F',
   				@originv + ',  ' + convert(varchar(8), @applymth, 1) + ',  ' + convert(varchar(6), @ARTrans), 
    			@GLCo, @GLFinChgAcct, @taxgroup, (@FCPct * @AmtDue), (@FCPct * @AmtDue),
   				@applymth, @ARTrans, @inco, @loc)

   			/* increment ARLine count now, after a line has been inserted. */
   			select @ARLine = @ARLine + 1
   
      		/*get next transaction */
		nextARTrans2:
   			fetch next from bcGetARTrans into @ARTrans, @applymth, @newrectype, @originv
   			end	/*End ARTrans Loop */
   
		if @opentranscursor = 1
			begin
			close bcGetARTrans
			deallocate bcGetARTrans

			select @opentranscursor = 0
			end
   	
   		end   /* End FCTYPE of R */
      
   	/* Get next customer */
nextCustomer:
   	fetch next from bcCustomer into @Customer, @CustGroup, @FCType, @excludecontract, @FCPct, 
   		@GLCo, @GLARAcct, @GLFinChgAcct, @FCMinChrg, @FCCalcOnFC, @FCMinBal, @RecType, 
   		@payterms, @FCFinOrServ
   
   	end 	/* End customer loop */
   
if @opencustcursor = 1
	begin
	close bcCustomer
	deallocate bcCustomer
	select @opencustcursor = 0
	end
   	   
select @rcode = 0
select @errmsg = 'Finance charge calculations complete!'
error:
if @rcode<>0 select @errmsg=@errmsg		--+ char(13) + char(10) + '[bspARFinanceChgCalc]'

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
	end
if @opencustcursor = 1
	begin
	close bcCustomer
	deallocate bcCustomer
	end

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARFinanceChgCalc] TO [public]
GO
