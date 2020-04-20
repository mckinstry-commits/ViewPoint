SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[vspARCustomerValForMSInvPrint]
/***********************************************************
* CREATED BY:	GF 09/10/2012 TK-17760
* MODIFIED By: 
*
* USAGE:
* validates Customer Sort Name for MS Invoice Print. The MS Invoice Print has an
* option to print by sort name not customer number, so need to output sort name.
*
* an error is returned if any of the following occurs
*     Customer not found
*
* INPUT PARAMETERS
* CustGroup		Customer Group
* Customer		Customer SortName or number
* Option		null = any customer
*				'A' = Active Only	(Will only error when Customer is InActive)
*				'H' = Not on Hold	(Will only error when Customer is On Hold)
*				'X' = Active and Not on hold	(Will error when Customer is InActive or On Hold)
*
* OUTPUT PARAMETERS
* CustomerOutput	customer number
* SortNameOutput	customer sort name
* @msg      error message if error occurs, otherwise Name of customer
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/
(@CustGroup tinyint = null, @Customer bSortName, @Option char(1)=null,  
 @CustomerOutput bCustomer output, @SortNameOutput bSortName OUTPUT,
 @msg varchar(255) output)
AS
SET NOCOUNT ON

DECLARE @rcode int, @Status CHAR(1), @SortNameChk bSortName
   
SET @rcode = 0
SET @CustomerOutput = NULL
SET @SortNameOutput = NULL

IF @CustGroup IS NULL
	BEGIN
	SELECT @msg = 'Missing Customer Group!', @rcode = 1
	GOTO vspexit
	END
	
IF @Customer IS NULL
	BEGIN
	SELECT @msg = 'Missing Customer!', @rcode = 1
	goto vspexit
	END
 
/* If @Customer input by user is numeric and is also the correct length allowed
	by bCustomer Mask (max 6), then check for existing record in ARCM.  No sense checking
	otherwise. */
	
IF ISNUMERIC(@Customer) <> 0	-- If IsNumeric is True
	AND LEN(@Customer) < 7		-- Maximum allowed by bCustomer Mask #####0
  	BEGIN
  	/* Validate Customer to make sure it is valid to post entries to */
  	SELECT @CustomerOutput = Customer,
  			@Status=Status,
  			@msg=Name,
  			@SortNameOutput = SortName
	FROM dbo.bARCM with (nolock)
	WHERE CustGroup = @CustGroup
		AND Customer = convert(int,convert(float, @Customer))
	END

/* If @CustomerOutput is null, then it was not looked for or found above.  We now
	will treat the Customer input as a SortName and look for it as such. */
IF @CustomerOutput IS NULL
	BEGIN	/* Begin SortName Check */
   	SET @SortNameChk = @Customer
   
   	SELECT @CustomerOutput = Customer,
   			@Status=Status,
   			@msg=Name,
   			@SortNameOutput = SortName
   	FROM dbo.bARCM with (nolock)
   	WHERE CustGroup = @CustGroup
   		AND SortName = @SortNameChk
   	IF @@ROWCOUNT = 0
		BEGIN
		/* Begin Approximate SortName Check */		
   		/* Approximate SortName Check.  Input is neither numeric or an exact SortName match. */
   		/* If not an exact SortName then bring back the first one that is close to a match.  */
   	   	SET @SortNameChk = @SortNameChk + '%'
   
   	   	SELECT TOP 1 @CustomerOutput = Customer,
   	   				 @Status=Status,
   	   				 @msg=Name,
   	   				 @SortNameOutput = SortName
   		FROM dbo.bARCM with (nolock)
   		WHERE CustGroup = @CustGroup
   			AND SortName LIKE @SortNameChk
   		ORDER BY Customer	
   	   	IF @@ROWCOUNT = 0   /* if there is not a match then display message */
   	   		BEGIN
   	     	SELECT @msg = 'Customer is not valid!', @rcode = 1
   			GOTO vspexit
   			END
   	 	END		/* End Approximate SortName Check */
	END		/* End SortName Check */
   
   
/* This is a valid Customer, Now do a Status Check */
IF @Option IN ('A','X') AND @Status='I'
	BEGIN
	SELECT @msg = 'Customer is not active!', @rcode = 1
	GOTO vspexit
  	END
  	
IF @Option IN ('H','X') AND @Status='H'
 	BEGIN	
	SELECT @msg = 'Customer is on hold!', @rcode = 1
	GOTO vspexit
	END



vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspARCustomerValForMSInvPrint] TO [public]
GO
