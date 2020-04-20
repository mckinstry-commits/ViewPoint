SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vspARCustomerValWithNotes]
/***********************************************************
* CREATED BY: TJL 06/21/06 - Issue #28040, 6x Rewrite ARCreditNotes
* MODIFIED By : AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*			
*
* USAGE:
* 	Validates Customer
*	Returns Phone, Contact, and Notes for Customer
*
* INPUT PARAMETERS
*   CustGroup	Customer Group
*   Customer	Customer to validate
*
* OUTPUT PARAMETERS
*   @phone		ARCM.Phone
*   @contact	ARCM.Contact
*   @custoutput	An output of bspARCustomerVal
*	@notes		Customer Notes
*   @msg		error message if error occurs, or ARCM.Name
*
* RETURN VALUE
*   0	Success
*   1	Failure
*****************************************************/
    (
      @custgroup bGroup = NULL,
      @customer bSortName = NULL,
      @custoutput bCustomer = NULL OUTPUT,
      @phone bPhone = NULL OUTPUT,
      @contact VARCHAR(30) = NULL OUTPUT,
      @notes VARCHAR(MAX) OUTPUT,
      @msg VARCHAR(255) = NULL OUTPUT
    )
AS 
    SET nocount ON

    DECLARE @rcode INT,
        @option CHAR(1)

    SELECT  @rcode = 0,
            @option = NULL
   
    IF @custgroup IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Customer Group!',
                    @rcode = 1
            GOTO vspexit
        END
    IF @customer IS NULL 
        BEGIN
            SELECT  @msg = 'Missing Customer!',
                    @rcode = 1
            GOTO vspexit
        END
   
    EXEC @rcode = bspARCustomerVal @custgroup, @customer, @option,
        @custoutput OUTPUT, @msg OUTPUT
    IF @rcode = 1 
        GOTO vspexit
   
/* Need to get other customer info */
    SELECT  @phone = a.Phone,
            @contact = a.Contact,
            @notes = Notes,
            @msg = a.Name
    FROM    ARCM a WITH ( NOLOCK )
    WHERE   CustGroup = @custgroup
            AND Customer = @custoutput
   
    vspexit:
    IF @rcode <> 0 
        SELECT  @msg = @msg	--+ char(13) + char(10) + '[vspARCustomerValWithNotes]'
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARCustomerValWithNotes] TO [public]
GO
