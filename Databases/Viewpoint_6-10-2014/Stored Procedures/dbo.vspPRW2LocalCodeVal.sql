SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRW2LocalCodeVal]
/************************************************************************
* CREATED:	MH 2/26/2007    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Validate Local code and return TaxType and TaxID for defaults.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

	(@prco bCompany, @local bLocalCode, @taxid varchar(20) output, @taxtype char(1) output, @msg varchar(60) output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @prco is null
	begin
		select @msg = 'Missing PR Company.', @rcode = 1
		goto vspexit
	end

	if @local is null
	begin
		select @msg = 'Missing Local Code.', @rcode = 1
		goto vspexit
	end

	exec @rcode = bspPRLocalVal @prco, @local, @msg output

	if @rcode = 0 
	begin
		select @taxtype = TaxType, @taxid = TaxID from PRLI where PRCo = 1 and LocalCode = @local
	end

vspexit:

    return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRW2LocalCodeVal] TO [public]
GO
