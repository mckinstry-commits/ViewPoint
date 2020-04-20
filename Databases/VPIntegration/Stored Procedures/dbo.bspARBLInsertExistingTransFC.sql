SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARBLInsertExistingTransFC    Script Date: 8/28/99 9:36:00 AM ******/
   CREATE procedure [dbo].[bspARBLInsertExistingTransFC]
   /********************************************************************************************************************************
   * CREATED BY: 	TJL - 07/16/01
   * MODIFIED By :	TJL - 07/27/01  Check FCLevel and use JC Dept, GLRev account if 'Update to JC' is YES
   *		TJL 03/05/02 - Issue #14171, Add BY RECTYPE option, Calculate AmtDue for ON ACCOUNT
   *		TJL 02/04/04 - Issue #23642, While reviewing for this issue, added "with (nolock)" thru-out
   *		TJL 06/01/05 - Issue #27704, 6x rewrite requirement.  Change message text only.
   *               
   *
   * USAGE:	Pulls Line information from bARTL to be placed in the Detail form of ARFinChgLines
   *
   * INPUTS:	@arco
   *		@batchmth
   *		@batchID
   *		@batchseq
   *		@m_applymth		Applied Mth of transaction that FC applies against. (NA for 'A' and 'R')
   *		@m_applytrans	Applied Transaction of invoice that FC applies against. (NA for 'A' and 'R')
   *		@arline			Line number to be pulled or added. (NA for 'R')
   *		@FCPct			Finance Charge percentage to multiply AmtDue Line by.
   *		@headeraction
   *		@fctype			Finance Charge Type 'I' or 'A' or 'R' to determine proper values.
   *		@rectype		RecType to determine proper Finance Chg GLCo and GLAcct.
   *		@custgroup
   *		@customer
   *		@duedatecutoff	Determines transaction involved in calculations (NA for 'I' and 'R')
   *		@paiddatecutoff	Determines payments to be allowed in calcs  (NA for 'I' and 'R')
   *
   * OUTPUTS:	@LineDesc	Returns Invoice line description.	(NA for 'A' and 'R')
   *		@AmtDue			Returns Invoice Line AmtDue to display.	(NA for 'A' and 'R')
   *		@GLCo			Returns FC GLCo based on RecType.
   *		@FCRevGLAcct	Returns FC Revenue GLAcct base on RecType.
   *		@FCAmtDueLine	Returns calculated default Finance Chg for this line. (NA for 'R')
   *		@ContractItem	Returns Contract Item if Invoice is a contract invoice.
   *
   * RETURN VALUES:
   *		0	STDBTK_SUCCESS
   *		1	STDBTK_ERROR
   *
   * Checks batch info in bHQBC, and transaction info in bARTL 
   *
   * 
   *******************************************************************************************************************************/
    
   (@arco bCompany = null, @batchmth bMonth = null, @batchid bBatchID, @batchseq int, @m_applymth bMonth = null, 
   	@m_applytrans bTrans = null, @arline int = null, @FCPct bPct = null, @headeraction varchar(1) = null,
   	@fctype varchar(1) = null, @rectype int = null, @custgroup bGroup = null, @customer bCustomer = null,
   	@duedatecutoff bDate = null, @paiddatecutoff bDate = null,
   	@LineDesc varchar(30) output, @AmtDue bDollar output,  @GLCo bCompany output,
   	@FCRevGLAcct bGLAcct output, @FCAmtDueLine bDollar output,  @ContractItem bContractItem output, 
   	@errmsg varchar(250) output)
   
   as
   set nocount on
   
   declare @status tinyint, @inusebatchid bBatchID, @errtext varchar(100), @source bSource,
   	@jcco bCompany, @contract bContract, @contitemtmp bContractItem,
   	@fclevel tinyint,  @glcotmp bCompany, @jcdept bDept, @contractrevacct bGLAcct
   
   declare @rcode int
   select @rcode = 0, @contitemtmp = NULL, @ContractItem = NULL
   
   If @duedatecutoff is null
   	begin
   	select @duedatecutoff = getdate()
   	end
   If @paiddatecutoff is null
   	begin
   	select @paiddatecutoff = getdate()
   	end
   
   /* Input Validation */
   
   if @arco is null or @batchmth is null or @batchid is null or @batchseq is null 
   	or @arline is null or @headeraction is null or @custgroup is null or @customer is null
   	begin
   	select @errmsg = 'Error processing standard Batch,  parameters missing. Exit batch and begin again.', @rcode = 1
   	goto bspexit
   	end
   
   if @FCPct is null
   	begin
   	select @errmsg = 'Finance Charge percentage is missing.', @rcode = 1
   	goto bspexit
   	end
   
   if @rectype is null
   	begin
   	select @errmsg = 'Receivable Type is missing.', @rcode = 1
   	goto bspexit
   	end
   
   if @fctype <> 'I' and @fctype <> 'A'
   	begin
   	select @errmsg = 'You may not process individual lines if FCType is not (Invoice or Account).'
   	select @errmsg = @errmsg + '  If FCType is (RecType) use File/Menu feature to create line defaults.', @rcode = 1
   	goto bspexit
   	end
   
   If @fctype = 'A' and @arline <> 1
   	begin
   	select @errmsg = 'Only one line may exist for On Account type Finance Charge Invoices.', @rcode = 1
   	goto bspexit
   	end
   
   /* Get GLCo and Finance Chg Revenue GLAcct.  These are determined by RecType from form. */
   select @GLCo = GLCo, @FCRevGLAcct = GLFinChgAcct
   from bARRT with (nolock)
   where ARCo = @arco and RecType = @rectype
   
   /* Get FCLevel from ARCO */
   select @fclevel = FCLevel from bARCO with (nolock) where ARCo = @arco
   
   /* Validate HQ Batch */
   exec @rcode = bspHQBatchProcessVal @arco, @batchmth, @batchid, 'ARFinanceC', 'ARBH', 
   	@errtext output, @status output
   if @rcode <> 0
   	begin
   	select @errmsg = @errtext, @rcode = 1
   	goto bspexit   
     	end
   
   if @status <> 0 
      	begin
   	select @errmsg = 'Invalid Batch status -  must be open!', @rcode = 1
   	goto bspexit
      	end
   
   if @fctype = 'I'
   	begin
   	/* All Transactions can be pulled into a batch as long as it's InUseFlag is set to null.
   	   Otherwise this Trans has been pulled back into batch to be 'C'hanged or 'D'eleted and
   	   Finance Charges should not be calculated on it until that process is complete. */
     	select @inusebatchid = isnull(InUseBatchID, 0) 
   	from bARTH with (nolock)
   	where ARCo=@arco and ARTrans=@m_applytrans and Mth = @m_applymth
   
     	if @inusebatchid > 0 and @inusebatchid <> @batchid
     		begin
     		select @source=Source
     		from bHQBC with (nolock)
     		where Co=@arco and BatchId=@inusebatchid and Mth=@batchmth
   
     		if @@rowcount <> 0
     			begin
     			select @errmsg = 'Transaction already in use by ' +
     					convert(varchar(2),DATEPART(month, @batchmth)) + '/' +
     		      		substring(convert(varchar(4),DATEPART(year, @batchmth)),3,4) +
     					' batch # ' + convert(varchar(6),@inusebatchid) + ' - ' + 
   					'Batch Source: ' + @source, @rcode = 1
     			goto bspexit
   			end
     	 	else
   			begin
     			select @errmsg='Transaction already in use by another batch!' + convert(varchar(10),@arline), @rcode=1
     			goto bspexit
   			end
     		end
   
   	/* Now make sure the line exists in bARTL if this is an INVOICE FCType customer. */
   	if not exists (select 1 from bARTL with (nolock)
   				where ARCo=@arco and Mth=@m_applymth and ARTrans=@m_applytrans and ARLine=@arline)
   		begin
   		select @errmsg = 'Invoice line not found!', @rcode = 1
   		goto bspexit
   		end
   
   	/* If line is present, first get AmtDue for this Line */
     	exec bspARFCAmtDueLineForInvoice @arco, @custgroup, @customer, @m_applymth, @m_applytrans, 
   		@arline, @duedatecutoff, @paiddatecutoff, 'Y', @AmtDue output, @LineDesc output
   
   	/* Calculate Default Finance Charge for this Line */
   	select @FCAmtDueLine = (@AmtDue * @FCPct)
   
   	/* Get Contract Item for this Line if it exists AND get JC Open Rev Acct and JC GLCo if ARCO FCType set to Update JC  */
   	select @jcco = l.JCCo, @contract = l.Contract, @contitemtmp = l.Item		--@Contract Item starts out as NULL
   	from bARTL l with (nolock)
   	where ARCo = @arco and Mth = @m_applymth and ARTrans = @m_applytrans and ARLine = @arline
   	if @jcco is not null and isnull(@contract, '') <> '' and isnull(@contitemtmp, '') <> ''	-- If any Contract values are invalid, no Contract Item returned
   		begin
   		select @ContractItem = @contitemtmp		-- If Contract values are ALL valid, return Contract Item regardless of FCLevel
   		/* if @fclevel = 3		-- If Finance Charge set to Update JC 
   			begin
   			select @glcotmp = GLCo From bJCCO with (nolock) where JCCo = @jcco	-- Get GLCo from JC company rather than from RecType
   			select @jcdept = Department from bJCCM with (nolock) where JCCo = @jcco and Contract = @contract	-- Get JC Dept for this JCCO and Contract
   			if @glcotmp is not null and isnull(@jcdept, '') <> ''		-- If valid JC GLCo and JC Dept
   				begin
   				select @contractrevacct = OpenRevAcct from JCDM with (nolock) where JCCo = @jcco and Department = @jcdept	-- Get Contract Open Rev Acct
   				if isnull(@contractrevacct, '') <> ''	-- If all JC info is valid to now, Use JC Open Rev Acct and JC GLco
   								-- If any contract value came back NULL, GLAcct (Rev) and GLCo come from RecType
   					begin
   					select @FCGLAcct = @contractrevacct
   					select @GLCo = @glcotmp
   					end
   				end
   			end */
   		end
   
   	end	/* Invoice type */
   
   if @fctype = 'A'
   	begin
   	/* Calculate current amount due for entire customer account. */
   	exec bspARFCAmtDue @arco, null, null, @custgroup, @customer, @duedatecutoff, @paiddatecutoff,
   		 null, @fctype, null, @AmtDue output, null
   
   	/* Calculate Finance Charge AmtDue for this Account. */
   	select @FCAmtDueLine = (@AmtDue * @FCPct)
   
   	end	/* End Account type */
   
   bspexit:
   if @rcode<>0 select @errmsg=@errmsg		--+ char(13) + char(10) + '[dbo.bspARBLInsertExistingTransFC]'  
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARBLInsertExistingTransFC] TO [public]
GO
