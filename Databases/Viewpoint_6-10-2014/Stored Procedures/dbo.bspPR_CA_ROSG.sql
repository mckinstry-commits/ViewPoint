SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_ROSG]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_CA_ROSG]
   /********************************************************
   * CREATED BY: EN/KK 6/08/2011 
   * MODIFIED BY:  
   *
   * USAGE:
   * 	Calculates rate of gross earning and posts to timecard addons table (bPRTA).
   *
   * INPUT PARAMETERS:
   *	@prco		PR Company
   *	@addon		Allowance earn code
   *	@prgroup	PR Group
   *	@prenddate	Pay Period Ending Date
   *	@employee	Employee
   *	@payseq		Payment Sequence
   *	@craft		Craft
   *	@class		Class
   *	@template	Job Template
   *	@rate		hourly rate of allowance (newrate)
   *
   * OUTPUT PARAMETERS:
   *	@msg	error message if failure
   *
   * RETURN VALUE:
   * 	0 	    success
   *	1 		failure
   **********************************************************/
   	(@prco bCompany = NULL, 
   	 @addon bEDLCode = NULL,
   	 @prgroup bGroup, 
   	 @prenddate bDate,
   	 @employee bEmployee, 
	 @payseq tinyint, 
	 @craft bCraft, 
	 @class bClass, 
	 @template smallint, 
	 @rate bUnitCost = 0, 
	 @msg varchar(255) = NULL OUTPUT)
	 
	AS
	SET NOCOUNT ON

	DECLARE @rcode int, 
			@SubjEC bEDLCode, 
			@openTimecard tinyint, 
			@postseq smallint, 
			@subjectamt bDollar, 
			@amt bDollar
	   
	SELECT @rcode = 0, @subjectamt = 0, @amt = 0
 
	--Cycle through subject earn codes to determine amt
	--Create table variable for all earn codes subject to allowance earn code
	DECLARE @SubjEarns table (SubjEarnCode bEDLCode)

	INSERT @SubjEarns SELECT SubjEarnCode FROM bPRES (NOLOCK) WHERE PRCo = @prco AND EarnCode = @addon

	--Read first Subject earn code
	SELECT @SubjEC = MIN(SubjEarnCode) FROM @SubjEarns 
	WHILE @SubjEC IS NOT NULL
	BEGIN
		--DECLARE cursor on Timecards subject to Addon
		DECLARE bcTimecard CURSOR FOR
			SELECT DISTINCT h.PostSeq, h.Amt FROM bPRTH h (NOLOCK)
			LEFT OUTER JOIN bJCJM j (NOLOCK) ON h.JCCo = j.JCCo AND h.Job = j.Job
			JOIN bPRES s (NOLOCK) ON h.PRCo = s.PRCo AND h.EarnCode = s.SubjEarnCode
			JOIN bPREC e (NOLOCK) ON h.PRCo = e.PRCo AND s.SubjEarnCode = e.EarnCode
			WHERE h.PRCo = @prco 
				AND h.PRGroup = @prgroup 
				AND h.PREndDate = @prenddate
				AND h.Employee = @employee 
				AND h.PaySeq = @payseq
				AND h.Craft = @craft 
				AND h.Class = @class
				AND s.SubjEarnCode = @SubjEC
				AND (( j.CraftTemplate = @template) 
					OR (h.Job IS NULL AND @template IS NULL)
					OR (j.CraftTemplate IS NULL AND @template IS NULL))
				AND e.SubjToAddOns = 'Y'

		--open Timecard cursor
		OPEN bcTimecard
		SELECT @openTimecard = 1

		--loop through rows in Timecard cursor
		next_Timecard:
			FETCH NEXT FROM bcTimecard INTO @postseq, @subjectamt
            IF @@FETCH_STATUS = -1 GOTO end_Timecard
			IF @@FETCH_STATUS <> 0 GOTO next_Timecard

			--Compute allowance including RDO factor rate adjustment (1-(36/40))
			SELECT @amt = @subjectamt * @rate

			--add Timecard Allowance Addon entry
			IF @amt <> 0.00
            BEGIN
				INSERT bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
				VALUES (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @addon, @rate, @amt)
			END
			GOTO next_Timecard
      
  		end_Timecard:
			CLOSE bcTimecard
			DEALLOCATE bcTimecard
			SELECT @openTimecard = 0
			SELECT @SubjEC = MIN(SubjEarnCode) FROM @SubjEarns WHERE SubjEarnCode > @SubjEC
	END


	bspexit:
  		IF @openTimecard = 1
  		BEGIN
  			CLOSE bcTimecard
  			DEALLOCATE bcTimecard
  		END

   		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_ROSG] TO [public]
GO
