SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRSQCheckExist    Script Date: 8/28/99 9:33:19 AM ******/
   CREATE proc [dbo].[bspPRSQCheckExist]
   (@prco bCompany, @empl varchar(15), @prgroup bGroup, @prenddate bDate = null, @payseq tinyint = null, @msg varchar(90) = null output)
   /***********************************************************
    * CREATED BY: EN 4/15/00
    * MODIFIED BY: EN 5/8/00 - wasn't checking for non-null @cmref
    *              EN 10/11/00 - modified error msg to specify it's for this pay seq
    *              EN 1/8/01 - expand message size limit from 60 to 90
    *
    * Usage:
    *	Used by PRTimeCards to see if a check exists in bPRSQ for a given PRCo/PRGroup/PREndDate/Employee/PaySeq.
    *
    * Input params:
    *	@prco		PR company
    *	@empl		Employee sort name or number
    *	@prgroup	PR Group
    *  @prenddate  Period End Date
    *  @payseq     Payment Sequence
    *
    * Output params:
    *	@msg		error message (if any)
    *
    * Return code:
    *	0 = success, 1 = failure
    **************************************************************************/
   as
   set nocount on
   declare @rcode int, @cmacct bCMAcct, @cmref bCMRef, @checkexists char(1)
   select @rcode = 0
   
   if @prenddate is not null and @payseq is not null and exists (select * from bPRSQ where PRCo = @prco and PRGroup = @prgroup
   and PREndDate = @prenddate and Employee = @empl and PaySeq = @payseq)
       begin
       select @cmref = CMRef, @cmacct = CMAcct from bPRSQ
           where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @empl and PaySeq = @payseq
       if @cmacct is not null and @cmref is not null
           begin
           select @msg = 'Warning - payment already made for this pay seq. (Check #' + @cmref + '/Acct ' + convert(varchar(4),@cmacct) + ').', @rcode = 1
           goto bspexit
           end
       end
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRSQCheckExist] TO [public]
GO
