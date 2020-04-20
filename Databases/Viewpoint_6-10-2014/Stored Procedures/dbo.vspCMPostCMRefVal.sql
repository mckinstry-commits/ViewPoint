SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMPostCMRefVal]
/************************************************************************
* CREATED:	MH 5/2/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Validate CMRef and return next CMRefSeq if CMRef previously used.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

        @cmco bCompany = 0, @mth bMonth = null, @batchid bBatchID = null,
    	@batchseq int = null, @cmtrans bTrans = null, @cmtranstype bCMTransType = null,
    	@cmacct bCMAcct = null, @cmref bCMRef = null, @cmrefseq tinyint output, @cmreferr tinyint output, 
		@refvalmsg varchar(255) output,	@errmsg varchar(255) output

as
set nocount on

    declare @rcode int, @nextrefseq_rcode int, @nextrefseqmsg varchar(60)

    select @rcode = 0

	exec @rcode = bspCMRefVal @cmco, @mth, @batchid, @batchseq, @cmtrans, @cmtranstype, @cmacct, @cmref, @refvalmsg output

	if @rcode = 1
	begin
		select @errmsg = @refvalmsg
		goto vspexit
	end 

	if @rcode = 2
	begin

		select @cmreferr = @rcode
		exec @rcode = bspCMNextRefSeq @cmco, @mth, @batchid, @cmtranstype, @cmacct, @cmref, @cmrefseq output, @nextrefseqmsg output

		if @rcode = 1 
		begin
			select @errmsg = @nextrefseqmsg
			goto vspexit
		end 
	end
	else --@rcode = 0
		select @cmrefseq = 0

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMPostCMRefVal] TO [public]
GO
