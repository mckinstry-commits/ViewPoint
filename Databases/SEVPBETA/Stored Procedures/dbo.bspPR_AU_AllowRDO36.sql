SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_AllowRDO36]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_AU_AllowRDO36]
   /********************************************************
   * CREATED BY: 	EN 3/10/2009 #129888
   * MODIFIED BY:	EN 2/09/2010 #136039 modified from original routine created on 3/10/2009 called 
   *										bspPR_AU_AllowanceRDO - needed to create an alternate 32 hour version
   *
   * USAGE:
   * 	Calculates rate per hour allowance with RDO factor adjustment for a 36 hour week and posts to timecard 
   *	addons table (bPRTA).
   *	The RDO adjustment essentially evens out the subject hours used in rate per hour computation so that
   *	each week the same hours are used.  In other words for an RDO scheme where an RDO day is taken every
   *	2nd week, with this scheme 36 hours are used each week to compute the allowance whereas in the
   *	scheme without the RDO adjustment 40 hours are used the 1st week and 32 are used the 2nd week.
   *	At Probuild this RDO adjustment is used to compute regular time Site, Multi-Storey, and Structural
   *	Frame allowances.
   *
   * INPUT PARAMETERS:
   *	@prco	PR Company
   *	@addon	Allowance earn code
   *	@prgroup	PR Group
   *	@prenddate	Pay Period Ending Date
   *	@employee	Employee
   *	@payseq		Payment Sequence
   *	@craft		Craft
   *	@class		Class
   *	@template	Job Template
   *	@rate	hourly rate of allowance (newrate)
   *
   * OUTPUT PARAMETERS:
   *	@msg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   	(@prco bCompany = null, @addon bEDLCode = null, @prgroup bGroup, @prenddate bDate, @employee bEmployee, 
	@payseq tinyint, @craft bCraft, @class bClass, @template smallint, @rate bUnitCost = 0, 
	@msg varchar(255) = null output)
	as
	set nocount on

	declare @rcode int, @SubjEC bEDLCode, @openTimecard tinyint, @hours bHrs, @postseq smallint, 
		@subjecthours bHrs, @amt bDollar, @procname varchar(30)
   
	select @rcode = 0, @hours = 0, @subjecthours = 0, @amt = 0, @procname = 'bspPR_AU_AllowRDO36'
 
	--Cycle through subject earn codes to determine hours

	--create table variable for all earn codes subject to allowance earn code
	declare @SubjEarns table (SubjEarnCode bEDLCode)

	insert @SubjEarns select SubjEarnCode from bPRES (nolock) where PRCo = @prco and EarnCode = @addon

	--read first Subject earn code
	select @SubjEC = min(SubjEarnCode) from @SubjEarns
	while @SubjEC is not null
		begin
		--declare cursor on Timecards subject to Addon
		declare bcTimecard cursor for
		select distinct h.PostSeq, h.Hours from bPRTH h (nolock)
		left outer join bJCJM j (nolock) on h.JCCo = j.JCCo and h.Job = j.Job
		join bPRES s (nolock) on h.PRCo = s.PRCo and h.EarnCode = s.SubjEarnCode
		join bPREC e (nolock) on h.PRCo = e.PRCo and s.SubjEarnCode = e.EarnCode
		where h.PRCo = @prco and h.PRGroup = @prgroup and h.PREndDate = @prenddate
			and h.Employee = @employee and h.PaySeq = @payseq
			and h.Craft = @craft and h.Class = @class
			and s.SubjEarnCode = @SubjEC
			and (( j.CraftTemplate = @template) or (h.Job is null and @template is null)
			or (j.CraftTemplate is null and @template is null))
			and e.SubjToAddOns = 'Y'

		--open Timecard cursor
		open bcTimecard
		select @openTimecard = 1

		--loop through rows in Timecard cursor
		next_Timecard:
			fetch next from bcTimecard into @postseq, @subjecthours
            if @@fetch_status = -1 goto end_Timecard
			if @@fetch_status <> 0 goto next_Timecard

			--Compute allowance modified by RDO factor rate adjustment (36/40)
			select @subjecthours = @subjecthours * (36.00/40.00)
			select @amt = @subjecthours * @rate

			--add Timecard Allowance Addon entry
			if @amt <> 0.00
                begin
				insert bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
				values (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @addon, @rate, @amt)
				end
			goto next_Timecard
      
  			end_Timecard:
			close bcTimecard
			deallocate bcTimecard
			select @openTimecard = 0

		select @SubjEC = min(SubjEarnCode) from @SubjEarns where SubjEarnCode > @SubjEC
		end


	bspexit:
  	if @openTimecard = 1
  		begin
  		close bcTimecard
  		deallocate bcTimecard
  		end

   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_AllowRDO36] TO [public]
GO
