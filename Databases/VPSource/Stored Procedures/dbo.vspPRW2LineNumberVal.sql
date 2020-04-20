SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRW2LineNumberVal]
/************************************************************************
* CREATED:		CHS 12/07/2010
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Validate Line number. 
*           
* Notes about Stored Procedure
* 
* returns 0 IF successfull 
* returns 1 and error msg IF failed
*************************************************************************/
(@prco bCompany, @taxyear varchar(4), @state bState, @linenumber int, @msg varchar(255) output)

AS

SET NOCOUNT ON

    DECLARE @rcode int, @rowcount int

    SELECT @rcode = 0, @rowcount = 0

	IF @prco is null	
		BEGIN
		SELECT @msg = 'Missing PR Company.', @rcode = 1
		GOTO vspexit
		END

	IF @taxyear is null
		BEGIN
		SELECT @msg = 'Missing tax year.', @rcode = 1
		GOTO vspexit
		END

	IF @state is null
		BEGIN
		SELECT @msg = 'Missing state.', @rcode = 1
		GOTO vspexit
		END

	IF @linenumber is null
		BEGIN
		SELECT @msg = 'Missing line number.', @rcode = 1
		GOTO vspexit
		END

	IF NOT EXISTS(SELECT TOP 1 1 FROM PRW2MiscHeader WHERE PRCo = @prco AND TaxYear = @taxyear AND State = @state)
		BEGIN
		IF @linenumber <> 1
			BEGIN
			SELECT @msg = 'When entering a new state, the line numbering must begin with line number 1.', @rcode = 1
			GOTO vspexit				
			END	
		END
	
	SELECT LineNumber FROM PRW2MiscHeader WHERE PRCo = @prco AND TaxYear = @taxyear AND State = @state
	set @rowcount = @@rowcount
	
	IF @rowcount >= 12
		BEGIN
		SELECT @msg = 'You are only allowed a maximum of 12 Misc Box 14 lines for this state.', @rcode = 1
		GOTO vspexit
		END

vspexit:

    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRW2LineNumberVal] TO [public]
GO
