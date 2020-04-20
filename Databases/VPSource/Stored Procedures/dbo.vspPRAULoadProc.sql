SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[vspPRAULoadProc]
	/******************************************************
	* CREATED BY:	MV	03/09/11 #138181
	* MODIFIED By: 
	*
	* Usage:	Returns taxgroup from HQCO for form PRAUBASProcessGSTTaxCodes
	*	
	*
	* Input params:
	*	
	*	@co - Company
	*
	* Output params:
	*
	*	@taxgroup - tax group from HQCO
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@co bCompany, @TaxGroup bGroup output, @CMCo bCompany output, @msg varchar(100) output)
	as 
	set nocount on
	declare @rcode int
   	
	select @rcode = 0
	
	SELECT @TaxGroup = TaxGroup
	FROM dbo.HQCO
	WHERE HQCo = @co
	IF @@ROWCOUNT = 0
	BEGIN
	SELECT @msg = 'Invalid PRCo.', @rcode=1
	goto vspexit
	END
	
	SELECT @CMCo=CMCo 
	FROM dbo.PRCO
	WHERE PRCo=@co
 
	vspexit:

	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPRAULoadProc] TO [public]
GO
