SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[vfPRRateDefault]
/***********************************************************
* Based on stored proc BY: (kb 3/1/99)
*			
* MODIFIED BY : KK 12/02/12 - TK-19690 Made this stored procedure bspPRRateDefault into a function for AU Allowances epic
*				KK 01/17/13 - TK-20786 Refactored when there was a concern with base rate calculations
*				KK 02/04/13 - 8166 Modified to take in Timecard earncode and Allowance earncode separately
*
* USAGE: Used by PR Process when processing Australian allowances to get the rate
*		 Called from PRProcessAllowances
*
* INPUT PARAMETERS
*	@prco				PR Company from timecard 
*	@employee			Employee from timecard via PR Process
*	@postdate			PR End Date on timecard line 
*	@craft				Craft on timecard line
*	@class				Class on timecard line
*	@template			Template on timecard line
*	@shift				Shift on timecard line
*	@earncode			Earncode on timecard line, used to find rate in the heirarchy
*	@allowanceearncode	Allowance earncode for factoring rates (NOTE: Allowance earncodes are all 1.0)
*
* RETURN VALUE
*   0	Success
*   1	Failure
*****************************************************/
(
	@prco bCompany, 
	@employee bEmployee, 
	@postdate bDate, 
	@craft bCraft,
	@class bClass, 
	@template smallint, 
	@shift tinyint, 
	@earncode bEDLCode, -- Used to find rate in the heirarchy
	@allowanceearncode bEDLCode -- Used as the factor in comparing rates
)
RETURNS dbo.bUnitCost

AS
BEGIN
 
	DECLARE @factor bRate,
			@rate bUnitCost,
			@effectivedate bDate,
			@vclassrate bUnitCost,
			@classrate bUnitCost, 
			@jobcraft bCraft

	-- Get factor (We are calling this from Allowance Processing in which all allowance earn code factors are 1.0)
	SELECT @factor = Factor	FROM PREC WHERE PRCo = @prco AND EarnCode = @allowanceearncode

	-- Get the employee's hourly pay rate from PR Employees and multiply it by the factor from the earn code (1.0)
	SELECT @rate = HrlyRate FROM PREH WHERE PRCo = @prco AND Employee = @employee
	SELECT @rate = @rate * @factor 

	-- Get the effective date from Craft Master
	SELECT @effectivedate = EffectiveDate FROM PRCM WHERE PRCo = @prco AND Craft = @craft
	
	-- Initialize variable rate(@vclassrate) and pay rate(@classrate) set at the Craft/Class or Craft/Class Temp level
	SELECT @vclassrate = 0, @classrate = 0

	-- CRAFT/CLASS TEMPLATE: If there is a template, we will check here for a pay rate override
	IF @template IS NOT NULL
  	BEGIN
		-- If there is an effective date override at Craft Template, use this, else use Craft Master effective date 
  		SELECT @effectivedate = CASE OverEffectDate WHEN 'Y' 
  													THEN ISNULL(EffectiveDate,@effectivedate) 
													ELSE @effectivedate END
  		FROM PRCT WHERE PRCo = @prco 
  					AND Craft = @craft 
  					AND Template = @template

		-- C/C Temp Variable Rate: If the posting date is on or after the effective date use new rate, else use old rate
		SELECT @vclassrate = CASE WHEN @postdate >= @effectivedate 
								  THEN NewRate 
								  ELSE OldRate END
		FROM PRTE WHERE PRCo = @prco 
					AND Craft = @craft 
					AND Class = @class 
					AND Template = @template 
					AND Shift = @shift 
					AND EarnCode = @earncode
		  		
		-- If we found a variable rate at the Craft/Class Template, compare it to the factored PR Employee rate
		IF @vclassrate IS NOT NULL AND @vclassrate <> 0
		BEGIN

			-- Compare to the variable rate to the factored PR Employee rate, and return the greater
			IF @vclassrate > @rate SELECT @rate = @vclassrate
			RETURN @rate
		END

		-- No variable pay was found at the Craft/Class Template (or we would have returned a value)
		
		-- C/C Temp Pay Rate: If the posting date is on or after the effective date use new rate, else use old rate
  		SELECT @classrate = CASE WHEN @postdate >= @effectivedate 
  								 THEN NewRate 
  								 ELSE OldRate END
  		FROM PRTP WHERE PRCo = @prco 
					AND Craft = @craft 
					AND Class = @class 
					AND Template = @template 
					AND Shift = @shift

		-- If we found a pay rate at the Craft/Class Temp, compare it to the PR Employee rate
		IF @classrate IS NOT NULL AND @classrate <> 0
		BEGIN
			-- Return the greater between the factored C/C Temp pay rate and the factored PR Employee rate
			SELECT @classrate = @classrate * @factor
			IF @classrate > @rate SELECT @rate = @classrate
			RETURN @rate
		END

		-- No pay rates were found at the Craft/Class Template, reinitialize variables
		SELECT @vclassrate = 0, @classrate = 0
  	END

	-- CRAFT/CLASS: Rates will be based on Employee or Craft/Class tables
	-- C/C Variable Rate: If the posting date is on or after the effective date use new rate, else use old rate
	SELECT @vclassrate = CASE WHEN @postdate >= @effectivedate 
							  THEN NewRate 
							  ELSE OldRate END
	FROM PRCE WHERE PRCo = @prco 
				AND Craft = @craft 
				AND Class = @class 
				AND Shift = @shift 
				AND EarnCode = @earncode
		
	-- If we found a variable rate at Craft/Class, compare it to the factored PR Employee rate
	IF @vclassrate IS NOT NULL AND @vclassrate <> 0
	BEGIN
		-- Compare to the variable rate to the factored PR Employee rate, and return the greater
		IF @vclassrate > @rate SELECT @rate = @vclassrate
		RETURN @rate
	END
	
	-- C/C Pay Rate: If the posting date is on or after the effective date use new rate, else use old rate
	SELECT @classrate = CASE WHEN @postdate >= @effectivedate 
							 THEN NewRate 
							 ELSE OldRate END
	FROM PRCP WHERE PRCo = @prco 
				AND Craft = @craft 
				AND Class = @class 
				AND Shift = @shift
		
	-- If we found a pay rate at Craft/Class, compare it to the PR Employee rate
	IF @classrate IS NOT NULL AND @classrate <> 0
	BEGIN
		-- Return the greater between the factored C/C pay rate and the factored PR Employee rate
		SELECT @classrate = @classrate * @factor
		IF @classrate > @rate SELECT @rate = @classrate
		RETURN @rate
	END

	-- No rate overrides were found that were greater than PR Employee rate
	-- Return the factored PR Employee rate
	RETURN @rate
END
GO
GRANT EXECUTE ON  [dbo].[vfPRRateDefault] TO [public]
GO
