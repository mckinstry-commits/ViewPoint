SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRELAmtsGet    Script Date: 8/28/99 9:35:32 AM ******/
   CREATE   proc [dbo].[bspPRELAmtsGet]
   (@prco bCompany, @mth bMonth = null, @batchid bBatchID = null, @sequence int = null,
    @employee bEmployee, @leavecode bLeaveCode, @cap1reset bDate = null, @cap2reset bDate = null,
    @availbalreset bDate = null, @accum1 bHrs output, @accum2 bHrs output, @availbal bHrs output,
    @curraccum1 bHrs output, @curraccum2 bHrs output, @curravailbal bHrs output, @msg varchar(60) output)
   /***********************************************************
    * CREATED BY: EN 1/22/98
    * MODIFIED By : EN 6/22/99
    *               EN 2/17/00 - add option to provide reset dates in input params rather than look them up in bPREL
    *               EN 2/17/00 - modify code which adjusts current balances for bPRAB entries to include better support for reset entries
    *               EN 4/3/02 - Issue 15788 Adjust for renamed bPRAB fields ... return totals broken down by bPREL bucket amount and batch total
	*				MH 04/24/09 - Issue 131962 - make sure we are using the table, not the view.
    *
    * Usage:
    *	Validate an employee/leave code combination to PREL.
    *	Return current accumulator 1 & 2 as well as current available balance are based on
    *  amounts from bPREL and unposted batch entries except for the batch entry addressed
    *  by the prco/mth/batchid/sequence information provided in the input parameters (if any).
    *
    * Input params:
    *	@prco		PR company
    *	@mth		Month (null if none)
    *	@batchid	Batch ID (null if none)
    *	@sequence	Batch sequence # (null if none)
    *	@employee	Employee Code to validate
    *	@leavecode	Leave Code to validate
    *  @cap1reset  Cap 1 Reset Date (optional)
    *  @cap2reset  Cap 2 Reset Date (optional)
    *  @availbalreset  Available Balance Reset Date (optional)
    *
    * Output params:
    *	@accum1		accumulator 1 bucket amount from bPREL
    *	@accum2		accumulator 2 bucket amount from bPREL
    *	@availbal	available balance bucket amount from bPREL
    *	@curraccum1	total accrual accumulator 1 unposted changes within batch
    *	@curraccum2     total accrual accumulator 2 unposted changes within batch
    *	@curravailbal	total available balance unposted changes within batch
    *	@msg		Leave code description or error message
    *
    * Return code:
    *	0 = success, 1 = failure
    ************************************************************/
   as
   set nocount on
   declare @rcode int, @cap1date bDate, @cap2date bDate, @availbaldate bDate
   
   select @rcode = 0
   
   /* check required input params */
   
   /* validate employee */
   if @employee is null
   	begin
   	select @msg = 'Missing Employee.', @rcode = 1
   	goto bspexit
   	end
   if not exists(select 1 from bPREH where PRCo=@prco and Employee=@employee)
   	begin
   	select @msg = 'Invalid Employee.', @rcode = 1
   	goto bspexit
   	end
   
   /* validate leave code */
   if @leavecode is null
   	begin
   	select @msg = 'Missing Leave Code.', @rcode = 1
   	goto bspexit
   	end
   if not exists(select 1 from bPRLV where PRCo=@prco and LeaveCode=@leavecode)
   	begin
   	select @msg = 'Invalid Leave Code.', @rcode = 1
   	goto bspexit
   	end
   
   /* validate employee/leave code combination */
   select @accum1 = Cap1Accum, @cap1date = Cap1Date,
   	@accum2 = Cap2Accum, @cap2date = Cap2Date,
   	@availbal = AvailBal, @availbaldate = AvailBalDate
   	from bPREL where PRCo=@prco and Employee=@employee and LeaveCode=@leavecode
   if @@rowcount=0
   	begin
   	select @msg = 'Employee/Leave Code has not been set up.', @rcode = 1
   	goto bspexit
   	end
   
   /* use reset date overrides if provided */
   if @cap1reset is not null select @cap1date = @cap1reset
   if @cap2reset is not null select @cap2date = @cap2reset
   if @availbalreset is not null select @availbaldate = @availbalreset
   
   -- init batch accum amts
   select @curraccum1 = 0, @curraccum2 = 0, @curravailbal = 0
   
   /* adjust current balances for bPRAB entries */
   /* Note: Specifically coded to test ActDate <= cap or availdate so that if date */
   /*       being compared against is null, then amount from table is defaulted */
   
   -- first, adjust for reset entries (note that reset entries cannot be changed or deleted here)
   select @curraccum1 = @curraccum1 + isnull(sum(CASE WHEN ActDate <= @cap1date THEN 0 ELSE Accum1Adj END),0),
   	@curraccum2 = @curraccum2 + isnull(sum(CASE WHEN ActDate <= @cap2date THEN 0 ELSE Accum2Adj END),0),
   	@curravailbal = @curravailbal + isnull(sum(CASE WHEN ActDate <= @availbaldate THEN 0 ELSE AvailBalAdj END),0)
   from bPRAB
   where Co = @prco and Mth = isnull(@mth,Mth) and BatchId = isnull(@batchid,BatchId)
    and BatchSeq <> isnull(@sequence,-1) and BatchTransType = 'A'
       and Employee = @employee and LeaveCode = @leavecode
       and Amt = 0 and (Accum1Adj <> 0 or Accum2Adj <> 0 or AvailBalAdj <> 0)
   
   -- then subtract old amts from curraccum1 and curraccum2 for changed and deleted accruals
   select @curraccum1 = @curraccum1 - isnull(sum(CASE WHEN OldActDate <= @cap1date THEN 0 ELSE OldAmt END),0),
   	@curraccum2 = @curraccum2 - isnull(sum(CASE WHEN OldActDate <= @cap2date THEN 0 ELSE OldAmt END),0),
   	@curravailbal = @curravailbal - isnull(sum(CASE WHEN OldActDate <= @availbaldate THEN 0 ELSE OldAmt END),0)
   from bPRAB
   where Co = @prco and Mth = isnull(@mth,Mth) and BatchId = isnull(@batchid,BatchId)
       and BatchSeq <> isnull(@sequence,-1) and (BatchTransType = 'C' or BatchTransType = 'D')
       and Employee = @employee and LeaveCode = @leavecode and Type = 'A'
   
   -- then add old amts into curravailbal for changed and deleted usage
   select @curravailbal = @curravailbal + isnull(sum(CASE WHEN OldActDate <= @availbaldate THEN 0 ELSE OldAmt END),0)
   from bPRAB
   where Co = @prco and Mth = isnull(@mth,Mth) and BatchId = isnull(@batchid,BatchId)
       and BatchSeq <> isnull(@sequence,-1) and (BatchTransType = 'C' or BatchTransType = 'D')
       and Employee = @employee and LeaveCode = @leavecode and Type = 'U'
   
   -- then add amts into curraccum1 and curraccum2 for added and changed accruals
   select @curraccum1 = @curraccum1 + isnull(sum(CASE WHEN ActDate <= @cap1date THEN 0 ELSE Amt END),0),
   	@curraccum2 = @curraccum2 + isnull(sum(CASE WHEN ActDate <= @cap2date THEN 0 ELSE Amt END),0),
   	@curravailbal = @curravailbal + isnull(sum(CASE WHEN ActDate <= @availbaldate THEN 0 ELSE Amt END),0)
   from bPRAB
   where Co = @prco and Mth = isnull(@mth,Mth) and BatchId = isnull(@batchid,BatchId)
       and BatchSeq <> isnull(@sequence,-1) and (BatchTransType = 'A' or BatchTransType = 'C')
       and Employee = @employee and LeaveCode = @leavecode and Type = 'A'
   
   -- then subtract amts from curravailbal for added and changed usage
   select @curravailbal = @curravailbal - isnull(sum(CASE WHEN ActDate <= @availbaldate THEN 0 ELSE Amt END),0)
   from bPRAB
   where Co = @prco and Mth = isnull(@mth,Mth) and BatchId = isnull(@batchid,BatchId)
       and BatchSeq <> isnull(@sequence,-1) and (BatchTransType = 'A' or BatchTransType = 'C')
       and Employee = @employee and LeaveCode = @leavecode and Type = 'U'
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRELAmtsGet] TO [public]
GO
