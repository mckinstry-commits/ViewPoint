SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspPRAutoOTRateDefault]
   /***********************************************************
   * CREATED: EN 9/12/00
   * MODIFIED: EN 10/7/02 - issue 18877 change double quotes to single
   *			GG 01/21/03 - #18703 - weighted average overtime rates
   *			GG 01/21/03 - #20001 - fix rate hierarchy
   *			EN/KK 05/10/11  TK-04978 / #143502 add extra step to compare final rate to employee's rate and use higher of the two
   *			EN 7/11/2012  B-09337/#144937 implement additional rate options added to PRCO (AutoOTUseVariableRatesYN and AutoOTUseHighestRateYN)
   *
   * USAGE: Called from bspPRAutoOTPost and bspPRAutoOTPostLevels to get overtime
   *	earnings rate based on Craft, Class, Template, Shift, and Earnings Code.
   *
   * INPUT PARAMETERS
   *	@prco  		PR Company
   *  	@employee   Employee #
   *  	@postdate   Date posted 
   *  	@craft      Craft
   *  	@class      Class
   *  	@jcco       JC Company
   *  	@job        Job
   *  	@shift      Shift
   *  	@otearncode Overtime Earnings Code
   *	@otfactor	Factor for overtime earnings
   *	@postedrate	Earnings rate posted with timecard
   *	@autootusevariableratesyn	PRCO flag; if 'Y' look up/use variable earnings rate based on craft/class/template
   *	@autootusehighestrateyn		PRCO flag; if 'Y' when posting overtime use highest of employee rate, posted rate and if @autootusevariableratesyn='Y', variable rate
   *
   * OUTPUT PARAMETERS
   *  	@otrate  	Overtime earnings rate
   *  	@Message    error message (if any)
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
(@prco bCompany = NULL, 
 @employee bEmployee = NULL,  
 @postdate bDate = NULL,  
 @craft bCraft = NULL,
 @class bClass = NULL,  
 @jcco bCompany = NULL,  
 @job bJob = NULL,  
 @shift tinyint = NULL,
 @otearncode bEDLCode = NULL,  
 @otfactor bRate = NULL,  
 @postedrate bUnitCost = NULL,
 @autootusevariableratesyn bYN = NULL,
 @autootusehighestrateyn bYN = NULL,
 @otrate bUnitCost OUTPUT,  
 @Message varchar(100) OUTPUT)
 
AS

SET NOCOUNT ON

DECLARE @effectivedate bDate, 
		@template smallint,
		@CheckPRCE bYN

BEGIN TRY
	-- determine factored posted rate
	DECLARE @FactoredPostRate bUnitCost
	SELECT @FactoredPostRate = @postedrate * @otfactor

	IF @autootusevariableratesyn = 'Y'
	BEGIN
		-- determine variable rate
		DECLARE @VariableRate bUnitCost
		
		-- get Effective Date from Craft Master
		IF @craft IS NOT NULL AND @class IS NOT NULL
		BEGIN
			SELECT @effectivedate = EffectiveDate 
			FROM dbo.bPRCM (NOLOCK) 
			WHERE PRCo = @prco AND Craft = @craft
		END

		-- get up Job Craft Template - may be null
		IF @jcco IS NOT NULL AND @job IS NOT NULL
		BEGIN
			SELECT @template = CraftTemplate 
			FROM dbo.bJCJM (NOLOCK) 
			WHERE JCCo = @jcco AND Job = @job
		END
	   
		IF @template IS NOT NULL
		BEGIN
			-- check for Effective Date override 
			IF (SELECT CASE OverEffectDate WHEN 'Y' THEN EffectiveDate ELSE NULL END
				FROM dbo.bPRCT (NOLOCK)
				WHERE PRCo = @prco AND Craft = @craft AND Template = @template) IS NOT NULL
			BEGIN
				SELECT @effectivedate = EffectiveDate
				FROM dbo.bPRCT (NOLOCK)
				WHERE PRCo = @prco AND Craft = @craft AND Template = @template
			END

			-- check Template Variable Earnings - Rates at Craft/Class/Template/Shift/EC level
			SELECT @CheckPRCE = 'N'

			SELECT @VariableRate = CASE WHEN @postdate >= @effectivedate THEN NewRate ELSE OldRate END
			FROM dbo.bPRTE (NOLOCK)
			WHERE	PRCo = @prco 
					AND Craft = @craft  
					AND Class = @class  
					AND Template = @template
					AND Shift = @shift  
					AND EarnCode = @otearncode
			IF @@ROWCOUNT = 0 SELECT @CheckPRCE = 'Y'

		END

		IF @template IS NULL OR (@template IS NOT NULL AND @CheckPRCE = 'Y')	

		BEGIN
			-- No Template or assigned rate, get rates from standard Craft and Class setup

			-- check Variable Earnings - Rates at Craft/Class/Shift/EC level -- use this overtime earnings code specific rate
			IF @craft IS NOT NULL AND @class IS NOT NULL
			BEGIN
				SELECT @VariableRate = CASE WHEN @postdate >= @effectivedate THEN NewRate ELSE OldRate END
				FROM dbo.bPRCE (NOLOCK)
				WHERE	PRCo = @prco 
						AND Craft = @craft  
						AND Class = @class  
						AND Shift = @shift  
						AND EarnCode = @otearncode
			END
		END
	END

	IF @autootusehighestrateyn = 'Y'
	BEGIN
		-- determine factored employee rate
		DECLARE @FactoredEmplRate bUnitCost

		SELECT @FactoredEmplRate = HrlyRate * @otfactor
		FROM dbo.PREH 
		WHERE PRCo = @prco AND Employee = @employee
	END
	
	-- determine overtime rate based on the PRCO rate options
	IF @autootusevariableratesyn = 'N' AND @autootusehighestrateyn = 'N'
	BEGIN
		-- use posted rate
		SELECT @otrate = @FactoredPostRate
	END
	ELSE IF @autootusevariableratesyn = 'Y' AND @autootusehighestrateyn = 'N'
	BEGIN
		-- use variable rate with posted rate as a backup
		SELECT @otrate = ISNULL(@VariableRate,@FactoredPostRate)
	END
	ELSE IF @autootusevariableratesyn = 'N' AND @autootusehighestrateyn = 'Y'
	BEGIN
		-- use employee rate or posted rate ... whichever is higher
		SELECT @otrate = (CASE WHEN @FactoredEmplRate > @FactoredPostRate THEN @FactoredEmplRate ELSE @FactoredPostRate END)
	END
	ELSE IF @autootusevariableratesyn = 'Y' AND @autootusehighestrateyn = 'Y'
	BEGIN
		-- use employee rate, posted rate, or variable rate ... whichever is higher
		SELECT @otrate = (CASE WHEN @FactoredEmplRate > @FactoredPostRate THEN @FactoredEmplRate ELSE @FactoredPostRate END)
		SELECT @otrate = (CASE WHEN @VariableRate > @otrate THEN @VariableRate ELSE @otrate END)
	END
	
END TRY
BEGIN CATCH
	-- Return error message if error is caught
	SET @Message = ERROR_MESSAGE()
	RAISERROR (@Message, 15, 1)
END CATCH
GO
GRANT EXECUTE ON  [dbo].[bspPRAutoOTRateDefault] TO [public]
GO
