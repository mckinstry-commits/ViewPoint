SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHQTaxRateGetAll]
/********************************************************
* CREATED BY:  TJL 05/30/08 - Issue #128286, International Sales Tax
* MODIFIED BY:	MV 02/04/10 - #136500 - return CrdRetgGSTGLAcct
*				MV 10/25/11 - #TK-09243 - return APcrdRetgGLAcctPST
*		
*
* USAGE:
* 	Retrieves the tax rates from HQTX. If tax code is multi-level
*	(i.e. MultiLevel = 'Y') retrieves total tax rate and individual component tax rates.
*	Will also retrieve related Credit and Debit GLAccts
*
* INPUT PARAMETERS:
*	TaxGroup  assigned in bHQCO
*	HQ Tax Code
*	Date - for comparision to Effective Date
*
* OUTPUT PARAMETERS:
*	TaxRate		When multilevel, this is the combined tax rate of its components
*	GST			Goods and Services tax rate		
*	PST			Provincial Sales Tax rate
*	GLAccts		Returns CreditGLAcct, CreditRetgGLAcct, DebitGLAcct, DebitRetgGLAcct
*				CreditGLAcctPST, CreditRetgGLAcctPST
*	Error message
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
   
(@taxgroup bGroup = null, @taxcode bTaxCode = null, @compdate bDate = null,
 @valueadd char(1) output, @taxrate bRate output, @gstrate bRate output, @pstrate bRate = null output,
 @crdGLAcct bGLAcct output, @crdRetgGLAcct bGLAcct output, @dbtGLAcct bGLAcct output, @dbtRetgGLAcct bGLAcct output,
 @crdGLAcctPST bGLAcct output, @ARcrdRetgGLAcctPST bGLAcct output, @crdRetgGLAcctGST bGLAcct output,@APcrdRetgGLAcctPST bGLAcct output,
 @msg varchar(60)=null output)
as

set nocount on

declare @rcode int, @multilevel char(1)

select @rcode = 0, @taxrate = 0, @gstrate = 0, @pstrate = 0
   
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
if @compdate is null
	/*if Compdate is null then always use New Rate */
   	begin
   	select @compdate='12/31/2070'
   	end

/* Get tax rate for this TaxCode */
exec @rcode = bspHQTaxRateGet @taxgroup, @taxcode, @compdate, @taxrate output, null, null, @msg output
if @rcode <> 0
	begin
	select @rcode = 1
	goto bspexit
	end

/* Return base taxcode values
   Non-VAT:	Returns CreditGLAcct and CreditRetgGLAcct
   VAT:		Returns CreditGLAcct, CreditRetgGLAcct, DebitGLAcct,DebitRetgGLAcct,CrdRetgGSTGLAcct */
select @valueadd = ValueAdd, @multilevel = MultiLevel, @msg = Description,
	@crdGLAcct = GLAcct, @crdRetgGLAcct = RetgGLAcct, @dbtGLAcct = DbtGLAcct, @dbtRetgGLAcct = DbtRetgGLAcct,
	@crdRetgGLAcctGST = CrdRetgGSTGLAcct
from dbo.bHQTX with (nolock)
where TaxGroup = @taxgroup and TaxCode = @taxcode

/* Get individual GST and PST tax rates */
if @valueadd = 'Y'
	begin
	if @multilevel = 'Y'
		/* If this is not a ValueAdd taxcode or it is, but not a MultiLevel taxcode then we already have the 
		   GL Accts and Tax Rate from the SingleLevel statement above. */
		begin
		/* ValueAdd/MultiLevel:  We need to breakout and get GST and PST Rates and GLAccts from each component. */
		/* Get GST rate and accounts */
		select @gstrate = case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
   					 isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end,
			@crdGLAcct = comp.GLAcct, @crdRetgGLAcct = comp.RetgGLAcct, 
			@dbtGLAcct = comp.DbtGLAcct, @dbtRetgGLAcct = comp.DbtRetgGLAcct,
			@crdRetgGLAcctGST = comp.CrdRetgGSTGLAcct
		from dbo.bHQTX base with(nolock)
		full outer join dbo.bHQTL l with(nolock)on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
		full outer join dbo.bHQTX comp with(nolock)on comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
		where base.TaxGroup = @taxgroup and base.TaxCode = @taxcode and comp.GST = 'Y'

		/* Get PST rate and accounts */
		select @pstrate = sum(case comp.InclGSTinPST when 'Y'
			then
   				--MultiLevel (GST included in PST):  Pulls from the component taxcode and performs conversion
				((1.0 + @gstrate) * (case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
				isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end))
			else
				--MultiLevel:  Pulls from the component without conversion
				(case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
				isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end)
			end),
			@crdGLAcctPST = comp.GLAcct,
			@ARcrdRetgGLAcctPST = comp.RetgGLAcct,
			@APcrdRetgGLAcctPST = comp.CrdRetgGSTGLAcct
		from dbo.bHQTX base with(nolock)
		full outer join dbo.bHQTL l with(nolock)on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
		full outer join dbo.bHQTX comp with(nolock)on comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
		where base.TaxGroup = @taxgroup and base.TaxCode = @taxcode and comp.GST = 'N'
		group by comp.GLAcct, comp.RetgGLAcct, comp.CrdRetgGSTGLAcct
		end

	end


bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQTaxRateGetAll] TO [public]
GO
