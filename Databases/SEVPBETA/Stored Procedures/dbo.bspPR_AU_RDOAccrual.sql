SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_RDOAccrual]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_AU_RDOAccrual]
   /********************************************************
   * CREATED BY: 	EN 2/05/2010 #136039 new earnings routine to compute RDO on subject earnings (regular earnings)
   * MODIFIED BY:	EN 9/30/2010 #141284 ability to compute RDO only on days in which the regular hours posted satisfy an hours threshold
   *
   * USAGE:
   * 	Compute rate per hour for any days with time posted to subject earnings codes.
   *	Used for RDO accrual earnings code setup with regular earnings as Subject Earnings.
   *
   * INPUT PARAMETERS:
   *	@prco	PR Company
   *	@earncode	earn code
   *	@prgroup	PR Group
   *	@prenddate	Pay Period Ending Date
   *	@employee	Employee
   *	@payseq	Pay Sequence
   *	@rate		hourly rate
   *	@tothours	total hours posted to PRTH and PRTB that is subject to Auto Earnings
   *	@totamt		total earnings amount posted to PRTH, PRTB and Addon Earnings that is subject to Auto Earnings
   *	@stdhours	from PRAE.StdHours ... =Y if using overriding PRPC.Hrs value with PRAE.Hours
   *	@praehours	Hours column from PRAE
   *	@prpchours	Hrs column from PRPC
   *	@daycount	# of days for which timecards have been posted to this employee in the pay period 
   *	@MiscAmt1	value from bPRRM
   *
   * OUTPUT PARAMETERS:
   *	@hours		computed RDO hours
   *	@amt		computed amount
   *	@errmsg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    	success
   *	1 		failure
   **********************************************************/
   	(@prco bCompany = NULL, @earncode bEDLCode = NULL, @prgroup bGroup, @prenddate bDate, @employee bEmployee, 
	@payseq TINYINT, @rate bUnitCost = 0, @tothours bHrs = 0, @totamt bDollar = 0, @stdhours bYN = 'N',
	@praehours bHrs = 0, @prpchours bHrs = 0, @daycount TINYINT = 0, @MiscAmt bDollar = 0, @hours bHrs OUTPUT, 
	@amt bDollar OUTPUT, @errmsg VARCHAR(255) = null OUTPUT)
	AS
	SET NOCOUNT ON

	DECLARE @rcode INT, @subjecthours bHrs
   
	SELECT @rcode = 0, @subjecthours = 0
 
	IF @MiscAmt = 0.00
		BEGIN
			--determine subject regular hours
			SELECT @subjecthours = SUM(h.Hours) 
			FROM bPRTH h (NOLOCK)
			WHERE h.PRCo = @prco 
				AND h.PRGroup = @prgroup 
				AND h.PREndDate = @prenddate
				AND h.Employee = @employee
				AND h.EarnCode IN (SELECT SubjEarnCode FROM bPRES WHERE PRCo=@prco AND EarnCode=@earncode)
		END
	ELSE
		BEGIN
			--determine subject regular hours applying daily hours threshold (stored in @MiscAmt)
			DECLARE @TallyHrsWithThreshold TABLE
				(
				DailyApplicableHours bHrs
				)

			INSERT @TallyHrsWithThreshold
			SELECT CASE WHEN SUM(h.Hours) < @MiscAmt THEN 0.00 ELSE SUM(h.Hours) END
			FROM bPRTH h (NOLOCK)
			WHERE h.PRCo = @prco 
				AND h.PRGroup = @prgroup 
				AND h.PREndDate = @prenddate
				AND h.Employee = @employee
				AND h.EarnCode IN (SELECT SubjEarnCode FROM bPRES WHERE PRCo=@prco AND EarnCode=@earncode)
			GROUP BY h.PostDate

			SELECT @subjecthours = SUM(DailyApplicableHours) FROM @TallyHrsWithThreshold
		END

	--compute hours and amount using factored hours
	SELECT @hours = ((@praehours / 40) -1) * @subjecthours
	SELECT @amt = @rate * @hours


   	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_RDOAccrual] TO [public]
GO
