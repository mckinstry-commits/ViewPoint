SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          procedure [dbo].[bspPRSalaryDistrib]
 /****************************************************************
  * CREATED BY: EN 05/15/07
  * MODIFIED By : MH 04/28/08 Issue 128057 
  *					EN 10/21/08  #130653
  *					mh 11/18/08 #128415
  *					EN 11/21/08 - #131132  fix made to retain attachments on Change type PRTB entries
  *					EN 11/24/08 - #126931  added params into code to call vspPRTBAddCEntry
  *
  * USAGE:
  * Called by the PR Salary Distribution form to distribute salary amounts for employee's 
  * timecard postings in a specified batch.  Salary will be distributed among any timecards
  * with earnings code marked in bPREC for being included in salary dist. calculations.
  *
  * INPUT:
  *   @co      		PR Company
  *   @mth        	Batch month
  *   @batchid    	Batch ID
  *   @specempl		specific employee to distribute - null for all salary employee
  *   @specpayseq	specific payment sequence for distribution - null for all pay seqs
  *
  * OUTPUT:
  *   @PRTBAlteredYN	Y = Distributions made in this session, N = No distributions made
  *   @msg		Error message
  *
  * RETURN:
  *   0		Sucess
  *   1		Failure
  ********************************************************/
 	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @specempl int = null, 
	 @specpayseq tinyint = null, @PRTBAlteredYN char(1) = 'N' output, @msg varchar(200) = null output)
 as
 set nocount on
 
	declare @rcode int, @inuseby bVPUserName, @status tinyint,
   	 @prgroup bGroup, @prenddate bDate, @begindate bDate, @openEmplPost tinyint,
	 @employee bEmployee, @payseq tinyint, @postseq smallint, 
	 @postedhrs bHrs, @totalposts int, @salaryamt bDollar, @totalhrs bHrs,
	 @postamt bDollar, @postrate bUnitCost, @totalamtposted bDollar,
	 @postingcount int, @seq int, @daynum smallint, @postdate bDate, @prtbud_flag bYN --#131132 added @prtbud_flag

	select @rcode = 0, @totalamtposted = 0, @postingcount = 1, @PRTBAlteredYN = 'N', @prtbud_flag = 'N' --#131132 added @prdbud_flag

    -- #131132 check Timecard Batch table for custom fields
    if exists(select top 1 1 from sys.syscolumns (nolock) where name like 'ud%' and id = object_id('dbo.PRTB'))
		set @prtbud_flag = 'Y'	-- bPRTB has custom fields

	-- get PR Group and Ending Date from Batch
	select @inuseby = InUseBy, @status = Status, @prgroup = PRGroup, @prenddate = PREndDate
	from dbo.bHQBC with (nolock)
	where Co = @co and Mth = @mth and BatchId = @batchid
	if @@rowcount = 0
   		begin
     	select @msg =  'Missing HQ Batch.', @rcode = 1
     	goto bspexit
     	end
	if @inuseby <> SUSER_SNAME()
     	begin
     	select @msg = 'This batch already in use by ' + isnull(@inuseby,''), @rcode = 1
     	goto bspexit
     	end
	if @status <> 0
       begin
       select @msg = 'Batch status must be ''open''.', @rcode = 1
       goto bspexit
       end

	-- get Pay Period begin date
	select  @begindate = BeginDate	from dbo.bPRPC with (nolock)
	where PRCo = @co and PRGroup = @prgroup and PREndDate = @prenddate
	if @@rowcount = 0
 		begin
 		select @msg = 'Missing Pay Period Control entry!', @rcode = 1
		goto bspexit
		end


	-- Create temp table containing employees in a batch (they will be exempt from distribution until batches are posted)
	if object_id('#PREmplsInBatch') is not null drop table #PREmplsInBatch -- first make sure temp table doesn't already exist
	create table #PREmplsInBatch (Employee int not null)
   
	-- add an index for ensure uniqueness and improve performance
	create unique clustered index biPREmplsInBatch
   	 on #PREmplsInBatch(Employee)

	-- clear temp table
	delete #PREmplsInBatch 

	insert #PREmplsInBatch (Employee)
	select distinct tb.Employee
	from dbo.bPRTB tb (nolock)
	join dbo.bHQBC bc (nolock) on tb.Co = bc.Co and tb.Mth = bc.Mth and tb.BatchId = bc.BatchId
	join dbo.bPREH eh (nolock) on tb.Co = eh.PRCo and tb.Employee = eh.Employee
	join dbo.bPREC ec (nolock) on tb.Co = ec.PRCo and eh.EarnCode = ec.EarnCode
	where bc.Co = @co and bc.PRGroup = @prgroup and bc.PREndDate = @prenddate
	and eh.ActiveYN = 'Y' and ec.Method = 'A'

   
	-- Create temp table to store employees applicable for salary distribution and total hours to distribute
	if object_id('#PRSalDist') is not null drop table #PRSalDist -- first make sure temp table doesn't already exist
	create table #PRSalDist (Employee int not null, TotalHrs numeric(10,2) not null, TotalPosts int not null)
   
	-- add an index for ensure uniqueness and improve performance
	create unique clustered index biPRSalDist
   	 on #PRSalDist(Employee)

	-- clear temp table
	delete #PRSalDist 

	insert #PRSalDist (Employee, TotalHrs, TotalPosts)
	select th.Employee, sum(th.Hours), count(*)
	from dbo.bPRTH th with (nolock)
	join dbo.bPREH eh (nolock) on th.PRCo = eh.PRCo and th.Employee = eh.Employee
	join dbo.bPREC ec1 with (nolock) on ec1.PRCo = th.PRCo and ec1.EarnCode = eh.EarnCode --ec from empl header
	join dbo.bPREC ec2 with (nolock) on ec2.PRCo = th.PRCo and ec2.EarnCode = th.EarnCode --ec in timecard
	where th.PRCo = @co and th.PRGroup = @prgroup and th.PREndDate = @prenddate and 
		th.Employee = isnull(@specempl,th.Employee) and th.PaySeq = isnull(@specpayseq,th.PaySeq) and
		eh.ActiveYN = 'Y' and ec1.Method = 'A' and ec2.IncldSalaryDist = 'Y' and 
		not exists(select e.Employee from #PREmplsInBatch e where e.Employee=th.Employee)
	group by th.Employee

    -- Create a cursor of applicable employees/earn codes
    declare bcEmplPost cursor for
    select th.Employee, th.PaySeq, th.PostSeq, th.PostDate, th.Hours
    from dbo.bPRTH th with (nolock)
	join dbo.bPREC ec with (nolock) on th.PRCo = ec.PRCo and th.EarnCode = ec.EarnCode
    where th.PRCo = @co and th.PRGroup = @prgroup and th.PREndDate = @prenddate and
		exists(select sd.Employee from #PRSalDist sd where sd.Employee=th.Employee) and
		ec.IncldSalaryDist = 'Y' and th.PaySeq = isnull(@specpayseq,th.PaySeq)
    order by th.Employee, th.PaySeq, th.PostSeq, th.Hours

    open bcEmplPost
    select @openEmplPost = 1

    next_EmplPost:    -- loop through
        fetch next from bcEmplPost into @employee, @payseq, @postseq, @postdate, @postedhrs
        if @@fetch_status <> 0
            begin
            close bcEmplPost
	        deallocate bcEmplPost
            select @openEmplPost = 0
            goto end_EmplPost
            end

		-- Before cycling through each employee's postings ...
		--if @currempl is null or (@currempl is not null and @employee <> @currempl)
		if @postingcount = 1
			begin
			-- ... read the salary amount
			select @salaryamt = SalaryAmt from dbo.bPREH with (nolock) where PRCo = @co and Employee = @employee
			-- ... read the total hours and total # of postings to distribute for the employee
			select @totalhrs = TotalHrs, @totalposts = TotalPosts from #PRSalDist where Employee = @employee
		end

		--Issue 128057 - If the posted hours for this timecard are zero skip it.   This is to prevent
		--a divide by zero error.  This was discussed and determined to be the best course of action
		--at the moment.  If customers complain about no warning timecard was skipped we can deal with
		--that at a later release.  MH 4/28/08
		if isnull(@postedhrs,0) = 0
		begin
			--#130653 Adjust @postingcount and possibly @totalamtposted or it will be out of sync for the code 
			--following this. Also moved this code (originally added for issue #128057) to be after the code to read
			--@salaryamt, @totalhrs, and @totalposts to make sure that does not get skipped.  EN 10/21/08
			if @postingcount = @totalposts
				select @totalamtposted = 0, @postingcount = 1
			else
				select @postingcount = @postingcount + 1 --#130653
			goto next_EmplPost
		end

		-- Compute rate & amount for posting
		if @postingcount = @totalposts
			begin -- dump remainder of salary in the last posting
			select @postamt = @salaryamt - @totalamtposted
			select @postrate = round((@postamt / @postedhrs), 2)
			select @totalamtposted = 0, @postingcount = 1
			end
		else
			begin -- else distribute amount and rate based on hours posted
			select @postamt = round(((@postedhrs / @totalhrs) * @salaryamt), 2)
			select @postrate = round((@postamt / @postedhrs), 2)
			select @totalamtposted = @totalamtposted + @postamt, @postingcount = @postingcount + 1
			end

		-- Post timecard Change to batch
		-- compute daynum
        select @daynum = datediff(day,@begindate,@postdate) + 1   -- convert posting date to day number

		-- add timecard to batch
		--#131132 replaced get seq# and insert bPRTB code with call to vspPRTBAddCEntry
		exec @rcode = vspPRTBAddCEntry @co, @prgroup, @prenddate, @mth, @batchid, @prtbud_flag,
			@employee, @payseq, @postseq, @daynum, 'N', 'Y', @postrate, @postamt, null, 'N', 0, @msg output
		if @rcode = 2 select @msg = 'Unable to add updated regular earnings entry to Timecard batch.', @rcode = 1
		if @rcode <> 0 goto bspexit

		select @PRTBAlteredYN = 'Y' -- this flag is in return params

		goto next_EmplPost

	end_EmplPost:
	-- done processing
        
    bspexit:
	if object_id('#PREmplsInBatch') is not null drop table #PREmplsInBatch

	if object_id('#PRSalDist') is not null drop table #PRSalDist

    if @openEmplPost = 1
		begin
		close bcEmplPost
		deallocate bcEmplPost
		end

    return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRSalaryDistrib] TO [public]
GO
