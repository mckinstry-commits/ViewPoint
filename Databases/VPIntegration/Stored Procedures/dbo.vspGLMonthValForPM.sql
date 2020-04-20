SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspGLMonthValForPM  ******/
CREATE procedure [dbo].[vspGLMonthValForPM]
/******************************************************
* Created By:	GF 01/22/2012 TK-11973 month validation for PM Interface
* Modified By:
*
*
*
* Validates a month for PM Interface. runs bspGLMonthVal
* and also checks that the fiscal year is set up for the month.
* GL posting - must be after last mth closed in GL
* and before or equal to last
* mth closed in subledgers + max open mths
*
* pass in GL Co#, and Month
* returns 0 if successfull, 1 and error msg if error
*******************************************************/
(@GLCo bCompany, @Mth bMonth, @ErrMsg varchar(255) OUTPUT)
AS
SET NOCOUNT ON

declare @lastmthsubclsd bMonth, @lastmthglclsd bMonth,
		@maxopen tinyint, @beginmth bMonth, @endmth bMonth,
		@rcode int

SET @rcode = 0

---- execute dbo.bspGLMonthVal first
EXEC @rcode = dbo.bspGLMonthVal @GLCo, @Mth, @ErrMsg OUTPUT
IF @rcode <> 0 GOTO bspexit

---- make sure Fiscal Year has been setup for this month
IF NOT EXISTS(SELECT 1 FROM dbo.GLFY WHERE GLCo = @GLCo and BeginMth <= @Mth and FYEMO >= @Mth)
	BEGIN
	SELECT @ErrMsg = 'Must first add a Fiscal Year in General Ledger.', @rcode = 1
	goto bspexit
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspGLMonthValForPM] TO [public]
GO
