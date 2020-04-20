SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************/
CREATE proc [dbo].[vspMSHQTaxRateGet]
/********************************************************
* CREATED BY:	GF 06/23/2008 - issue #128290 international tax
* MODIFIED BY:	MV 02/04/10 - #136500 bspHQTaxRateGetAll added NULL output param
*				MV 10/25/11 - TK=-0243 bspHQTaxRateGetAll added NULL output param
*
*
*
* USAGE: Used in MS Ticket Entry, MS Haul Addons, MS Hauler Timesheets
* Validates the tax code, and if the tax type is 3=VAT,
* then validates that the tax code in HQTX. then calls bspHQTaxRateGet
* to get the tax rate
*
*
* INPUT PARAMETERS:
* TaxGroup  Tax Group from MS
* TaxType	Tax Type from MS
* TaxCode	HQ Tax Code
* CompDate - for comparision to Effective Date
*
* OUTPUT PARAMETERS:
* TaxRate
* TaxPhase
* TaxJCCType
* Error message
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@taxgroup bGroup = null, @taxtype tinyint = null, @taxcode bTaxCode = null,
 @compdate bDate = null, @taxrate bRate = 0 output, @msg varchar(255)=null output)
as
set nocount on

declare @rcode int, @retcode int, @errmsg varchar(255), @valueadd char(1)

select @rcode = 0, @retcode = 0
   
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

---- if Compdate is null then use a default date
if @compdate is null
   	begin
   	select @compdate='12/31/2070'
   	end

---- if tax type is null assume sales type
if isnull(@taxtype,0) = 0
	begin
	select @taxtype = 1
	end

---- validate the tax code and get tax rate for this tax code
exec @retcode = bspHQTaxRateGetAll @taxgroup, @taxcode, @compdate, @valueadd output, @taxrate output,
		null, null, null, null, null, null, null, null, NULL, NULL, @msg output
if @retcode <> 0
    begin
    select @taxrate = 0, @rcode = 1
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
GRANT EXECUTE ON  [dbo].[vspMSHQTaxRateGet] TO [public]
GO
