
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
*				KK 04/09/13 - 45623	 Modified to disregard Variable Rate calculations all together.
*									 Including Shift in the rate but took out EarnCode and therefore Factor throughout.
*
* USAGE: Used by PR Process when processing allowances to get the rate
*
* INPUT PARAMETERS
*	@prco		PR Company
*	@employee	PR Employee being evaluated
*	@postdate	PR Timecard Entry posting date 
*	@craft		PR Craft for this timecard line
*	@class		PR Class for this timecard line 
*	@template	PR Template that comes from the job on this timecard line
*	@shift		Shift on this timecard line
*
* OUTPUT PARAMETERS
*	Rate	  as bUnitCost = base allowance rate to use for this timecard line
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(
	@prco bCompany, 
	@employee bEmployee, 
	@postdate bDate, 
	@craft bCraft,
	@class bClass, 
	@template smallint, 
	@shift tinyint
)
RETURNS dbo.bUnitCost
AS
BEGIN
	DECLARE @rate bUnitCost,
			@effectivedate bDate,
			@classrate bUnitCost

	-- Get the employee's hourly pay rate from PR Employees and multiply it by the factor from the earn code
	SELECT @rate = HrlyRate FROM PREH WHERE PRCo = @prco AND Employee = @employee
	
	-- Get the effective date from Craft Master
	SELECT @effectivedate = EffectiveDate FROM PRCM WHERE PRCo = @prco AND Craft = @craft
	
	-- Initialize pay rate(@classrate) set at the Craft/Class or Craft/Class Temp level
	SELECT @classrate = 0.00

	-- CRAFT/CLASS TEMPLATE: If there is a template, we will check here for a pay rate overrides
	IF @template IS NOT NULL
  	BEGIN
		-- If there is an effective date override at Craft Template, use this, else use Craft Master effective date 
  		SELECT @effectivedate = CASE OverEffectDate WHEN 'Y' 
  													THEN ISNULL(EffectiveDate,@effectivedate) 
													ELSE @effectivedate END
  		FROM PRCT WHERE PRCo = @prco 
  					AND Craft = @craft 
  					AND Template = @template
  		
		-- C/C Temp Pay Rate: If the posting date is on or after the effective date use new rate, else use old rate
  		SELECT @classrate = CASE WHEN @postdate >= @effectivedate 
  								 THEN NewRate 
  								 ELSE OldRate END
  		FROM PRTP
		WHERE PRCo = @prco 
		  AND Craft = @craft 
		  AND Class = @class 
		  AND Template = @template 
		  AND Shift = @shift

		-- If we found a pay rate at the Craft/Class Temp, compare it to the PR Employee rate
		IF @classrate IS NOT NULL AND @classrate <> 0
		BEGIN
			-- Return the greater between the C/C Temp pay rate and the PR Employee rate
			IF @classrate > @rate SELECT @rate = @classrate
			RETURN @rate
		END

		-- No pay rates were found at the Craft/Class Template, reinitialize variable
		SELECT @classrate = 0.00
  	END

	-- CRAFT/CLASS: Rates will be based on Employee or Craft/Class tables

	-- C/C Pay Rate: If the posting date is on or after the effective date use new rate, else use old rate
	SELECT @classrate = CASE WHEN @postdate >= @effectivedate 
							 THEN NewRate 
							 ELSE OldRate END
	FROM PRCP 
	WHERE PRCo = @prco 
	  AND Craft = @craft 
	  AND Class = @class 
	  AND Shift = @shift
		
	-- If we found a pay rate at Craft/Class, compare it to the PR Employee rate
	IF @classrate IS NOT NULL AND @classrate <> 0
	BEGIN
		-- Return the greater between the factored C/C pay rate and the factored PR Employee rate
		IF @classrate > @rate SELECT @rate = @classrate
		RETURN @rate
	END

	-- No rate overrides were found that were greater than PR Employee rate, so return PR Employee rate
	RETURN @rate
END
GO

GRANT EXECUTE ON  [dbo].[vfPRRateDefault] TO [public]
GO
