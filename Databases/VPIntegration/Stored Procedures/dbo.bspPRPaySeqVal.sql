SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPaySeqVal    Script Date: 8/28/99 9:33:32 AM ******/
   CREATE  proc [dbo].[bspPRPaySeqVal]
   /***********************************************************
    * CREATED BY: kb
    * MODIFIED By : kb 1/26/98
    * MODIFIED By : EN 1/26/98
    *				EN 10/8/02 - issue 18877 change double quotes to single
    *
    * Usage:
    *	Used by PRTimeCard Entry. Validates the pay sequence against PRPS
    *  * Input params:
    *	@prco		PR company
    *	@prgroup 	PR Group
    * 	@prenddate	PR Ending Date
    *	@payseq		PaySequence
    *
    * Output params:
    *	@msg		Pay seq description or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/ 
   (@prco bCompany, @prgroup bGroup, @prenddate bDate, @payseq tinyint, @msg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   /* check required input params */	
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company.', @rcode = 1
   	goto bspexit
   	end
   if @prgroup is null
   	begin
   	select @msg = 'Missing PR Group.', @rcode = 1
   	goto bspexit
   	end
   	
   if @prenddate is null
   	begin
   	select @msg = 'Missing PR Ending Date.', @rcode = 1
   	goto bspexit
   	end
   	
   if @payseq is null
   	begin
   	select @msg = 'Missing Pay Sequence.', @rcode = 1
   	goto bspexit
   	end
   	
   select @msg=Description from PRPS where PRCo=@prco and PRGroup=@prgroup
   	and PREndDate=@prenddate and PaySeq=@payseq
   if @@rowcount=0 
   	begin
   	select @msg='Invalid pay sequence.', @rcode=1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPaySeqVal] TO [public]
GO
