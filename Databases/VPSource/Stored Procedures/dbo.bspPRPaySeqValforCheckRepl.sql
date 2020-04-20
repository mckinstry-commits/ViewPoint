SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRPaySeqValforCheckRepl]
   /***********************************************************
    * CREATED BY: GG 09/15/01
    * MODIFIED By: 
    *
    * Usage:
    *	Called by the PR Check Replacement form to validate an Employee and 
    *	Pay Seq within a Pay Period.  
    *
    * Input params:
    *	@prco		PR company
    *	@prgroup	PR Group	
    *	@prenddate	PR End Date
    *	@employee	Employee number
    *	@payseq		Pay Seq
    *
    * Output params:
    *	@msg		message if error
    *
    * Return code:
    *	0 = success, 1 = failure
    **************************************************************************/ 
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
   	 @employee bEmployee = null, @payseq tinyint = null, @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- make sure this Employee exists within the Pay Period
   if (select count(*) from PRSQ where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   	and Employee = @employee and PaySeq = @payseq) = 0
   	begin
   	select @msg = 'Invalid Employee/Pay Seq within this Pay Period.', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPaySeqValforCheckRepl] TO [public]
GO
