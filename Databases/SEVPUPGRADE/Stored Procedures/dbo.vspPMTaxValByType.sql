SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMTaxValByType    Script Date: 8/28/99 9:32:49 AM ******/
CREATE  proc [dbo].[vspPMTaxValByType]
/***********************************************************
* CREATED BY:	GF 09/16/2008
* MODIFIED By : 
*
* USAGE:
* validates HQ Tax Code
* an error is returned if any of the following occurs
* no tax code passed, or tax code doesn't exist in HQTX
*
* INPUT PARAMETERS
* @taxgroup		TaxGroup assigned in bHQCO
* @taxtype		TaxCode to validate for VAT
* @taxcode		TaxCode to validate
*
* OUTPUT PARAMETERS
*   @msg      		Tax code description or error message 
*
* RETURN VALUE
*   @rcode			0 = success, 1 = error
*   
*****************************************************/ 
(@taxgroup bGroup = null, @taxtype tinyint = null, @taxcode bTaxCode = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @valueadd char(1)

select @rcode = 0

if @taxgroup is null
	begin
   	select @msg = 'Missing Tax Group', @rcode = 1
   	goto bspexit
   	end
if @taxcode is null
   	begin
   	select @msg = 'Missing Tax Code', @rcode = 1
   	goto bspexit
   	end
---- if tax type is null assume sales type
if isnull(@taxtype,0) = 0
	begin
	select @taxtype = 1
	end

---- validate tax code and get value added flag
select @msg = Description, @valueadd = ValueAdd
from HQTX with (nolock)
where TaxGroup = @taxgroup and TaxCode = @taxcode
if @@rowcount = 0
	begin
	select @msg = 'Tax code not setup in HQ!', @rcode = 1
	goto bspexit
	end

---- Tax Type 3 - VAT should only be used with ValueAdd tax codes
if (@valueadd = 'Y' and @taxtype <> 3) or (@valueadd = 'N' and @taxtype = 3)
	begin
	select @msg = 'Tax Code is invalid for Tax Type: ' + convert(char(1), @taxtype), @rcode = 1
	goto bspexit
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMTaxValByType] TO [public]
GO
