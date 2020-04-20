SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMAddLineTwo Script Date: 07/04/02 9:32:34 AM ******/
 CREATE proc [dbo].[bspJBTandMAddLineTwo]
 /***********************************************************
 * CREATED BY:  	TJL 07/04/02 - Issue #17701
 * MODIFIED BY: 	TJL 03/27/03 - Issue #20550, Friendly Error on LineType 'N', non-billable
 *		TJL 09/15/03 - Issue #22126, Perfomance enhancements, added NoLocks in this procedure
 *		TJL 03/31/04 - Issue #24189, Check for invalid Template Seq Item
 *		TJL 05/10/06 - Issue #28227, 6x Rewrite.  Return Re-Sequence YN flag
 *
 * USED IN:
 *	bspJBTandMAddSeqAddons
 *	bspJBTandMAddJCTrans
 *	Called directly from form JBTMBillLines, event NextGridSeq
 *
 * USAGE:
 *	Places Blank Detail or Total Addon Line in the correct order
 *	when other Addons already exist.
 *
 * INPUT PARAMETERS
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
 
 (@co bCompany, @billmth bMonth, @billnum int, @linekey varchar(100),
 	@template varchar(10), @templateseq int, @item bContractItem,
 	@line int output, @reseqyn bYN output, @msg varchar(255) output)
 as
 
 set nocount on
 
 declare @rcode int, @minline int, @maxline int, @mintempseq int, @maxtempseq int,
 	@minitem bContractItem, @maxitem bContractItem, @linetype char(1)
 
 select @rcode = 0, @reseqyn = 'N'
 
 select @linetype = Type
 from bJBTS with (nolock)
 where JBCo = @co and Template = @template and Seq = @templateseq
 
 /* If this transaction falls into a template sequence that is non-billable,
    display a friendly message to the user. */
 if @linetype = 'N'
 	begin
 	select @msg = 'This transaction is associated with a non-billable template '
 	select @msg = @msg + 'sequence.  It may not be marked as billable!', @rcode = 1
 	goto bspexit
 	end
 
 GetLineNum:
 if @linetype = 'A' or @linetype = 'S'
 	begin	/* Begin 'A' and 'S' type process */
 	select  @minline = max(Line) 
 	from bJBIL with (nolock)
 	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
		and LineKey < @linekey and LineType <> 'T'
 
	select @maxline = min(Line) 
 	from bJBIL with (nolock)
 	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
		and LineKey >= @linekey and LineType <> 'T'
 
 	if @minline is null and @maxline is null
 		begin
 		/* No 'A' or 'S' lines exists, Maybe some 'T' Total Addons but who cares. */
 		select @line = 10
 		goto CheckForLine
 		end
 	else
 		begin
 		if @minline is not null
 			begin
 			select @line = @minline + 1
 			goto CheckForLine
 			end
 		else
 			begin
 			select @line = @maxline - 5
 			goto CheckForLine
 			end
 		end
 	end		/* End 'A' and 'S' type process */
 
 if @linetype = 'D'
 	begin  /*Begin 'D' type process */
 	select  @minline = max(Line) 
 	from bJBIL with (nolock)
 	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
		and LineKey = @linekey and TemplateSeq < @templateseq
 
	select @maxline = min(Line) 
 	from bJBIL with (nolock)
 	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
		and LineKey = @linekey and TemplateSeq > @templateseq
 
 	if @minline is null and @maxline is null
 		begin
 		/* Neither a Source ('A' or 'S') or other Detail Addons exist. 
 		   This should not happen. */
 		select @msg = 'Neither an Amount line or Source line exist to apply against!'
 		select @rcode = 1
 		goto bspexit
 		end
 	else
 		begin
 		if @minline is not null
 			begin
 			select @line = @minline + 1
 			goto CheckForLine
 			end
 		else
 			begin
 			select @line = @maxline - 5
 			goto CheckForLine
 			end
 		end
 	end		/* End 'D' type process */
 
 if @linetype = 'T'
 	begin	/* Begin 'T' type process */
 	select  @minline = max(Line) 
 	from bJBIL with (nolock)
 	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
		and LineKey <= @linekey and LineType = @linetype
 
	select @maxline = min(Line) 
 	from bJBIL with (nolock)
 	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
		and LineKey > @linekey and LineType = @linetype
 
 	if @minline is null and @maxline is null
 		begin
 		/* No Total Addons Exist */
 		select @line = (max(Line) + 10)
 		from bJBIL with (nolock)
 		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
 		goto CheckForLine
 		end
 	else
 		begin
 		if @minline is not null
 			begin
 			select @line = @minline + 1
 			goto CheckForLine
 			end
 		else
 			begin
 			select @line = @maxline - 5
 			goto CheckForLine
 			end
 		end
 	end 	/* End 'T' type process */
 
 CheckForLine:
 /* A LineNumber has been selected.  Check to see if it already exists in bJBIL */
 if @line <= 0 or exists (select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @billmth
 	and BillNumber = @billnum and Line = @line)
 	begin
 	exec @rcode = bspJBLineResequence @co, @billmth, @billnum, @msg output
 	if @rcode <> 0
 		begin
 		select @msg = 'Automatic Resequencing of JBT&MBill Lines has failed! '
 		select @msg = @msg + char(13) + char(10) + char(10)
 		select @msg = @msg + 'First Resequence JBT&MBillLines manually, Delete and then ReAdd the transaction.'
 		select @rcode = 1
 		goto bspexit
 		end
 	else
 		begin
		select @reseqyn = 'Y'
 		goto GetLineNum
 		end
 	end
 
 bspexit:
 /* If all has failed and LineNumber is still null at this point, return error. */
 if @line is null select @rcode = 1
 
 return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBTandMAddLineTwo] TO [public]
GO
