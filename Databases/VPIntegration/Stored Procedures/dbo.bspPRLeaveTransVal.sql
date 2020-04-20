SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRLeaveTransVal    Script Date: 8/28/99 9:33:25 AM ******/
   CREATE  proc [dbo].[bspPRLeaveTransVal]
   (@prco bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @prgroup bGroup output,
    @prenddate bDate output, @payseq tinyint output, @msg varchar(60) output)
   /***********************************************************
    * CREATED BY: EN 1/26/98
    * MODIFIED By : EN 4/3/98
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * Usage:
    *	Look up PRGroup, PREndDate and PaySeq for a specific PRAB entry.
    *
    * Input params:
    *	@prco		PR company
    *	@mth		Month
    *	@batchid	Batch ID
    *	@batchseq	Batch sequence
    *
    * Output params:
    *	@prgroup	PR group #
    *	@prenddate	PR ending date
    *	@payseq		Pay period sequence #
    *	@msg		Error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/  as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   /* access PRAB */
   select @prgroup=PRGroup, @prenddate=PREndDate, @payseq=PaySeq from PRAB
   	where Co=@prco and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
   if @@rowcount = 0
   	begin
   	select @msg = 'Batch entry not found.', @rcode = 1
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRLeaveTransVal] TO [public]
GO
