SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_ROSG]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  proc [dbo].[bspPR_AU_ROSG]
/********************************************************
* CREATED BY: 	EN 3/10/2009 #129888
* MODIFIED BY:  EN 5/15/2012 - D-04874 add ability to use an exempt limit
*				EN 6/14/2012 - D-05133/TK-15692 changed @msg to @errmsg to resolve error when this procedure is called from bspPRProcessAddons
*				EN 08/29/2012 - D-05698/TK-17502 retrofit this routine to allow use when set up as an auto earning
*
* USAGE:
* 	Calculates rate of gross subject earnings based on subject earnings defined in PRES table.
*	If being used to compute addon earnings, posts the computed amount to timecard addons table (bPRTA).
*	If being used to compute auto earnings, passes back the computed amount as a return parameter.
*
* INPUT PARAMETERS:
*	@prco		PR Company
*	@earncode	Allowance earn code
*	@addonYN	= Y if being called from bspPRProcessAddons, otherwise = N
*	@prgroup	PR Group
*	@prenddate	Pay Period Ending Date
*	@employee	Employee
*	@payseq		Payment Sequence
*	@craft		Craft
*	@class		Class
*	@template	Job Template
*	@rate		hourly rate of allowance (newrate)
*	@accumsubj	accumulated ytd subject amount 
*	@exemptamt	exemption limit amount 
*
* OUTPUT PARAMETERS:
*	@amt		computed earnings amount to return (only if computing as an auto earning)
*	@errmsg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
(@prco bCompany = NULL, 
 @earncode bEDLCode = NULL, 
 @addonYN bYN, 
 @prgroup bGroup = NULL, 
 @prenddate bDate = NULL, 
 @employee bEmployee = NULL, 
 @payseq tinyint = NULL, 
 @craft bCraft = NULL, 
 @class bClass = NULL, 
 @template smallint = NULL, 
 @rate bUnitCost = 0, 
 @ytdearns bDollar = 0, 
 @exemptamt bDollar = 0, 
 @amt bDollar OUTPUT, 
 @errmsg varchar(255) = NULL OUTPUT)

AS
SET NOCOUNT ON

DECLARE @totalsubject bDollar,
		@totaleligible bDollar,
		@prorate bRate,
		@SubjEC bEDLCode, 
		@postseq smallint, 
		@postedsubjamt bDollar, 
		@prta_amt bDollar,
		@checksubjtoaddonearnings varchar(1)
   
SELECT	@postedsubjamt = 0, 
		@prta_amt = 0

--make sure that input params related only to computed addon earnings are not a factor when computing auto earnings
IF @addonYN	= 'N'
BEGIN
	SELECT @craft = NULL,
		   @class = NULL,
		   @template = NULL
END

SELECT @checksubjtoaddonearnings = (CASE WHEN @addonYN = 'Y' THEN 'Y' ELSE NULL END) -- this flag will be Y if computing an addon, otherwise it is NULL

--Part A: create a table variable to be used in Parts B and C to identify all earn codes subject to the allowance earn code
DECLARE @SubjEarns TABLE (SubjEarnCode bEDLCode)

INSERT @SubjEarns 
SELECT SubjEarnCode 
FROM dbo.bPRES 
WHERE PRCo = @prco AND EarnCode = @earncode

--Part B: Compare total subject amount to exemption limit to determine total eligible amount
--Prorate is computed when eligible amount is different than subject and will be used to determine the eligible amounts
-- to use when posting detail to PRTA

--determine total subject amount
SELECT @totalsubject = ISNULL(SUM(th.Amt),0)
FROM dbo.bPRTH th (NOLOCK)
JOIN @SubjEarns se ON se.SubjEarnCode = th.EarnCode
LEFT OUTER JOIN dbo.bJCJM jm (NOLOCK) ON jm.JCCo = th.JCCo AND 
										 jm.Job = th.Job
JOIN dbo.bPREC ec ON ec.PRCo = th.PRCo AND 
					 ec.EarnCode = se.SubjEarnCode
WHERE th.PRCo = @prco AND 
	  th.PRGroup = @prgroup AND 
	  th.PREndDate = @prenddate AND
	  th.Employee = @employee AND 
	  th.PaySeq = @payseq AND 
	  (th.Craft IS NULL OR th.Craft = ISNULL(@craft,th.Craft)) AND 
	  (th.Class IS NULL OR th.Class = ISNULL(@class,th.Class)) AND 
	  (
	   (jm.CraftTemplate = ISNULL(@template,jm.CraftTemplate)) OR 
	   (th.Job IS NULL AND @template IS NULL) OR 
	   (jm.CraftTemplate IS NULL AND @template IS NULL)
	  ) AND 
	  ec.SubjToAddOns = ISNULL(@checksubjtoaddonearnings,ec.SubjToAddOns)

--compare total subject to exemption limit to determine total eligible amount
--case 1: handle amount reversal crossing back over the exemption limit
IF (@ytdearns > @exemptamt AND 
	@ytdearns + @totalsubject <= @exemptamt)
BEGIN
	SELECT	@totaleligible = @exemptamt - @ytdearns
END
--case 2: exemption limit not yet reached
ELSE 
IF @exemptamt >= @ytdearns + @totalsubject
BEGIN
	SELECT	@totaleligible = 0
END
--case 3: exemption limit just reached in this pay pd/pay seq
ELSE 
IF (@ytdearns <= @exemptamt AND 
	@ytdearns + @totalsubject > @exemptamt)
BEGIN
	SELECT  @totaleligible = (@ytdearns + @totalsubject) - @exemptamt
END
--case 4: exemption limit reached in previous pay pd/pay seq
ELSE
SELECT	@totaleligible = @totalsubject 

--compute prorate if needed
IF @totaleligible <> @totalsubject AND @totalsubject <> 0
BEGIN
	SELECT @prorate = @totaleligible / @totalsubject
END
ELSE
BEGIN
	SELECT @prorate = 1
END

--Part C: Compute amount based on subject earnings prorated for RDO factor
IF @addonYN = 'Y'
BEGIN
	--read first Subject earn code
	SELECT @SubjEC = MIN(SubjEarnCode) 
	FROM @SubjEarns

	--Cycle through subject earn codes to determine amt
	WHILE @SubjEC IS NOT NULL
	BEGIN
		--declare cursor on Timecards subject to Addon
		DECLARE bcTimecard CURSOR FOR
		SELECT DISTINCT th.PostSeq, th.Amt 
		FROM dbo.bPRTH th (NOLOCK)
		LEFT OUTER JOIN dbo.bJCJM jm (NOLOCK) ON jm.JCCo = th.JCCo AND 
												 jm.Job = th.Job
		JOIN dbo.bPREC ec ON ec.PRCo = th.PRCo AND 
							 ec.EarnCode = th.EarnCode
		WHERE th.PRCo = @prco AND 
			  th.PRGroup = @prgroup AND 
			  th.PREndDate = @prenddate AND
			  th.Employee = @employee AND 
			  th.PaySeq = @payseq AND 
			  th.Craft = @craft AND 
			  th.Class = @class AND 
			  th.EarnCode = @SubjEC AND 
			  (
			   (jm.CraftTemplate = @template) OR 
			   (th.Job IS NULL AND @template IS NULL) OR 
			   (jm.CraftTemplate IS NULL AND @template IS NULL)
			  ) AND 
			  ec.SubjToAddOns = 'Y'

		--open Timecard cursor
		OPEN bcTimecard

		--loop through rows in Timecard cursor
		FETCH NEXT FROM bcTimecard INTO @postseq, @postedsubjamt
		WHILE @@FETCH_STATUS <> -1
		BEGIN
			IF @@FETCH_STATUS = 0
			BEGIN
				--Compute allowance including RDO factor rate adjustment (1-(36/40))
				SELECT @prta_amt = (@postedsubjamt * @prorate) * @rate

				--add Timecard Allowance Addon entry
				IF @prta_amt <> 0.00
				BEGIN
					INSERT dbo.bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
					VALUES (@prco, @prgroup, @prenddate, @employee, @payseq, @postseq, @earncode, @rate, @prta_amt)
				END
			END
			FETCH NEXT FROM bcTimecard INTO @postseq, @postedsubjamt
		END

		CLOSE bcTimecard
		DEALLOCATE bcTimecard

		SELECT @SubjEC = MIN(SubjEarnCode) 
		FROM @SubjEarns 
		WHERE SubjEarnCode > @SubjEC
	END
END
ELSE
BEGIN
	--Compute allowance including RDO factor rate adjustment (1-(36/40))
	SELECT @amt = (@totalsubject * @prorate) * @rate
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_ROSG] TO [public]
GO
