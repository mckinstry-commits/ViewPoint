SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_AU_AmountPerDiemAward]    Script Date: 02/27/2008 13:19:16 ******/
CREATE  proc [dbo].[bspPR_AU_AmountPerDiemAward]
/********************************************************
* CREATED BY: 	EN 06/05/2012 D-05200/TK-152389/#146483
* MODIFIED BY:  EN/KK 06/08/12 - D-05183 Modified to grab the craft/class template info to determine the totalposted vs totalallowance difference 
*
* USAGE:
* 	Computes an award as an amount per day using optional weekday and weekend day thresholds.
*	This routine may be called by either PR Auto Earnings or PR Payroll Processing for addon earnings.
*	For auto earnings the total amount of the award will be returned and bspPRAutoEarnInit
*	will handle the bPRTB posting.  
*	For addon earnings, this routine will handle posting to the timecard addons table (bPRTA).  
*
*	Note: A null threshold passed into this routine indicates no threshold.  A threshold of 0 indicates
*
* INPUT PARAMETERS:
*	@prco				PR Company
*	@earncode			Allowance earn code
*	@addonYN			'Y' if computing as addon earn; 'N' if computing as auto earning
*	@prgroup			PR Group
*	@prenddate			Pay Period Ending Date
*	@employee			Employee
*	@payseq				Payment Sequence
*	@weekdaythreshold	Weekday Threshold (from bPRRM)
*	@weekendthreshold	Weekend Day Threshold (from bPRRM)
*	@craft				used if routine called from PR Process
*	@class				used if routine called from PR Process
*	@template			Job Template ... used if routine called from PR Process
*	@rate				used if routine called from Auto Earn Init
*
* OUTPUT PARAMETERS:
*	@amt		used if routine called from Auto Earn Init
*	@errmsg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 			failure
**********************************************************/
(@prco bCompany = NULL, 
 @earncode bEDLCode = NULL, 
 @addonYN bYN, 
 @prgroup bGroup, 
 @prenddate bDate, 
 @employee bEmployee, 
 @payseq tinyint, 
 @weekdaythreshold bDollar, 
 @weekendthreshold bDollar, 
 @craft bCraft, 
 @class bClass, 
 @template smallint, 
 @rate bUnitCost, 
 @amt bDollar output, 
 @errmsg varchar(255) = null OUTPUT)

AS
SET NOCOUNT ON
SET DATEFIRST 7 -- This assures that we can distinguish weekdays from weekend days in case user default language 
				-- is set to something other than us_english which would adversely affect the weekday returned by 
				-- DATEPART().

DECLARE @TotalEarnings bDollar, 
		@OldRate bUnitCost, 
		@NewRate bUnitCost, 
		@EffectiveDate bDate, 
		@LastPostSeq smallint, 
		@TotalAward bDollar, 
		@TotalPostedAmount bDollar,
		@PostDate bDate

SELECT  @amt = 0

--create table variable to collect all posting dates eligible for the award and the award amount for each day
DECLARE @PostDates TABLE (PostDate bDate, TotalHours bHrs, TotalEarnings bDollar, AwardAmount bDollar)

IF @addonYN = 'Y'
BEGIN --compute as addon earnings and post distributions in bPRTA

	--get Craft Effective Date with possible override by Template
	SELECT @EffectiveDate = EffectiveDate 
	FROM dbo.bPRCM 
	WHERE PRCo = @prco AND Craft = @craft
	
	SELECT @EffectiveDate = EffectiveDate 
	FROM dbo.bPRCT 
	WHERE	PRCo = @prco AND 
			Craft = @craft AND 
			Template = @template AND 
			OverEffectDate = 'Y'

	--get Craft, Class Addon Rates with possible override by Template - lookup 0.00 Factor
	SELECT @OldRate = 0.00, @NewRate = 0.00
	
	SELECT @OldRate = OldRate, @NewRate = NewRate 
	FROM dbo.bPRCI 
	WHERE	PRCo = @prco AND 
			Craft = @craft AND 
			EDLType = 'E' AND 
			EDLCode = @earncode AND 
			Factor = 0.00
			
	SELECT @OldRate = OldRate, @NewRate = NewRate 
	FROM dbo.bPRCF 
	WHERE	PRCo = @prco AND 
			Craft = @craft AND 
			Class = @class AND 
			EarnCode = @earncode AND 
			Factor = 0.00
			
	SELECT @OldRate = OldRate, @NewRate = NewRate 
	FROM dbo.bPRTI 
	WHERE	PRCo = @prco AND 
			Craft = @craft AND 
			Template = @template AND 
			EDLType = 'E' AND 
			EDLCode = @earncode AND 
			Factor = 0.00
			
	SELECT @OldRate = OldRate, @NewRate = NewRate 
	FROM dbo.bPRTF 
	WHERE	PRCo = @prco AND 
			Craft = @craft AND 
			Class = @class AND 
			Template = @template AND 
			EarnCode = @earncode AND 
			Factor = 0.00

	--insert daily hours and earnings into @PostDates for all days worked during the pay period
	INSERT @PostDates
	SELECT	h.PostDate, 
			SUM(h.Hours),
			SUM(h.Amt),
			(CASE WHEN h.PostDate >= @EffectiveDate THEN @NewRate ELSE @OldRate END)
	FROM dbo.bPRTH h (NOLOCK)
	LEFT OUTER JOIN dbo.bJCJM j (NOLOCK) ON h.JCCo = j.JCCo AND 
											h.Job = j.Job
	JOIN dbo.bPREC e (NOLOCK) ON h.PRCo = e.PRCo AND 
								 h.EarnCode = e.EarnCode
	WHERE	h.PRCo = @prco AND 
			h.PRGroup = @prgroup AND 
			h.PREndDate = @prenddate AND 
			h.Employee = @employee AND 
			h.PaySeq = @payseq AND 
			h.EarnCode IN  (SELECT SubjEarnCode 
							FROM dbo.bPRES s (NOLOCK) 
							WHERE s.PRCo = @prco AND s.EarnCode = @earncode
						   ) 
			AND 
			h.Craft = @craft AND 
			h.Class = @class AND 
			(
			 (j.CraftTemplate = @template) OR 
			 (h.Job IS NULL AND @template IS NULL) OR 
			 (j.CraftTemplate IS NULL AND @template IS NULL)
			)
			AND 
			e.SubjToAddOns = 'Y'
	GROUP BY h.PostDate

	--remove any entries from @PostDates ...
	--	1) where hours threshold is null
	--	2) where hours threshold is greater than zero and threshold was not exceeded
	--  3) where hours threshold is zero and hours worked evaluates to 0 (possible positive and negative hours cancel each other out)
	DELETE @PostDates
	WHERE  (
			(DATEPART(WEEKDAY, PostDate) IN (2,3,4,5,6) AND TotalHours <= @weekdaythreshold) OR
			(DATEPART(WEEKDAY, PostDate) IN (1,7) AND TotalHours <= @weekendthreshold) OR
			(DATEPART(WEEKDAY, PostDate) IN (2,3,4,5,6) AND TotalHours = 0) OR
			(DATEPART(WEEKDAY, PostDate) IN (1,7) AND TotalHours = 0)
		   )
		   
	--cycle through eligible dates found for generating award
	SELECT @PostDate = MIN(PostDate) FROM @PostDates

	WHILE @PostDate IS NOT NULL
	BEGIN
		--get total award to post
		SELECT	@TotalEarnings = TotalEarnings,
				@TotalAward = AwardAmount
		FROM @PostDates WHERE PostDate = @PostDate
		IF @TotalAward <> 0
		BEGIN
			-- distibute based on proportion of earnings to total daily earnings 
			INSERT bPRTA (PRCo,		PRGroup,	PREndDate,	Employee,
						  PaySeq,	PostSeq,	EarnCode,	Rate,		
						  Amt)
			SELECT	@prco,		@prgroup,	@prenddate,		@employee,	
					@payseq,	PostSeq,	@earncode,		0,				
					ROUND((Amt / @TotalEarnings) * @TotalAward, 2)
			FROM dbo.bPRTH h (NOLOCK)
			LEFT OUTER JOIN dbo.bJCJM j (NOLOCK) ON h.JCCo = j.JCCo AND 
													h.Job = j.Job
			JOIN dbo.bPREC e (NOLOCK) ON h.PRCo = e.PRCo AND 
										 h.EarnCode = e.EarnCode
			WHERE	h.PRCo = @prco AND 
					h.PRGroup = @prgroup AND 
					h.PREndDate = @prenddate AND 
					h.Employee = @employee AND 
					h.PaySeq = @payseq AND 
					h.PostDate = @PostDate AND 
					h.Craft = @craft AND 
					h.Class = @class AND 
					h.EarnCode IN  (SELECT SubjEarnCode 
									FROM dbo.bPRES s (NOLOCK) 
									WHERE s.PRCo = @prco AND s.EarnCode = @earncode
								   ) 
					AND 
					(
					 (j.CraftTemplate = @template) OR 
					 (h.Job IS NULL AND @template IS NULL) OR 
					 (j.CraftTemplate IS NULL AND @template IS NULL)
					) 
					AND 
					e.SubjToAddOns = 'Y' AND 
					(
					 (DATEPART(WEEKDAY, @PostDate) IN (2,3,4,5,6) AND DATEPART(WEEKDAY,h.PostDate) IN (2,3,4,5,6)) OR
					 (DATEPART(WEEKDAY, @PostDate) IN (1,7) AND DATEPART(WEEKDAY,h.PostDate) IN (1,7))
					)
			ORDER BY PostSeq

		END
		
		SELECT @PostDate = MIN(PostDate) FROM @PostDates WHERE PostDate > @PostDate
	END
	--compare total posted against allowance to determine need to update the difference 
	--D-05183 Modified the select statement to grab the craft/class template information
	SELECT @TotalPostedAmount = SUM(a.Amt), @LastPostSeq = MAX(a.PostSeq)  
	FROM dbo.bPRTA a (NOLOCK)
	JOIN dbo.bPRTH h (NOLOCK) ON h.PRCo = a.PRCo
								 AND h.PRGroup = a.PRGroup
								 AND h.PREndDate = a.PREndDate
								 AND h.Employee = a.Employee
								 AND h.PaySeq = a.PaySeq
								 AND h.PostSeq = a.PostSeq
	LEFT OUTER JOIN dbo.bJCJM j (nolock) on j.JCCo = h.JCCo and j.Job = h.Job
	WHERE a.PRCo = @prco 
		  AND a.PRGroup = @prgroup 
		  AND a.PREndDate = @prenddate 
		  AND a.Employee = @employee 
		  AND a.PaySeq = @payseq
		  AND a.EarnCode = @earncode
		  AND h.Craft = @craft 
		  AND h.Class = @class
		  AND (
			   (j.CraftTemplate = @template) 
			   OR (h.Job IS NULL AND @template IS NULL)
			   OR (j.CraftTemplate IS NULL AND @template IS NULL)
			  )	

	SELECT @TotalAward = SUM(AwardAmount) FROM @PostDates

	IF @TotalAward <> @TotalPostedAmount
	BEGIN
		-- update difference to last entry for the day 
		UPDATE bPRTA 
		SET Amt = Amt + (@TotalAward - @TotalPostedAmount)
		WHERE	PRCo = @prco AND 
				PRGroup = @prgroup AND 
				PREndDate = @prenddate AND 
				Employee = @employee AND 
				PaySeq = @payseq AND 
				PostSeq = @LastPostSeq AND 
				EarnCode = @earncode
	END


END --when @addonYN = 'Y'
ELSE --when @addonYN = 'N'
BEGIN
	--insert daily hours and earnings into @PostDates for all days worked during the pay period
	INSERT @PostDates
	SELECT	h.PostDate, 
			SUM(h.Hours),
			SUM(h.Amt),
			@rate
	FROM dbo.bPRTH h (NOLOCK)
	WHERE	h.PRCo = @prco AND 
			h.PRGroup = @prgroup AND 
			h.PREndDate = @prenddate AND 
			h.Employee = @employee AND 
			h.PaySeq = @payseq AND 
			h.EarnCode IN  (SELECT SubjEarnCode 
							FROM dbo.bPRES s (NOLOCK) 
							WHERE s.PRCo = @prco AND s.EarnCode = @earncode
						   ) 
	GROUP BY h.PostDate

	--remove any entries from @PostDates for which the hours threshold was not exceeded
	DELETE @PostDates
	WHERE  (
			(DATEPART(WEEKDAY, PostDate) IN (2,3,4,5,6) AND TotalHours <= @weekdaythreshold) OR
			(DATEPART(WEEKDAY, PostDate) IN (1,7) AND TotalHours <= @weekendthreshold) OR
			(DATEPART(WEEKDAY, PostDate) IN (2,3,4,5,6) AND TotalHours = 0) OR
			(DATEPART(WEEKDAY, PostDate) IN (1,7) AND TotalHours = 0)
		   )
		   
	--compute total amount of award to pass as output parameter
	SELECT @amt = SUM(AwardAmount) 
	FROM @PostDates
END


RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspPR_AU_AmountPerDiemAward] TO [public]
GO
