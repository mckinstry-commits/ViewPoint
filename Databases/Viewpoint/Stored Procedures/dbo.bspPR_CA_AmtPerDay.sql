SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPR_CA_AmtPerDay]    Script Date: 02/27/2008 13:19:16 ******/
   CREATE  proc [dbo].[bspPR_CA_AmtPerDay]
   /********************************************************
   * CREATED BY: EN/KK 6/08/2011 
   * MODIFIED BY:  
   *
   * USAGE:
   * 	Calculates amount per day (based on each day subject earnings were posted or std days if Post To All
   *	was checked) and posts to timecard addons table (bPRTA).  The amount is stored in craft/class/template 
   *	pay rate tables.
   *
   * INPUT PARAMETERS:
   *	@prco	PR Company
   *	@earncode	Allowance earn code
   *	@prgroup	PR Group
   *	@prenddate	Pay Period Ending Date
   *	@employee	Employee
   *	@payseq		Payment Sequence
   *	@craft		used if routine called from PR Process
   *	@class		used if routine called from PR Process
   *	@template	Job Template ... used if routine called from PR Process
   *	@posttoall	earnings posted to all days - Y or N
   *	@addonYN	'Y' if computing as addon earn; 'N' if computing as auto earning
   *	@rate		used if routine called from Auto Earn Init
   *
   * OUTPUT PARAMETERS:
   *	@amt		used if routine called from Auto Earn Init
   *	@errmsg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    success
   *	1 		failure
   **********************************************************/
   	(@prco bCompany = NULL, 
   	 @earncode bEDLCode = NULL, 
   	 @prgroup bGroup, 
   	 @prenddate bDate, 
   	 @employee bEmployee, 
	 @payseq tinyint, 
	 @craft bCraft, 
	 @class bClass, 
	 @template smallint, 
	 @posttoall bYN, 
	 @addonYN bYN,
	 @rate bUnitCost, 
	 @amt bDollar OUTPUT, 
	 @errmsg varchar(255) = NULL OUTPUT)
	 
	AS
	SET NOCOUNT ON

	DECLARE @rcode int, 
			@totalearns bDollar, 
			@addonamt bDollar, 
			@oldrate bUnitCost, 
			@newrate bUnitCost, 
			@effectdate bDate, 
			@stddays tinyint, 
			@amtdist bDollar, 
			@lastpostseq smallint, 
			@postseq smallint,
			@distamt bDollar, 
			@postdate bDate, 
			@numdays tinyint, 
			@totalallowance bDollar, 
			@totalposted bDollar
   
	SELECT @rcode = 0, @amt = 0

	-- Earnings posted to all days - use Pay Periods standard # of days 
	IF @posttoall = 'Y'
	BEGIN
		-- get standard # of days from Pay Period Control
		SELECT @stddays = Days FROM dbo.bPRPC WITH (NOLOCK)
		WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @errmsg = 'PR Group and Ending Date not setup in Pay Period Control!', @rcode = 1
			GOTO bspexit
		END
		
		--when @addonYN = 'Y' compute as addon earnings and post distributions in bPRTA
		IF @addonYN = 'Y'
		BEGIN 
			/* get Craft Effective Date with possible override by Template */
			SELECT @effectdate = EffectiveDate FROM bPRCM WHERE PRCo = @prco 
																AND Craft = @craft
			SELECT @effectdate = EffectiveDate FROM bPRCT WHERE PRCo = @prco 
																AND Craft = @craft
																AND Template = @template 
																AND OverEffectDate = 'Y'

			/* get Craft, Class Addon Rates with possible override by Template - lookup 0.00 Factor */
			SELECT @oldrate = 0.00, @newrate = 0.00
			SELECT @oldrate = OldRate, @newrate = NewRate FROM bPRCI WHERE PRCo = @prco
																		   AND Craft = @craft 
																		   AND EDLType = 'E' 
																		   AND EDLCode = @earncode 
																		   AND Factor = 0.00
			SELECT @oldrate = OldRate, @newrate = NewRate FROM bPRCF WHERE PRCo = @prco
																		   AND Craft = @craft 
																		   AND Class = @class 
																		   AND EarnCode = @earncode 
																		   AND Factor = 0.00
			SELECT @oldrate = OldRate, @newrate = NewRate FROM bPRTI WHERE PRCo = @prco
																		   AND Craft = @craft 
																		   AND Template = @template 
																		   AND EDLType = 'E' 
																		   AND EDLCode = @earncode 
																		   AND Factor = 0.00
			SELECT @oldrate = OldRate, @newrate = NewRate FROM bPRTF WHERE PRCo = @prco
																		   AND Craft = @craft 
																		   AND Class = @class 
																		   AND Template = @template 
																		   AND EarnCode = @earncode 
																		   AND Factor = 0.00

			SELECT @totalearns = ISNULL(SUM(Amt),0.00)
			FROM bPRTH h
			LEFT OUTER JOIN bJCJM j ON h.JCCo = j.JCCo AND h.Job = j.Job
			JOIN bPREC e ON h.PRCo = e.PRCo AND h.EarnCode = e.EarnCode
			WHERE h.PRCo = @prco 
				  AND h.PRGroup = @prgroup 
				  AND h.PREndDate = @prenddate
				  AND h.Employee = @employee 
				  AND h.PaySeq = @payseq
				  AND h.EarnCode IN (SELECT SubjEarnCode 
									 FROM bPRES s (NOLOCK) 
									 WHERE s.PRCo=@prco AND s.EarnCode=@earncode)
				  AND h.Craft = @craft 
				  AND h.Class = @class
				  AND (( j.CraftTemplate = @template) 
						OR (h.Job IS NULL AND @template IS NULL)
						OR (j.CraftTemplate IS NULL AND @template IS NULL))
				  AND e.SubjToAddOns = 'Y'

			IF @totalearns <> 0 --continue if there was something to distribute
			BEGIN
				-- calculate Addon amount using Pay Pd Ending Date to determine rate
				SELECT @addonamt = @oldrate * @stddays
				IF @prenddate >= @effectdate SELECT @addonamt = @newrate * @stddays

				-- Distribute Addon amount proportionately to all subject earnings, requires total earnings
				-- used by Flat Amount, Rate of Gross, and Rate per Day when Posting to All = 'Y' 
				-- initialize amount distributed
				SELECT @amtdist = 0.00, @lastpostseq = 0

				-- distibute addonamt based on proportion of earnings to total earnings
				INSERT bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
				SELECT @prco, @prgroup, @prenddate, @employee, @payseq, PostSeq, @earncode, 0, (Amt / @totalearns) * @addonamt
				FROM bPRTH h
				LEFT OUTER JOIN bJCJM j ON h.JCCo = j.JCCo AND h.Job = j.Job
				JOIN bPREC e ON h.PRCo = e.PRCo AND h.EarnCode = e.EarnCode
				WHERE h.PRCo = @prco 
					AND h.PRGroup = @prgroup 
					AND h.PREndDate = @prenddate
					AND h.Employee = @employee 
					AND h.PaySeq = @payseq
					AND h.EarnCode IN (SELECT SubjEarnCode 
									   FROM bPRES s (NOLOCK) 
									   WHERE s.PRCo=@prco AND s.EarnCode=@earncode)
					AND h.Craft = @craft 
					AND h.Class = @class
					AND (( j.CraftTemplate = @template) 
						OR (h.Job IS NULL AND @template IS NULL)
						OR (j.CraftTemplate IS NULL AND @template IS NULL))
					AND e.SubjToAddOns = 'Y'
					AND h.Amt <> 0 --do not distribute to postings with 0 amount
				ORDER BY PostSeq

				--compare total posted against allowance to determine need to update the difference
				SELECT @totalposted = SUM(Amt), @lastpostseq = max(PostSeq) 
				FROM dbo.bPRTA (NOLOCK)
				WHERE PRCo=@prco 
					AND PRGroup=@prgroup 
					AND PREndDate=@prenddate 
					AND Employee=@employee 
					AND PaySeq=@payseq
					AND EarnCode=@earncode

				IF @totalallowance <> @totalposted
				BEGIN
					-- update difference to last entry 
					UPDATE bPRTA SET Amt = Amt + (@totalallowance - @totalposted)
					WHERE  PRCo = @prco 
						AND PRGroup = @prgroup 
						AND PREndDate = @prenddate
						AND Employee = @employee 
						AND PaySeq = @payseq 
						AND PostSeq = @lastpostseq 
						AND EarnCode = @earncode
				END
			END 
		END
			
		ELSE --when @addonYN = 'N'
		BEGIN
			SELECT @amt = @rate * @stddays
		END
	END

	ELSE --when @posttoall <> 'Y'
	BEGIN --hours by days worked
	
		IF @addonYN = 'Y'
		BEGIN --when @addonYN = 'Y' compute as addon earnings and post distributions in bPRTA
			/* get Craft Effective Date with possible override by Template */
			SELECT @effectdate = EffectiveDate FROM bPRCM WHERE PRCo = @prco AND Craft = @craft
			SELECT @effectdate = EffectiveDate FROM bPRCT WHERE PRCo = @prco AND Craft = @craft
																			 AND Template = @template 
																			 AND OverEffectDate = 'Y'
			/* get Craft, Class Addon Rates with possible override by Template - lookup 0.00 Factor */
			SELECT @oldrate = 0.00, @newrate = 0.00
			SELECT @oldrate = OldRate, @newrate = NewRate FROM bPRCI WHERE PRCo = @prco
																		   AND Craft = @craft 
																		   AND EDLType = 'E' 
																		   AND EDLCode = @earncode 
																		   AND Factor = 0.00
			SELECT @oldrate = OldRate, @newrate = NewRate FROM bPRCF WHERE PRCo = @prco
																		   AND Craft = @craft 
																		   AND Class = @class 
																		   AND EarnCode = @earncode 
																		   AND Factor = 0.00
			SELECT @oldrate = OldRate, @newrate = NewRate FROM bPRTI WHERE PRCo = @prco
																		   AND Craft = @craft 
																		   AND Template = @template 
																		   AND EDLType = 'E' 
																		   AND EDLCode = @earncode 
																		   AND Factor = 0.00
			SELECT @oldrate = OldRate, @newrate = NewRate FROM bPRTF WHERE PRCo = @prco
																		   AND Craft = @craft 
																		   AND Class = @class 
																		   AND Template = @template 
																		   AND EarnCode = @earncode 
																		   AND Factor = 0.00

			--create table variable for all posting dates
			DECLARE @PostDates table (PostDate bDate, TotalEarns bDollar, AllowAmt bDollar)

			INSERT @PostDates
			SELECT h.PostDate, SUM(h.Amt), (CASE WHEN h.PostDate < @effectdate THEN @oldrate ELSE @newrate END)
			FROM bPRTH h
			LEFT OUTER JOIN bJCJM j ON h.JCCo = j.JCCo AND h.Job = j.Job
			JOIN bPREC e ON h.PRCo = e.PRCo AND h.EarnCode = e.EarnCode
			WHERE h.PRCo = @prco 
				AND h.PRGroup = @prgroup 
				AND h.PREndDate = @prenddate
				AND h.Employee = @employee 
				AND h.PaySeq = @payseq
				AND h.EarnCode IN (SELECT SubjEarnCode 
								   FROM bPRES s (NOLOCK) 
								   WHERE s.PRCo=@prco AND s.EarnCode=@earncode)
				AND h.Craft = @craft 
				AND h.Class = @class
				AND (( j.CraftTemplate = @template) 
					OR (h.Job IS NULL AND @template IS NULL)
					OR (j.CraftTemplate IS NULL AND @template IS NULL))
				AND e.SubjToAddOns = 'Y'
			GROUP BY h.PostDate

			SELECT @postdate=MIN(PostDate) FROM @PostDates

			WHILE @postdate IS NOT NULL
			BEGIN
				SELECT @totalearns=TotalEarns, @addonamt=AllowAmt FROM @PostDates WHERE PostDate=@postdate

                -- skip if no positive daily earnings were found
				IF @totalearns > 0.00 AND @addonamt <> 0.00
				BEGIN
					-- initialize amount already distributed 
					SELECT @amtdist = 0.00, @lastpostseq = 0

					-- distribute addon amount for all postings for the day 
	                INSERT bPRTA (PRCo, PRGroup, PREndDate, Employee, PaySeq, PostSeq, EarnCode, Rate, Amt)
					SELECT @prco, @prgroup, @prenddate, @employee, @payseq, PostSeq, @earncode, 0, ROUND((Amt/@totalearns)*@addonamt,2)
					FROM bPRTH h
	        		LEFT OUTER JOIN bJCJM j ON h.JCCo = j.JCCo AND h.Job = j.Job
	        		JOIN bPREC e ON h.PRCo = e.PRCo AND h.EarnCode = e.EarnCode
	        		WHERE h.PRCo = @prco 
	        			AND h.PRGroup = @prgroup 
	        			AND h.PREndDate = @prenddate
		        		AND h.Employee = @employee 
		        		AND h.PaySeq = @payseq
		        		AND h.PostDate = @postdate 
		        		AND h.Craft = @craft 
		        		AND h.Class = @class
						AND h.EarnCode IN (SELECT SubjEarnCode 
										   FROM bPRES s (NOLOCK) 
										   WHERE s.PRCo=@prco AND s.EarnCode=@earncode)
		        		AND (( j.CraftTemplate = @template) 
		        			OR (h.Job IS NULL AND @template IS NULL)
		        			OR (j.CraftTemplate IS NULL AND @template IS NULL))
		        		AND e.SubjToAddOns = 'Y'
					ORDER BY PostSeq

					SELECT @postdate=MIN(PostDate) FROM @PostDates WHERE PostDate>@postdate
				END
			END
			
			--compare total posted against allowance to determine need to update the difference
			SELECT @totalposted = SUM(Amt), @lastpostseq = max(PostSeq) FROM dbo.bPRTA (NOLOCK)
			WHERE PRCo=@prco 
				AND PRGroup=@prgroup 
				AND PREndDate=@prenddate 
				AND Employee=@employee 
				AND PaySeq=@payseq
				AND EarnCode=@earncode

			IF @totalallowance <> @totalposted
			BEGIN
				-- update difference to last entry for the day 
				UPDATE bPRTA SET Amt = Amt + (@totalallowance - @totalposted)
				WHERE  PRCo = @prco 
					AND PRGroup = @prgroup 
					AND PREndDate = @prenddate
					AND Employee = @employee 
					AND PaySeq = @payseq 
					AND PostSeq = @lastpostseq 
					AND EarnCode = @earncode
			END
		END 

		ELSE --when @addonYN = 'N'
		BEGIN
			-- determine # of days
			SELECT @numdays = COUNT(DISTINCT(h.PostDate))
			FROM bPRTH h
	    	WHERE h.PRCo = @prco 
	    		AND h.PRGroup = @prgroup 
	    		AND h.PREndDate = @prenddate
			    AND h.Employee = @employee 
			    AND h.PaySeq = @payseq
				AND h.EarnCode IN (SELECT SubjEarnCode 
								   FROM bPRES s (NOLOCK) 
								   WHERE s.PRCo=@prco AND s.EarnCode=@earncode)

			SELECT @amt = @rate * @numdays
		END
	END 

	bspexit:
   		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPR_CA_AmtPerDay] TO [public]
GO
