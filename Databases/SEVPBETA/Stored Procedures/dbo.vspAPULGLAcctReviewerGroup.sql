SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspAPULGLAcctReviewerGroup]
   /***************************************************
   * CREATED BY    : MV 10/29/08
   * Usage:
   *   Called from APUnapproved Entry Detail when a user enters a GLAcct on an Expense type line. 
   *   This stored proc returns the reviewer group from bGLAC.
   *
   * Input:
   *	@glco 
   *	@glacc        
   * Output:
   *	@reviewergroup
   *    @msg          
   *
   * Returns:
   *	0             success
   *   1             error
   *************************************************/
   	(@glco bCompany, @glacct bGLAcct, @reviewergroup varchar(10)output)
   as
   
   set nocount on
   
   declare @rcode int 
   
   select @rcode = 0

   select @reviewergroup=ReviewerGroup from bGLAC where GLCo=@glco and GLAcct=@glacct
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPULGLAcctReviewerGroup] TO [public]
GO
