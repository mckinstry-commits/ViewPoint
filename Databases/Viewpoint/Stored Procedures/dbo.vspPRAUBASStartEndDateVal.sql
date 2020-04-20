SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


   CREATE  procedure [dbo].[vspPRAUBASStartEndDateVal]
   /************************************************************
    * CREATED BY: 	 MV	03/14/11
    * MODIFIED By :
	*								
	*								
    *
    * USAGE:
    * Validate that the End Date is not before the Start Date
    * Called from PRAUBASProcess
    *
    * INPUT PARAMETERS
    *   @StartDate  Start Date
    *   @EndDate    End Date
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    ************************************************************/
   	@StartDate bDate, @EndDate bDate, @errmsg VARCHAR(255) OUTPUT
   AS
   SET NOCOUNT ON
   
   DECLARE @rcode INT
   
   SELECT @rcode = 0
   
   IF @StartDate IS NOT NULL AND @EndDate IS NOT NULL
   BEGIN
	   IF @EndDate < @StartDate
	   BEGIN
	   SELECT @errmsg = 'End Date is before Start Date.', @rcode = 1
   	GOTO bspexit
	   END
   END
   
   bspexit:
   	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAUBASStartEndDateVal] TO [public]
GO
