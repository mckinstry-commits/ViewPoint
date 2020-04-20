SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRAutoOTWeekly    Script Date: 8/28/99 9:36:31 AM ******/
CREATE      PROC [dbo].[bspPRAutoOTWeekly]
/************************************************************************************
* CREATED BY: kb 3/18/98
* MODIFIED By : GG 4/30/99
* MODIFIED By: kb 4/4/00 issue #6709
*				EN 8/26/02 issue 18197 do not post weekly ot to holiday days
*				GG 02/04/03 - #18703 - Weighted average overtime
*				EN 9/13/05 issue 29635  receive @PRTBAddedYN value from bspPRAutoOTPost and return it back to bspPRAutoOT
*				EN 9/15/06 issue 122491  ignore 0 hour timecards
*				EN 9/26/07 issue 119734  holiday week overtime feature
*				EN 11/17/2011 TK-09034 / #138180 modify max reg hours default to use the new week1 and week2
*												 values in bPRPC rather than hardcoded 40
*				CHS	07/06/2012 TK-16170 / 145445 fixed arithmetic overflow.
*				EN 7/11/2012  B-09337/#144937 accept PRCO additional rate options (AutoOTUseVariableRatesYN and AutoOTUseHighestRateYN))
*											  as input params and pass as params to bspPRAutoOTPost
*
* USAGE:
* Called by bspPRAutoOT to calculate weekly overtime for an Employee/Pay Sequence
*
* INPUT PARAMETERS
*   @co       	    PR Company
*   @mth			Batch month - used when adding entries to bPRTB
*   @batchid		Batch ID
*   @prgroup		PR Group
*   @prenddate		Pay Period Ending Date
*   @employee		Employee
*   @payseq			Payment Sequence
*   @payfreq		Payment frequency for PR Group
*   @otearncode		Overtime earnings code
*   @begindate		Pay Period beginning date
*	@otrateadj		Weighted average overtime rate adjustment
*   @autootusevariableratesyn	PRCO flag; if 'Y' look up/use variable earnings rate based on craft/class/template
*   @autootusehighestrateyn		PRCO flag; if 'Y' when posting overtime use highest of employee rate, posted rate and if @autootusevariableratesyn='Y', variable rate
*
* OUTPUT PARAMETERS
*   @msg           error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
************************************************************************************/
(@co bCompany = NULL, 
 @mth bMonth = NULL, 
 @batchid bBatchID = NULL, 
 @prgroup bGroup = NULL,
 @prenddate bDate = NULL, 
 @employee bEmployee = NULL, 
 @payseq tinyint = NULL,
 @payfreq bFreq = NULL, 
 @otearncode bEDLCode = NULL, 
 @begindate bDate = NULL,
 @otrateadj bUnitCost = 0, 
 @autootusevariableratesyn bYN = NULL,
 @autootusehighestrateyn bYN = NULL,
 @PRTBAddedYN bYN OUTPUT, 
 @msg varchar(255) OUTPUT) --#29635
 
AS
SET NOCOUNT ON

DECLARE @rcode int, 
		@otfactor bRate, 
		@week tinyint, 
		@startweek bDate, 
		@endweek bDate, 
		@tothrs bHrs,
		@othrs bHrs, 
		@otremain bHrs, 
		@openTimecard tinyint, 
		@postseq smallint, 
		@postdate bDate, 
		@postedhrs bHrs,
		@postedrate bUnitCost, 
		@source char(1), 
		@PRPCMaxRegHrsWeek1 bHrs, 
		@PRPCMaxRegHrsWeek2 bHrs, 
		@CraftMaxRegHrsInWeek bHrs, 
		@MaxRegHrsThisWeek bHrs, 
		@minpostseq smallint, 
		@firstcraftposted bCraft, --#119734
		@sortaggregate bigint

DECLARE @HoursDetail table ( PostSeq tinyint,
							 PostDate bDate,
							 Hours bHrs,
							 Rate bUnitCost,
							 TableCode char(1),
							 SortAggregate bigint
							)
  
SELECT @rcode = 0

-- get overtime earnings factor
SELECT @otfactor = Factor
FROM dbo.bPREC
WHERE PRCo = @co 
	  AND EarnCode = @otearncode

-- #119734 get total hours for pay period
SELECT @PRPCMaxRegHrsWeek1 = MaxRegHrsInWeek1, 
	   @PRPCMaxRegHrsWeek2 = MaxRegHrsInWeek2 
FROM dbo.bPRPC
WHERE PRCo = @co 
	  AND PRGroup = @prgroup 
	  AND PREndDate = @prenddate

-- initialize starting and ending dates to 1st week of pay period
SELECT @week = 1, 
	   @startweek = @begindate,
	   @endweek = DATEADD(DAY,6,@startweek)
	   
WHILE @endweek <= @prenddate
BEGIN
	--Get the maximum regular hours per week to use as a basis to determine if overtime was worked

	--	check for possible max reg hours override setup for the employee's craft
	--	determine the employee's first craft posted
	SELECT @minpostseq = MIN(PostSeq) 
	FROM dbo.bPRTH (NOLOCK)
	WHERE PRCo = @co 
		  AND PRGroup = @prgroup 
		  AND PREndDate = @prenddate 
		  AND Employee = @employee 
		  AND Craft IS NOT NULL

	SELECT @firstcraftposted = Craft 
	FROM dbo.bPRTH (NOLOCK)
	WHERE PRCo = @co 
		  AND PRGroup = @prgroup 
		  AND PREndDate = @prenddate 
		  AND Employee = @employee 
		  AND PostSeq = @minpostseq

	--	for craft employees check for MaxRegHrsPerWeek set up by Craft where there is a holiday set up 
	--	within the week for the craft
	SELECT @CraftMaxRegHrsInWeek = NULL

	IF @firstcraftposted IS NOT NULL
	BEGIN
		SELECT @CraftMaxRegHrsInWeek = MaxRegHrsPerWeek 
		FROM dbo.bPRCM (NOLOCK)
		WHERE PRCo = @co 
			  AND Craft = @firstcraftposted 
			  AND HolidayOT = 'Y' 
			  AND EXISTS ( SELECT * 
						  FROM dbo.bPRCH (NOLOCK) 
						  WHERE PRCo = @co 
								AND Craft = @firstcraftposted 
								AND	Holiday >= @startweek 
								AND Holiday <= @endweek ) 
	END

	--specify maximum regular hours in week to the craft override if available 
	-- with the value in pay period control as a default 
	IF @week = 1
	BEGIN
		SELECT @MaxRegHrsThisWeek = ISNULL(@CraftMaxRegHrsInWeek,@PRPCMaxRegHrsWeek1)
	END
	ELSE
	BEGIN
		SELECT @MaxRegHrsThisWeek = ISNULL(@CraftMaxRegHrsInWeek,@PRPCMaxRegHrsWeek2)
	END

	-- initialize temp table containing hours detail posted for the week to PRTH and PRTB
	DELETE @HoursDetail
	
	INSERT @HoursDetail
	SELECT PostSeq, 
		   PostDate, 
		   Hours, 
		   Rate, 
		   'H',  -- denotes bPRTH
		   (DATEPART(YEAR,PostDate)*1000000)+(DATEPART(DAYOFYEAR,PostDate)*1000)+PostSeq
	FROM dbo.bPRTH h (NOLOCK)
	JOIN dbo.bPREC e ON h.PRCo = e.PRCo 
						AND h.EarnCode = e.EarnCode
	WHERE h.PRCo = @co 
		  AND h.PRGroup = @prgroup 
		  AND h.PREndDate = @prenddate 
		  AND h.InUseBatchId IS NULL 
		  AND h.Employee = @employee
		  AND h.PaySeq = @payseq 
		  AND h.PostDate >= @startweek 
		  AND h.PostDate <= @endweek
		  AND e.OTCalcs = 'Y'
		  AND h.PostDate NOT IN ( SELECT Holiday 
								  FROM dbo.bPRHD f 
								  WHERE f.PRCo = h.PRCo 
										AND f.PRGroup = h.PRGroup
										AND f.PREndDate = h.PREndDate --issue 18197 do not post ot to holiday days
										AND (h.Craft IS NULL OR (h.Craft IS NOT NULL AND f.ApplyToCraft = 'Y'))
								 ) --issue 19763 check if holiday applies to Crafts
		  AND h.PostDate NOT IN ( SELECT Holiday 
								  FROM dbo.bPRCH g 
								  WHERE g.PRCo=h.PRCo 
										AND g.Craft=h.Craft
								 ) --issue 18197 do not post ot to craft holiday days either
		  AND h.Hours > 0 --issue 122342 ignore PRTH 0 hour entries
	UNION
	SELECT PostSeq, 
		   PostDate, 
		   Hours, 
		   Rate, 
		   'B',  -- denotes bPRTB
		   (DATEPART(YEAR,PostDate)*1000000)+(DATEPART(DAYOFYEAR,PostDate)*1000)+PostSeq
	FROM dbo.bPRTB b (NOLOCK)
	JOIN dbo.bPREC e ON b.Co = e.PRCo 
						AND b.EarnCode = e.EarnCode
	JOIN dbo.bHQBC c ON b.Co = c.Co 
						AND b.Mth = c.Mth 
						AND b.BatchId = c.BatchId --issue 18197 need PRGroup and PREndDate for holiday check
	WHERE b.Co = @co 
		  AND b.Mth = @mth 
		  AND b.BatchId = @batchid 
		  AND b.BatchTransType = 'C'
		  AND b.Employee = @employee 
		  AND b.PaySeq = @payseq
		  AND b.PostDate >= @startweek 
		  AND b.PostDate <= @endweek
		  AND e.OTCalcs = 'Y'
		  AND b.PostDate NOT IN ( SELECT Holiday 
								  FROM dbo.bPRHD f 
								  WHERE f.PRCo=b.Co 
										AND f.PRGroup=c.PRGroup
										AND f.PREndDate=c.PREndDate --issue 18197 do not post ot to holiday days
										AND (b.Craft IS NULL OR (b.Craft IS NOT NULL AND f.ApplyToCraft = 'Y')) 
								 ) --issue 19763 check if holiday applies to Crafts
		  AND b.PostDate NOT IN ( SELECT Holiday 
								  FROM dbo.bPRCH g 
								  WHERE g.PRCo=b.Co 
										AND g.Craft=b.Craft
								 ) --issue 18197 do not post ot to craft holiday days either
		  AND b.Hours > 0 --issue 122342 ignore PRTB 0 hour entries
	
	-- get weeks total hours from TimeCard Header and TimeCard batch
	SELECT @tothrs = SUM(Hours) FROM @HoursDetail
	
	-- check for overtime
	IF @tothrs > @MaxRegHrsThisWeek
	BEGIN
		-- total and remaining overtime hours to distribute
		SELECT @othrs = @tothrs - @MaxRegHrsThisWeek --#119734
		SELECT @otremain = @othrs

		--get first posting detail to process
		SELECT @sortaggregate = MAX(SortAggregate) 
		FROM @HoursDetail

		WHILE @sortaggregate IS NOT NULL 
			  AND @otremain > 0
		BEGIN
			SELECT @postseq = PostSeq,
				   @postdate = PostDate, 
				   @postedhrs = [Hours], 
				   @postedrate = Rate, 
				   @source = TableCode
			FROM @HoursDetail 
			WHERE SortAggregate = @sortaggregate
								 
			IF @source = 'B' AND @otremain >= @postedhrs -- otremain should always be >= @postedhrs but checking just in case
			BEGIN
				-- change existing batch entry from regular to overtime
				UPDATE dbo.bPRTB
				SET EarnCode = @otearncode, 
					Rate = @postedrate * @otfactor, 
					Amt = @postedhrs * (@postedrate * @otfactor)
				WHERE Co = @co 
					  AND Mth = @mth 
					  AND BatchId = @batchid 
					  AND Employee = @employee
					  AND PaySeq = @payseq 
					  AND PostSeq = @postseq
				IF @@rowcount <> 1
				BEGIN
					SELECT @msg = 'Unable to find existing entry in Timecard batch.'
					RETURN 1
				END

				-- adjust remaining overtime
				SELECT @otremain = @otremain - @postedhrs
			END
			ELSE
			BEGIN
				-- source is Timecard Header - add overtime to timecard batch
				EXEC @rcode = bspPRAutoOTPost @co, 
											  @mth, 
											  @batchid, 
											  @prgroup, 
											  @prenddate, 
											  @employee,
											  @payseq, 
											  @begindate, 
											  @postseq, 
											  @postdate, 
											  @postedhrs, 
											  @postedrate, 
											  @otearncode,
											  @otfactor, 
											  @otremain, 
											  @otrateadj, 
											  @autootusevariableratesyn,
											  @autootusehighestrateyn,
											  @PRTBAddedYN OUTPUT, 
											  @msg OUTPUT --#29635
				IF @rcode <> 0 
				BEGIN
					RETURN @rcode
				END

				-- adjust the amount remaining to post overtime
				IF @otremain < @postedhrs 
				BEGIN
					SELECT @otremain = 0
				END
				ELSE
				BEGIN
					SELECT @otremain = @otremain - @postedhrs
				END
			END
			
			--get next posting detail
			SELECT @sortaggregate = MAX(SortAggregate)
			FROM @HoursDetail 
			WHERE SortAggregate < @sortaggregate
		END
		
	END

	--increment week # and set starting and ending dates for next week 
	--overtime calculations will be done for second week if pay period is bi-weekly
	SELECT @week = @week + 1
	SELECT @startweek = DATEADD(DAY,7,@startweek), 
		   @endweek = DATEADD(DAY,7,@endweek)
END

--IF @otremain<>0, HOUSTON, THERE'S A PROBLEM
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[bspPRAutoOTWeekly] TO [public]
GO
