SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRURInsert    Script Date: 8/28/99 9:35:40 AM ******/
   CREATE  procedure [dbo].[bspPRURInsert]
   /*************************************************************
   * Created: GG 06/01/98
   * Modified: GG 06/12/98
   *			EN 10/9/02 - issue 18877 change double quotes to single
   *
   * Adds entries to PR Update Error table (bPRUR) - using the
   * next available sequence # for the Pay Period, Employee,
   * Pay Seq#, and Posting Seq#.  Called from PR Update validation procedures.
   *
   * Inputs:
   *	@prco		PR Company
   *	@prgroup	PR Group
   *	@prenddate	PR End Date
   *	@employee	Employee
   *	@payseq		Payment Sequence
   *   @postseq    Posting Sequence from timecard
   *	@errortext	Error Text
   *
   * Output:
   *	@errmsg		Error Message
   *
   * Return:
   *   0 if successfull, 1 if error
   **************************************************************/
   
   	(@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee,
   	 @payseq tinyint, @postseq smallint, @errortext varchar(255), @errmsg varchar(60) output)
   as
   set nocount on
   
   declare @rcode int, @seq int
   select @rcode=0, @seq = 0
   
   /* get next Seq# for PR Update Error entry */
   select @seq = isnull(max(Seq),0)+1
   from bPRUR
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   	and Employee = @employee and PaySeq = @payseq and PostSeq = @postseq
   
   /* add PR Update Error entry */
   insert bPRUR (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, Seq, ErrorText)
   values (@prco,@prgroup, @prenddate, @employee, @payseq, @postseq, @seq, @errortext)
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to add PR Update Error entry!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRURInsert] TO [public]
GO
