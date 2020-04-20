SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMAddLineSeq Script Date: 8/28/99 9:32:34 AM ******/
   CREATE proc [dbo].[bspJBTandMAddLineSeq]
   /***********************************************************
   * CREATED BY	: kb 7/24/00
   * MODIFIED BY : GG 11/27/00 - changed datatype from bAPRef to bAPReference
   *		kb 5/28/01 - issue #13086
   *		kb 12/11/01 - issue #15395
   *		TJL 10/07/02 - Issue #18568, Unlimited manual (No JCMonth, No JCTrans) entries allowed.
   *		TJL 09/15/03 - Issue #22126, Perfomance enhancements, added NoLocks in this procedure
   *
   * USED IN:
   *	...JBJCCDVal
   *	...JBTandMAddJCTrans
   *	...JBTandMAddJCTransToLine
   *
   * USAGE:
   *	When JC Transactions are being initialized or added to an existing bill, we want
   *	to find an existing Line/Seq # and use it or generate a new one.
   *
   * INPUT PARAMETERS
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   
   (@co bCompany, @billmth bMonth, @billnum int, @detailkey varchar(500),
    	@line int, @jbidseq int output, @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @minseq int, @maxseq int, @mintempseq int, @maxtempseq int,
     	@maxitem bContractItem, @sortlevel tinyint, @summaryopt tinyint,
     	@seqcategory varchar(10)
   
   select @rcode = 0
   
   /* Normal Line/Seq determination.  Any @detailkeys passed in  will either already be 
      associated with an existing Line/Seq or a New one will be acquired. */
   GetLineSeq:
   	select @jbidseq = Seq 
   	from bJBID with (nolock)
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line 
   		and DetailKey = @detailkey
   	if @@rowcount = 0 --issue 15395
   		begin	--Begin Getting new Line/Seq, May not already exist
   		select @minseq = max(Seq) 
   		from bJBID with (nolock)
   		where JBCo = @co and BillMonth = @billmth
   			and BillNumber = @billnum and Line = @line and DetailKey <= @detailkey
   
   		select @maxseq = min(Seq) 
   		from bJBID with (nolock)
   		where JBCo = @co and BillMonth = @billmth
   			and BillNumber = @billnum and Line = @line and DetailKey > @detailkey
   
   		if @minseq is null and @maxseq is null	--No Line/Seq exist for this JBIL.Line
   		  	begin
   		  	select @jbidseq = 10
   		  	goto CheckForSeq
   		  	end
   		else
   			begin
   			if @minseq is not null
   				begin
   				select @jbidseq = @minseq + 1
   				goto CheckForSeq
   				end
   			else
   				begin
   				select @jbidseq = @maxseq - 5
   				goto CheckForSeq
   				end
   			end
   
   		CheckForSeq:
   		/* A Line/Seq has been generated because this DetailKey does not already fit into an 
   		   existing Line/Seq. (Therefore it must be unique) Check to see that you haven't 
   		   created one that already exists for another DetailKey value. */
   		if @jbidseq <= 0 or exists (select 1 from bJBID with (nolock) where JBCo = @co and BillMonth = @billmth
   			and BillNumber = @billnum and Line = @line and Seq = @jbidseq)
   			begin
   			exec @rcode = bspJBSeqResequence @co, @billmth, @billnum, @line, @msg output
   			if @rcode <> 0
   				begin
   				select @msg = 'Automatic Resequencing of JBT&MBill Line Sequences has failed! '
   				select @msg = @msg + char(13) + char(10) + char(10)
   				select @msg = @msg + 'First Resequence JBT&MBillLineSeq manually, Delete and then ReAdd the transaction.'
   				select @rcode = 1
   				goto bspexit
   				end
   			else
   				begin
   				goto GetLineSeq
   				end
   			end
   		end		--End Getting new Line/Seq
   
   bspexit:
   /* If an existing Line/Seq # is returned, that record will be updated with Amounts from this
      transaction.  If a NEW Line/Seq # has been generated, a NEW record gets inserted. 
      ***** NOTE ***** This is somewhat different than when a user is inputing Line/Seq records
 
      manually.  In that case, when the DetailKey matches with an existing Line/Seq # then
      we want to increment the Line/Seq # by one to avoid a duplicate key error during an
      insert.  Another stored procedure called 'bspJBTandMAddLineSeqTwo' has been created
      to handle manual inputs from the form. */
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMAddLineSeq] TO [public]
GO
