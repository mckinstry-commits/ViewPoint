SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  proc [dbo].[bspPR_AU_Allowance]
/********************************************************
* CREATED BY: 	EN	03/10/2009	- #129888
* MODIFIED BY:  CHS 06/05/2011	- #146557 TK-15385 D-05231
*
* USAGE:
* 	Calculates basic rate per hour allowance AND posts to timecard addons table (bPRTA).
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
(@prco bCompany = null, @earncode bEDLCode = null, @addonYN bYN, @prgroup bGroup, @prenddate bDate, 
	@employee bEmployee, @payseq tinyint, @craft bCraft, @class bClass, @template smallint, 
	@rate bUnitCost, @amt bDollar OUTPUT, @errmsg varchar(255) = null OUTPUT)

	AS
	SET NOCOUNT ON

	DECLARE @rcode int, @SubjEC bEDLCode, @openTimecard tinyint, @hours bHrs, @postseq smallint, 
		@subjecthours bHrs, @procname varchar(30), @HoursThreshold bHrs
   
	SELECT @rcode = 0, @hours = 0, @subjecthours = 0, @amt = 0, @procname = 'bspPR_AU_Allowance', @HoursThreshold = 9.5
 
 	--create table variable for all posting dates and meal allowance for the day
	--DECLARE @PostDates TABLE (PostDate bDate, AllowAmt bDollar)

	
	
	
	IF @addonYN = 'Y'
		BEGIN
		
		--Cycle through subject earn codes to determine hours

		--create table variable for all earn codes subject to allowance earn code
		DECLARE @SubjEarns TABLE (SubjEarnCode bEDLCode)
			
		INSERT @SubjEarns SELECT SubjEarnCode FROM bPRES (NOLOCK) WHERE PRCo = @prco AND EarnCode = @earncode

		--read first Subject earn code
		SELECT @SubjEC = min(SubjEarnCode) FROM @SubjEarns
		WHILE @SubjEC IS NOT NULL
			BEGIN
			--DECLARE cursor on Timecards subject to Addon
			DECLARE bcTimecard CURSOR FOR
			SELECT DISTINCT h.PostSeq, h.Hours FROM bPRTH h (NOLOCK)
			LEFT OUTER JOIN bJCJM j (NOLOCK) ON h.JCCo = j.JCCo AND h.Job = j.Job
			JOIN bPRES s (NOLOCK) ON h.PRCo = s.PRCo AND h.EarnCode = s.SubjEarnCode
			JOIN bPREC e (NOLOCK) ON h.PRCo = e.PRCo AND s.SubjEarnCode = e.EarnCode
			WHERE h.PRCo = @prco AND h.PRGroup = @prgroup AND h.PREndDate = @prenddate
				AND h.Employee = @employee AND h.PaySeq = @payseq
				AND h.Craft = @craft AND h.Class = @class
				AND s.SubjEarnCode = @SubjEC
				AND (( j.CraftTemplate = @template) OR (h.Job IS NULL AND @template IS NULL)
				OR (j.CraftTemplate IS NULL AND @template is null))
				AND e.SubjToAddOns = 'Y'

			--open Timecard cursor
			OPEN bcTimecard
			SELECT @openTimecard = 1

			--loop through rows in Timecard cursor
			next_Timecard:
				FETCH NEXT FROM bcTimecard INTO @postseq, @subjecthours
				IF @@fetch_status = -1 GOTO end_Timecard
				IF @@fetch_status <> 0 GOTO next_Timecard

				--Compute allowance
				SELECT @amt = @subjecthours * @rate

				--add Timecard Allowance Addon entry
				IF @amt <> 0.00
					BEGIN
					INSERT bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
					VALUES (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @earncode, @rate, @amt)
					END
					
				GOTO next_Timecard
	      
  				end_Timecard:
				CLOSE bcTimecard
				DEALLOCATE bcTimecard
				SELECT @openTimecard = 0

			SELECT @SubjEC = min(SubjEarnCode) FROM @SubjEarns WHERE SubjEarnCode > @SubjEC
			END
		
		END

	ELSE --when @addonYN = 'N'
		BEGIN
		
		SELECT @amt = sum(h.Hours) * @rate
		FROM dbo.bPRTH h (NOLOCK)
		WHERE h.PRCo = @prco 
			AND h.PRGroup = @prgroup 
			AND h.PREndDate = @prenddate
			AND h.Employee = @employee 
			AND h.PaySeq = @payseq
			AND h.EarnCode IN (SELECT SubjEarnCode 
								FROM bPRES s (NOLOCK) 
								WHERE s.PRCo=@prco 
									AND s.EarnCode=@earncode)

		END

	bspexit:
  	IF @openTimecard = 1
  		BEGIN
  		CLOSE bcTimecard
  		DEALLOCATE bcTimecard
  		END

   	RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_Allowance] TO [public]
GO
