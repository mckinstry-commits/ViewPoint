SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspJBProgItemRec_Val]
   /*******************************************************************************************************
   * CREATED BY: 	 TJL 09/09/04 - Issue #25472, If transactions apply to Released/Credit Invoice, warn user
   * MODIFIED By :  
   *
   *
   * USAGE:  This is used to validate before an Item record gets saved.  Typically
   * the same validation here will also be found in JBAR interface validation but
   * for a particular reason, users wants to catch this up front to avoid setting
   * a condition in JB that requires Tech Support to alter later.  It is not intended
   * to replace what is in validation.  There is still good reason to keep it there as well.
   *
   * This procedure is intended to grow with time as more up front checks need to be made.
   * This is the reason for the unused inputs (@alternate).   
   * 
   * TO ADD TO THIS PROCEDURE:
   * 1) Modify the next available (@alternate) input to correct Name and Datatype
   * 2) Modify only those forms required.  Pass in New Input.  
   *
   * FORMS CURRENTLY USING THIS ROUTINE:
   * 1) JBProgressItemEdit - TDBSubGrid_BeforeUpdate
   * 2) JBProgressBillEdit - StdBidtekRecUpdate_BEFORE_REC_UPDATE
   * 3) JBReleaseRetainage - TDBSubGrid_BeforeUpdate, CmdUpdate
   * 4) JBProgBillRetgTot  - StdBidtekRecUpdate_BEFORE_REC_UPDATE
   *
   * LIST OF CURRENT UPFRONT VALIDATION CHECKS:
   * 1) Check for applied transactions against AR 'R'eleased Invoice (2nd 'R')  09/10/04
   *
   * INPUTS:
   *	@jbco
   *	@billmth
   *	@billnum
   *	@invstatus	- When available from form else retrieved in this procedure
   *	@alt1		- Alternate.  Future use
   *	@alt2		- Alternate.  Future use
   *	@alt3		- Alternate.  Future use
   *	@alt4		- Alternate.  Future use
   *	@alt5		- Alternate.  Future use
   *	@alt6		- Alternate.  Future use	(After this, add 5 more and modify all forms)
   * 
   * OUTPUTS:
   *	@errmsg		- Combination of all error messages required.  (Up to 5 at about 200 characters each)
   *
   * RESULTS:
   *	0	- Success
   *	1	- Failure.  Each form will display errmsg and decide if users is allowed to proceed
   *
   *******************************************************************************************************/
   @jbco bCompany, @billmth bMonth, @billnum int, @invstatus char(1) = null, @alt1 char(1) = null, 
   	 @alt2 char(1) = null,  @alt3 char(1) = null,  @alt4 char(1) = null,  @alt5 char(1) = null,
   	 @alt6 char(1) = null, @errmsg varchar(1020) output
   as
   
   set nocount on
   
   declare @rcode int, @ARRelRetgCrTran bTrans, @arco bCompany, @contract bContract, 
   	@warning1 varchar(512), @warning2 varchar(512), @warning3 varchar(512), @warning4 varchar(512),
   	@warning5 varchar(512)
   
   select @rcode = 0

   /* Get required information. */
   select @contract = n.Contract, @ARRelRetgCrTran = n.ARRelRetgCrTran, @arco = c.ARCo,
   	@invstatus = case when @invstatus is null then n.InvStatus else @invstatus end
   from bJBIN n with (nolock)
   join bJCCO c with (nolock) on c.JCCo = n.JBCo
   where n.JBCo = @jbco and n.BillMonth = @billmth and n.BillNumber = @billnum
   
   /*  1) Check for applied transactions against AR 'R'eleased Invoice (2nd 'R') */
   if @invstatus = 'I' or @invstatus = 'C' or @invstatus = 'D' 
   	begin
   	/* a) If InvStatus is 'I' or 'C' or 'D' then 'R', 'R' transactions may already exist in AR.
   		  (They will not exist when InvStatus is 'A' and this particular check will not run). */ 
   	if @ARRelRetgCrTran is not null
   		begin
   		/* We have 'R', 'R' transactions already in AR.  Continue with this check.
   		   We will see if any transactions have been applied to the 2nd 'R'eleased trans.
   		   If so, we cannot proceed. */
   		if exists(select top 1 1
           from bARTL with (nolock)
           where ARCo = @arco and ApplyMth = @billmth and ApplyTrans = @ARRelRetgCrTran	-- All Apply transactions
           	and JCCo = @jbco and Contract = @contract									-- for this contract
               and not (Mth = @billmth and ARTrans = @ARRelRetgCrTran))					-- exclude original lines
   			begin
   			/* Related error message text */
   			select @warning1 = 'Retainage was released on this billing, and the Released Retainage invoice in AR has'
   			select @warning1 = @warning1 + ' payments or other applied transactions.  You will not be able to re-interface'
   			select @warning1 = @warning1 + ' this billing if you make changes to retainage held or released.  Other'
   			select @warning1 = @warning1 + ' changes may be permitted.  If you enter Yes to continue, the Invoice Status'
   			select @warning1 = @warning1 + ' will be set (Changed) which requires re-interfacing.'
   			select @rcode = 1
   			end
   		end
   	end
   
   /* FUTURE:  Additional validation can be processed.  Each message should be tacked on to the end
      of the previous so user sees all problems at once.  This gives users the option to abort,
      if appropriate, before the InvStatus gets changed.  (and before JBAR validation gets run) */
   
   bspexit:
   
   if @rcode <> 0 select @errmsg = isnull(@warning1,'') + isnull(@warning2,'') + isnull(@warning3,'')
   								+ isnull(@warning4,'') + isnull(@warning5,'')
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBProgItemRec_Val] TO [public]
GO
