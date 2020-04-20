SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPRPurgeAccums    Script Date: 8/28/99 9:35:38 AM ******/
   CREATE     procedure [dbo].[vspPRPurgeAccumsMthVal]
   /***********************************************************
    * CREATED BY: MV	02/22/11	- #143362
    * MODIFIED By :
    *
    * USAGE:
    * Validates the through month against the begin month of the current payroll year.
    * 
    *
    * INPUT PARAMETERS
    *   @PRCo		PR Company
    *   @Month		Month to purge through
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   
   	(@PRCo bCompany, @Month bMonth, @ErrMsg VARCHAR(100) OUTPUT)
   	
   AS
   SET NOCOUNT ON
   
	DECLARE @rcode INT, @YearEndMth tinyint, @AccumBeginMth bMonth, @AccumEndMth bMonth,
	@CurrMth bDate,@DefaultCountry varchar(3)
	
	SELECT @rcode = 0

	SELECT @DefaultCountry = DefaultCountry
	FROM dbo.bHQCO
	WHERE HQCo= @PRCo

	SELECT @YearEndMth = CASE @DefaultCountry WHEN 'AU' THEN 6 ELSE 12 END
	SELECT @CurrMth = dbo.vfDateOnlyMonth ()

	EXEC vspPRGetMthsForAnnualCalcs @YearEndMth, @CurrMth, @AccumBeginMth output, @AccumEndMth output, @ErrMsg output
	-- Validate purge range against current payroll year
	IF (
			@Month >= @AccumBeginMth
		)
	BEGIN
		SELECT @ErrMsg = 'Through Month is greater or equal to current payroll year.', @rcode = 1
		GOTO bspexit	
	END
   
   bspexit:
   
   	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRPurgeAccumsMthVal] TO [public]
GO
