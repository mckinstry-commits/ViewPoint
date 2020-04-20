SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBGLSetDistributions    Script Date: ******/
CREATE procedure [dbo].[vspJBGLSetDistributions]
/*******************************************************************************************
* CREATED BY:   	TJL 08/20/08 - Issue #128370, JB Release International Sales Tax
* MODIFIED By :   	
*
*
* USAGE:
* Called from bspJBARReleaseVal to generate GL Distributions
*
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
***************************************************************************************************/
@jbco bCompany, @batchmth bMonth, @batchid bBatchID, @seq int, @batchtranstype char(1), 
	@postamount bDollar, @oldpostamount bDollar, @postGLCo bCompany, @postGLAcct bGLAcct,
	@oldpostGLCo bCompany, @oldpostGLAcct bGLAcct,
	@relretgtrans bTrans, @ARLine smallint, @custgroup bGroup, @customer bCustomer, @sortname varchar(15), 
	@invoice char(10), @jbcontract bContract, @jbcontractitem bContractItem, @transdate bDate, @oldtransdate bDate,
	@errmsg varchar(255) output

as
set nocount on
declare @rcode int, @count int

select @rcode = 0

if isnull(@postamount,0) <> 0 and (@batchtranstype <>'D')
	begin	/* Begin insert New values */
	exec @rcode = bspGLACfPostable @postGLCo, @postGLAcct, NULL, @errmsg output
	if @rcode <> 0 
 		begin
		select @rcode = 7		--GLCo, GLAcct invalid error, get_next_bcJBAL
		goto vspexit
 		end

	/* Lets first try to update to see if this GLAcct is already in batch */
	update bJBGL
	set ARTrans = @relretgtrans, ARLine = @ARLine, Customer = @customer, SortName = @sortname, CustGroup = @custgroup,
		Invoice = @invoice, Contract = @jbcontract, Item = @jbcontractitem, ActDate = @transdate,
		Amount = Amount + @postamount
	where JBCo = @jbco and Mth = @batchmth and BatchId = @batchid and GLCo = @postGLCo and
		GLAcct = @postGLAcct and BatchSeq = @seq and OldNew = 1 and JBTransType = 'R'

	/* If record is not already there then lets try to insert it */
	if @@rowcount = 0
		begin
		insert into bJBGL(JBCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, JBTransType, ARTrans, ARLine, Customer, SortName,
    		CustGroup, Invoice, Contract, Item, ActDate, Description, Amount)
		values(@jbco, @batchmth, @batchid, @postGLCo, @postGLAcct, @seq, 1, 'R', @relretgtrans, @ARLine, @customer, @sortname,
   			@custgroup, @invoice, @jbcontract, @jbcontractitem, @transdate, 'Release Retainage', @postamount)
		if @@rowcount = 0
  			begin
  			select @errmsg = 'Unable to add GL Distribution audit - ', @rcode = 1	--exit validation
  			goto vspexit
			end

		/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
		if not exists(select 1 from bHQCC where Co = @jbco and Mth = @batchmth and BatchId = @batchid and GLCo = @postGLCo)
			begin
			insert bHQCC (Co, Mth, BatchId, GLCo)
			values (@jbco, @batchmth, @batchid, @postGLCo)
			end
		end

/* Troubleshooting code - Look at each value as it gets posted to distribution table */
--select @count = isnull(max(OldNew), 0) + 1
--from bJBGL
--where JBCo = @jbco and Mth = @batchmth and BatchId = @batchid

--insert into bJBGL(JBCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, JBTransType, ARTrans, ARLine, Customer, SortName,
--	CustGroup, Invoice, Contract, Item, ActDate, Description, Amount)
--values(@jbco, @batchmth, @batchid, @postGLCo, @postGLAcct, @seq, @count, 'R', @relretgtrans, @ARLine, @customer, @sortname,
--	@custgroup, @invoice, @jbcontract, @jbcontractitem, @transdate, 'Release Retainage', @postamount)

	end		/* End insert New values */

if isnull(@oldpostamount,0) <> 0 and (@batchtranstype <> 'A')
	begin	/* Begin insert Changed or Deleted values */
	exec @rcode = bspGLACfPostable @oldpostGLCo, @oldpostGLAcct, NULL, @errmsg output
	if @rcode <> 0
		begin
		select @rcode = 8		--oldGLCo, oldGLAcct invalid error, get_next_bcJBAL
		goto vspexit
		end

	update bJBGL
	set ARTrans = @relretgtrans, ARLine = @ARLine, Customer = @customer, SortName = @sortname, CustGroup = @custgroup,
		Invoice = @invoice, Contract = @jbcontract, Item = @jbcontractitem, ActDate = @oldtransdate,
		Amount = Amount + @oldpostamount
	where JBCo = @jbco and Mth = @batchmth and BatchId = @batchid and GLCo = @oldpostGLCo and
		GLAcct = @oldpostGLAcct and BatchSeq = @seq and OldNew = 0 and JBTransType = 'R'

	/* If record is not already there then lets try to insert it */
	if @@rowcount = 0
		begin
		insert into bJBGL(JBCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, JBTransType, ARTrans, ARLine, Invoice,
 			Customer, SortName, CustGroup, Contract, Item, ActDate, Description, Amount)
		values(@jbco, @batchmth, @batchid, @oldpostGLCo, @oldpostGLAcct, @seq, 0, 'R', @relretgtrans, @ARLine, @invoice,
			@customer, @sortname, @custgroup, @jbcontract, @jbcontractitem, @oldtransdate, 'Release Retainage', @oldpostamount)
		if @@rowcount = 0
			begin
  			select @errmsg = 'Unable to add GL Distribution audit - ', @rcode = 1	--exit validation
  			goto vspexit
			end

		/* This entry into bHQCC will place a value for either AR GLCo or Cross Company JC GLCo. */
		if not exists(select 1 from bHQCC where Co = @jbco and Mth = @batchmth and BatchId = @batchid and GLCo = @oldpostGLCo)
			begin
			insert bHQCC (Co, Mth, BatchId, GLCo)
			values (@jbco, @batchmth, @batchid, @oldpostGLCo)
			end
		end
	
/* Troubleshooting code - Look at each value as it gets posted to distribution table */
--select @count = isnull(max(OldNew), 0) + 1
--from bJBGL
--where JBCo = @jbco and Mth = @batchmth and BatchId = @batchid

--insert into bJBGL(JBCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, OldNew, JBTransType, ARTrans, ARLine, Customer, SortName,
--	CustGroup, Invoice, Contract, Item, ActDate, Description, Amount)
--values(@jbco, @batchmth, @batchid, @oldpostGLCo, @oldpostGLAcct, @seq, @count, 'R', @relretgtrans, @ARLine, @customer, @sortname,
--	@custgroup, @invoice, @jbcontract, @jbcontractitem, @transdate, 'Release Retainage', @oldpostamount)

	end		/* End insert Changed or Deleted values */

vspexit:

if @rcode <> 0 select @errmsg = @errmsg	
return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspJBGLSetDistributions] TO [public]
GO
