SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspPRVoidChecks]
  /***********************************************************
  * CREATED: EN 3/24/98
  * MODIFIED: EN 9/23/98
  *        	EN 9/29/00 - issue #10756
  *           EN 10/04/00 - issue #10816 When voiding in check sort order, employees with
  *                         no check sort order code assigned (i.e. null) were not being
  *                         included in the void though bspPRCheckProcess would go ahead and
  *                         try to print a check for them.  This was causing an error that
  *                         checks were in use for the specified range upon assigning check #'s.
  *           GG 01/29/01 - removed bPRSQ.InUse
  *           GG 04/06/01 - removed sort options, voids computer checks within range (#12208)
  *			EN 10/9/02 - issue 18877 change double quotes to single
  *			GG 10/03/05 - #29555 exclude checks already cleared in CM
  *				EN 2/22/08 - 25357  abort and return error if pay period InUseBy is marked for another user
  *			
  *
  * USAGE:
  * Called from the PR Check Print program to void/clear a range of checks.  May be used to cancel
  * a check run after the check #s are assigned, but before they are printed, or prior to
  * reprinting, to void or clear previously assigned and printed checks.
  *
  * INPUT PARAMETERS
  *   @prco          	PR Co#
  *   @prgroup		PR Group
  *   @prenddate		Pay Period Ending Date
  *   @beginchk      	Beginning check # to void or clear
  *   @endchk        	Ending check # to void or clear
  *   @void		    Void option - Y = void, check#'s not reused
  *                              - N = clear, check#'s can be reused
  *   @clearonly     	Option to clear checks based on bPRSP entries only
  *   @voidmemo		Memo for voided checks
  *
  * OUTPUT PARAMETERS
  *   @msg      		error message if error occurs
  *
  * RETURN VALUE
  *   0   success
  *   1   fail
  *******************************************************************/
       (@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @beginchk bCMRef = null,
        @endchk bCMRef = null, @void bYN = 'N', @clearonly bYN = 'N', @voidmemo bDesc = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode tinyint, @checkcnt int, @reuse bYN, @openCheck tinyint, @employee bEmployee, @payseq tinyint,
       @cmco bCompany, @cmacct bCMAcct, @cmref bCMRef, @cmrefseq tinyint, @paiddate bDate, @paidmth bMonth,
       @hours bHrs, @earnings bDollar, @dedns bDollar, @cminterface bYN, @inuseby bVPUserName
   
   select @rcode = 0

   -- issue 25357  get current PRPC_InUseBy value  
   select @inuseby = InUseBy from dbo.bPRPC where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate

   -- issue 25357  abort and return error if PRPC_InUseBy is set for another user
   if isnull(@inuseby,'') <> ''
	begin
	if @inuseby <> SUSER_SNAME()
		begin
		select @msg = 'This pay period has already been reserved by user ' + @inuseby + '.  Please try again later.', @rcode = 1
		goto bspexit
		end
	end
   
   -- clear paid info from PR Employee Sequence Control based on checks currently in PR Check Print table
   -- only called if user cancels checks after #s have been assigned but before printing
   if @clearonly = 'Y'
       begin
       -- get # of entries in PR Check Stub
       select @checkcnt = count(*) from bPRSP where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   
       begin transaction
   
       update bPRSQ
       set CMRef = null, CMRefSeq = null, PaidDate = null, PaidMth = null, Hours = 0, Earnings = 0, Dedns = 0
       from bPRSQ s
       join bPRSP p on s.PRCo = p.PRCo and s.PRGroup = p.PRGroup and s.PREndDate = p.PREndDate
           and s.Employee = p.Employee and s.PaySeq = p.PaySeq
       where p.PRCo = @prco and p.PRGroup = @prgroup and p.PREndDate = @prenddate  -- current pay period
           and s.PayMethod = 'C' and s.ChkType = 'C' and s.CMInterface = 'N'   -- make sure only eligible entries are cleared
   
       if @@rowcount = @checkcnt
           begin
           -- clear PR Check Print tables
           delete bPRSX where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
           delete bPRSP where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
           commit transaction
           end
       else
           begin
           select @msg = 'Unable to clear check information from PR Employee Sequence Control and Check Print tables.', @rcode = 1
           rollback transaction
           end
       end
   
   
   -- Voids or Clears all checks within range, adds entries to PR Void Payments as needed
   if @clearonly = 'N'
       begin
  
       -- assign 'reuse' flag
       select @reuse = 'Y'
       if @void = 'Y' select @reuse = 'N'     -- voided check #s cannot be reused
   
       -- create a cursor to process each Check
       declare bcCheck cursor for
       select s.Employee, s.PaySeq, s.CMCo, s.CMAcct, s.CMRef, s.CMRefSeq, s.PaidDate, s.PaidMth,
           s.Hours, s.Earnings, s.Dedns, s.CMInterface
   	from bPRSQ s
   	join bPREH e on e.PRCo = s.PRCo and e.Employee = s.Employee
  	-- #29555 exclude cleared checks
  	left join bCMDT c on c.CMCo = s.CMCo and c.CMAcct = s.CMAcct and c.CMTransType = 1
  		and c.CMRef = s.CMRef and c.CMRefSeq = s.CMRefSeq
   	where s.PRCo = @prco and s.PRGroup = @prgroup and s.PREndDate = @prenddate 
       	and s.PayMethod = 'C' and s.ChkType = 'C' and s.CMRef >= isnull(@beginchk,'') and s.CMRef <= isnull(@endchk,'~~~~~~~~~~')
  		and c.StmtDate is null
   
       -- open cursor
       open bcCheck
       select @openCheck = 1
   
       --  loop through Check cursor
       next_Check:
           fetch next from bcCheck into @employee, @payseq, @cmco, @cmacct, @cmref, @cmrefseq, @paiddate, @paidmth,
               @hours, @earnings, @dedns, @cminterface
   
           if @@fetch_status <> 0 goto end_Check
   
           begin transaction
   
           -- add to PR Void Payments if check # is not to be reused or already updated to CM
           if @reuse = 'N' or @cminterface = 'Y'
               insert bPRVP (PRCo, PRGroup, PREndDate, CMCo, CMAcct, PayMethod, CMRef, CMRefSeq, EFTSeq, ChkType,
                   PaidDate, PaidMth, Employee, PaidAmt, VoidMemo, Reuse, PaySeq, Hours, Earnings, Dedns)
               values (@prco, @prgroup, @prenddate, @cmco, @cmacct, 'C', @cmref, @cmrefseq, 0, 'C',
                   @paiddate, @paidmth, @employee, (@earnings - @dedns), @voidmemo, @reuse, @payseq, @hours, @earnings, @dedns)
   
           -- clear payment info from PR Employee Sequence Control
           update bPRSQ
           set CMRef = null, CMRefSeq = null, PaidDate = null, PaidMth = null, Hours = 0, Earnings = 0, Dedns = 0, CMInterface = 'N'
           where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee and PaySeq = @payseq
           if @@rowcount = 1
               begin
               commit transaction
               end
           else
               begin
               select @msg = 'Unable to void or clear check information.', @rcode = 1
               rollback transaction
               goto bspexit
               end
   
           goto next_Check
   
       end_Check:
           close bcCheck
           deallocate bcCheck
           select @openCheck = 0
       end
   
   bspexit:
       if @openCheck = 1
   		begin
   		close bcCheck
   		deallocate bcCheck
   		end
   
     --  if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[bspPRVoidChecks]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRVoidChecks] TO [public]
GO
