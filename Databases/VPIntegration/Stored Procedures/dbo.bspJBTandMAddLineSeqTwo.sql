SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMAddLineSeqTwo Script Date: 10/07/02 9:32:34 AM ******/
   CREATE proc [dbo].[bspJBTandMAddLineSeqTwo]
   /***********************************************************
   * CREATED BY	: TJL 10/07/02 - Issue #18568, Unlimited manual (No JCMonth, No JCTrans) entries allowed.
   * MODIFIED BY : TJL 09/15/03 - Issue #22126, Perfomance enhancements, added NoLocks in this procedure
   *		TJL 05/18/06 - Issue #28227, 6x Rewrite.  Return Re-Sequence YN flag
   *
   *
   * USED IN:
   *	JBTMBillLines Form
   *	
   * USAGE:
   *	When users are inputing JBTM Bill Line/Seq's manually, we want to find an existing
   *	Line/Seq # relative to this DetailKey and Increment it by ONE to avoid an Insert
   *	error or we want to generate a new one.  By comparing DetailKeys values, we place the 
   *	NEW	JBID record in an order characterizing the Details of the entry.
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
    	@line int, @jbidseq int output, @reseqyn bYN output, @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @minseq int, @maxseq int, @mintempseq int, @maxtempseq int,
     	@maxitem bContractItem, @sortlevel tinyint, @summaryopt tinyint,
     	@seqcategory varchar(10)
   
   select @rcode = 0, @reseqyn = 'N'
   
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
				select @reseqyn = 'Y'
   				goto GetLineSeq
   				end
   			end
   		end		--End Getting new Line/Seq
   	else
   		begin	--Begin Incrementing Existing Line/Seq
   		select @jbidseq = @jbidseq + 1
   
   		if exists (select 1 from bJBID with (nolock) where JBCo = @co and BillMonth = @billmth
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
				select @reseqyn = 'Y'
   				goto GetLineSeq
   				end
   			end
   		end		--End Incrementing Existing Line/Seq
   
   bspexit:
   /* If an existing Line/Seq # is returned, then the user has entered information
      exactly resembling an existing JBID record.  Since this is manual entry, we must
      assume user wants to insert this new line and not update the existing sequence.
      So we increment the Line/Seq # by one, (This keeps the record close to the same position
      in the file as similar records) and allows the NEW recorded to be insert without a
      duplicate key error. */
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMAddLineSeqTwo] TO [public]
GO
