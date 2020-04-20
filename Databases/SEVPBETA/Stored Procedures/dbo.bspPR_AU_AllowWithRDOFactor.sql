SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   create  PROCEDURE [dbo].[bspPR_AU_AllowWithRDOFactor]
   /********************************************************
   * CREATED BY: 	EN 4/18/2011 D01575 / #143739
   * MODIFIED BY:	
   *
   * USAGE:
   * 	Calculates rate per hour allowance with an adjustment to use subject earnings hours works minus RDO hours.  RDO
   *	is considered to be 4 hours per week for weekly pay period or 2 hours per week for fortnightly pay periods.
   *	Subject earnings could be both regular and overtime hours worked.
   *    
   *	This is in lieu of routines bspPR_AU_AllowRDO36 and bspPR_AU_AllowRDO38 which only allow for regular time
   *	subject earnings hours.
   *
   *	The difference between this and bspPR_AU_Allowance is the RDO adjustment.  For allowances that are not computed
   *	on RDO time taken this method smooths out the allowance computation so that paychecks don't take a big hit
   *	on weeks that an employee takes his/her RDO day.
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
	(@prco bCompany = null, 
	 @addon bEDLCode = null, 
	 @prgroup bGroup, 
	 @prenddate bDate, 
	 @employee bEmployee, 
	 @payseq tinyint, 
	 @craft bCraft, 
	 @class bClass, 
	 @template smallint, 
	 @rate bUnitCost = 0, 
	 @msg varchar(255) = null OUTPUT
	)
	AS
	SET NOCOUNT ON

	--start by getting a list of the subject hours for this addon
	DECLARE @SubjectHours TABLE (SubjectEarnCode bEDLCode, PostSeq smallint, SubjectHours bHrs)

	INSERT @SubjectHours
		SELECT PRES.SubjEarnCode, PRTH.PostSeq, PRTH.Hours
		FROM dbo.bPRES PRES (NOLOCK)
		JOIN dbo.bPRTH PRTH (NOLOCK) ON PRTH.PRCo = PRES.PRCo and PRTH.EarnCode = PRES.SubjEarnCode
		LEFT OUTER JOIN dbo.bJCJM JCJM (NOLOCK) ON JCJM.JCCo = PRTH.JCCo AND JCJM.Job = PRTH.Job
		JOIN dbo.bPREC PREC (NOLOCK) ON PREC.PRCo = PRTH.PRCo AND PREC.EarnCode = PRES.SubjEarnCode
		WHERE PRES.PRCo = @prco AND PRES.EarnCode = @addon
			  AND PRTH.PRGroup = @prgroup AND PRTH.PREndDate = @prenddate
			  AND PRTH.Employee = @employee AND PRTH.PaySeq = @payseq
			  AND PRTH.Craft = @craft AND PRTH.Class = @class
			  AND (
				  (JCJM.CraftTemplate = @template) 
				   OR (PRTH.Job IS NULL AND @template IS NULL)
				   OR (JCJM.CraftTemplate IS NULL AND @template IS NULL )
				  )
			  AND PREC.SubjToAddOns = 'Y'

	--need RDO Hours per pay period to compute the RDO ratio
	--this routine supports Weekly (4 RDO hours every week) and fortnightly (4 RDO hours every 2 weeks) computation
	DECLARE @PayPdRDOHours bHrs
	SELECT @PayPdRDOHours = 4

	--need total hours per pay period to compute the RDO ratio
	DECLARE @PayPdHoursWorked bHrs
	SELECT @PayPdHoursWorked = SUM(SubjectHours) FROM @SubjectHours

	--add timecard allowance addons to PRTA computing the rate per out amount on a rate of subject hours 
	-- minus the RDO portion (RDO ration of RDOHours / HoursWorked multiplied by the subject hours)
	INSERT bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
	SELECT @prco, @prgroup, @prenddate, @employee, @payseq, PostSeq, @addon, @rate, 
			ROUND((SubjectHours - ((@PayPdRDOHours / @PayPdHoursWorked) * SubjectHours)) * @rate,2)
	FROM @SubjectHours

	--Adjust For Rounding
	-- get the total addon amount computed so far
	DECLARE @TotalAddonAmount bDollar
	SELECT @TotalAddonAmount = SUM(Amt) 
	FROM dbo.bPRTA (NOLOCK)
	WHERE	PRCo = @prco
			AND PRGroup = @prgroup
			AND PREndDate = @prenddate
			AND Employee = @employee
			AND PaySeq = @payseq
			AND EarnCode = @addon
			AND Rate = @rate

	-- determine the post sequence of the PRTA entry to adjust
	DECLARE @MaxPostSeq smallint
	SELECT @MaxPostSeq = MAX(PostSeq) 
	FROM dbo.bPRTA (NOLOCK)
	WHERE	PRCo = @prco
			AND PRGroup = @prgroup
			AND PREndDate = @prenddate
			AND Employee = @employee
			AND PaySeq = @payseq
			AND EarnCode = @addon
			AND Rate = @rate

	-- adjust the amount based on the difference of the weekly addon amount and the amount computed so far
	UPDATE dbo.bPRTA
	SET Amt = Amt + (((@PayPdHoursWorked - @PayPdRDOHours) * @rate) - @TotalAddonAmount)
	WHERE	PRCo = @prco
			AND PRGroup = @prgroup
			AND PREndDate = @prenddate
			AND Employee = @employee
			AND EarnCode = @addon
			AND PaySeq = @payseq
			AND PostSeq = @MaxPostSeq
			AND Rate = @rate


   	RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_AllowWithRDOFactor] TO [public]
GO
