SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspAPURHQReviewer]
    /*************************************
    * validates HQ Reviewer
    *
    * Pass:
    *	HQ Reviewer to be validated
    *
    * Success returns:
    *	0 and Description from bHQRV
    *
    * Error returns:
    *	1 and error message
    **************************************/
    	( @apco bCompany, @reviewer varchar(10) = null, @uimth bMonth, @uiseq int = null, @line int = -1, 
         @approvalseq int, @msg varchar(255) output)
    as 
    	set nocount on
    	declare @rcode int
    	select @rcode = 0
    	
    if @reviewer is null
    	begin
    	select @msg = 'Missing Reviewer', @rcode = 1
    	goto bspexit
    	end
    
    select @msg = Name from bHQRV where Reviewer= @reviewer
    	if @@rowcount = 0
    		begin
    		select @msg = 'Not a valid Reviewer code.', @rcode = 1
    		end
    
    --Check to make sure Reviewer is only assigned one time
   
    if exists (Select 1 from bAPUR where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line = @line and
               Reviewer = @reviewer and ApprovalSeq <> @approvalseq)
           begin 
           select @msg = 'Reviewer may not be assigned more than once to a line.', @rcode = 1
           end    
   
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPURHQReviewer] TO [public]
GO
