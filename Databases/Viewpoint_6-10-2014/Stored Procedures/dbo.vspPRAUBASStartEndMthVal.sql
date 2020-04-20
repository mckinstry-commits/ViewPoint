SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE  PROCEDURE [dbo].[vspPRAUBASStartEndMthVal]
   /************************************************************
    * CREATED BY: 	 MV	06/15/11
    * MODIFIED By :
	*								
	*								
    *
    * USAGE:
    * Validate that the GST End Month is not before the Start Month
    * Called from PRAUBASProcess for GST 
    *
    * INPUT PARAMETERS
    *   @StartMonth  Start Month
    *   @EndMonth    End Month
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    ************************************************************/
   	@StartDate bMonth, @EndDate bMonth, @errmsg VARCHAR(255) OUTPUT
   AS
   SET NOCOUNT ON
   
   DECLARE @rcode INT
   
   SELECT @rcode = 0
   
   IF @StartDate IS NOT NULL AND @EndDate IS NOT NULL
   BEGIN
	   IF @EndDate < @StartDate
	   BEGIN
	   SELECT @errmsg = 'End Month is before Start Month.', @rcode = 1
   	GOTO bspexit
	   END
   END
   
   bspexit:
   	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAUBASStartEndMthVal] TO [public]
GO
