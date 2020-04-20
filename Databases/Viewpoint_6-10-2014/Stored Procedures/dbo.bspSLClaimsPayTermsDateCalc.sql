SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspSLClaimsPayTermsDateCalc]
/***********************************************************
* CREATED: AJW 6/20/13
* MODIFIED: 
*
* USAGE:
*	Returns bspHQPayTermsDateCalc unless inputs are null than just returns

* INPUTS:
*   @payterms		Payment Terms
*	@invoicedate	Invoice Date
*   
* OUTPUTS:
*   @discdate		Discount Date
*   @duedate		Due Date
*   @discrate		Discount Rate
*   @msg			Payment Terms description or error message if failure
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
	(@payterms bPayTerms = NULL, @invoicedate bDate = NULL, @discdate bDate OUTPUT,
	 @duedate bDate OUTPUT, @discrate bPct OUTPUT, @msg VARCHAR(60) OUTPUT)
AS 
DECLARE @errmsg int        
SET NOCOUNT ON

SELECT @discdate=NULL,@duedate=NULL,@discrate=NULL,@msg=NULL

IF @payterms IS NULL OR @invoicedate IS NULL
BEGIN
	RETURN
END

BEGIN TRY 
	EXEC bspHQPayTermsDateCalc @payterms, @invoicedate, @discdate OUTPUT,@duedate OUTPUT,@discrate OUTPUT,@msg OUTPUT
END TRY
BEGIN CATCH
		SET @msg = 'Error in bspSLClaimsPayTermsDateCalc:' + ERROR_MESSAGE();
		RAISERROR(@msg,16,1);
END CATCH
GO
GRANT EXECUTE ON  [dbo].[bspSLClaimsPayTermsDateCalc] TO [public]
GO
