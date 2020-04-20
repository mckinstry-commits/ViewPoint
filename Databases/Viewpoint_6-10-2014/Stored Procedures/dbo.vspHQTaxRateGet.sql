SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspHQTaxRateGet]
/********************************************************
* CREATED BY:  DC 09/18/09
* MODIFIED BY: GF 06/11/2012 TK-15658 need to get the GST rate for a VAT single level tax code
*		
*
* USAGE:
* 	Retrieves the tax rates from HQTX. If tax code is multi-level
*	(i.e. MultiLevel = 'Y') retrieves total tax rate and individual component tax rates.
*	Will also retrieve related Credit and Debit GLAccts
*
* Used in:
*	POEntry
*
* INPUT PARAMETERS:
*	TaxGroup	Assigned in bHQCO
*	TaxCode		HQ Tax Code
*	CompDate	Date for comparision to Effective Date
*
* OUTPUT PARAMETERS:
*	@valueadd	
*	@taxrate			When multilevel, this is the combined tax rate of its components
*	@taxphase
*	@taxjcctype
*	@gstrate			Goods and Services tax rate		
*	@pstrate			Provincial Sales Tax rate
*	@crdGLAcct
*	@crdRetgGLAcct
*	@dbtGLAcct
*	@dbtRetgGLAcct
*	@crdGLAcctPST
*	@crdRetgGLAcctPST
*	@msg				Error message
*
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/   
(@taxgroup bGroup, @taxcode bTaxCode, @compdate bDate = NULL,
 @valueadd char(1) output, @taxrate bRate output, @taxphase bPhase=NULL output, 
 @taxjcctype bJCCType=NULL output, @gstrate bRate output, @pstrate bRate = NULL output,
 @crdGLAcct bGLAcct output, @crdRetgGLAcct bGLAcct output, @dbtGLAcct bGLAcct output, 
 @dbtRetgGLAcct bGLAcct output, @crdGLAcctPST bGLAcct output, @crdRetgGLAcctPST bGLAcct output, 
 @msg varchar(255)=NULL output)
as


set nocount on

DECLARE @rcode int, @multilevel char(1)

SELECT @rcode = 0, @taxrate = 0, @gstrate = 0, @pstrate = 0
   
	IF @taxgroup is NULL
		BEGIN
   		SELECT @msg = 'Missing Tax Group', @rcode = 1
   		GOTO vspExit
   		END
	IF @taxcode is NULL
   		BEGIN
   		SELECT @msg = 'Missing Tax Code', @rcode = 1
   		GOTO vspExit
   		END
	IF @compdate is NULL
		/*if Compdate is null then always use New Rate */
   		BEGIN
   		SELECT @compdate='12/31/2070'
   		END

	/* Return base taxcode values 
		Non-VAT:	CreditGLAcct and CreditRetgGLAcct
		VAT:		CreditGLAcct, CreditRetgGLAcct, DebitGLAcct, and DebitRetgGLAcct */
	SELECT @valueadd = ValueAdd, @multilevel = MultiLevel, @taxphase = Phase, @taxjcctype = JCCostType, 
		@crdGLAcct = GLAcct, @crdRetgGLAcct = RetgGLAcct, @dbtGLAcct = DbtGLAcct, @dbtRetgGLAcct = DbtRetgGLAcct,
		@msg = Description
	FROM dbo.bHQTX with (nolock)
	WHERE TaxGroup = @taxgroup and TaxCode = @taxcode
	IF @@rowcount = 0
		BEGIN
   		SELECT @msg = 'Invalid Tax Code', @taxrate=0, @rcode = 1
   		GOTO vspExit
   		END

	IF @valueadd = 'N'
		BEGIN
		/* Non VAT */
		SELECT @taxrate = sum(case base.MultiLevel when 'Y'
			then
   				--MultiLevel:  Pulls from the component taxcodes.
				(case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
				isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end)
			else
   				--SingleLevel:  Pulls from the base taxcode.
				(case when @compdate < isnull(base.EffectiveDate,'12/31/2070') then
   				isnull(base.OldRate,0) else isnull(base.NewRate,0) end)
			end)
		FROM dbo.bHQTX base with(nolock)
			full outer join dbo.bHQTL l with(nolock)on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
			full outer join dbo.bHQTX comp with(nolock)on comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
		WHERE base.TaxGroup = @taxgroup and base.TaxCode = @taxcode
		GROUP BY base.TaxCode, base.MultiLevel
		END
	ELSE
		BEGIN
		/* VAT */
		IF @multilevel = 'N'
			BEGIN
			--Single Level - GST only or (HST)Harmonized:  Pulls from the base taxcode.
			SELECT @taxrate = (case when @compdate < isnull(base.EffectiveDate,'12/31/2070') THEN isnull(base.OldRate,0) else isnull(base.NewRate,0) end)
   					----TK-15658
   					,@gstrate = CASE WHEN base.GST = 'N' THEN 0
   								ELSE (case when @compdate < isnull(base.EffectiveDate,'12/31/2070') 
   								THEN isnull(base.OldRate,0) else isnull(base.NewRate,0) END) 
   								END
			FROM dbo.bHQTX base with(nolock)
			WHERE base.TaxGroup = @taxgroup and base.TaxCode = @taxcode
			END
		ELSE
			BEGIN
			--MultiLevel - GST & PST or HST(Harmonized with breakout)
			
			/* Get GST rate for conversion */
			SELECT @gstrate = case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
   						 isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end,
					@crdGLAcct = comp.GLAcct, @crdRetgGLAcct = comp.RetgGLAcct, 
					@dbtGLAcct = comp.DbtGLAcct, @dbtRetgGLAcct = comp.DbtRetgGLAcct   						 
			FROM dbo.bHQTX base with(nolock)
				full outer join dbo.bHQTL l with(nolock)on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
				full outer join dbo.bHQTX comp with(nolock)on comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
			WHERE base.TaxGroup = @taxgroup and base.TaxCode = @taxcode and comp.GST = 'Y' 

			/* Get PST rate and accounts */
			SELECT @pstrate = sum(case comp.InclGSTinPST when 'Y'
				then
   					--MultiLevel (GST included in PST):  Pulls from the component taxcode and performs conversion
					((1.0 + @gstrate) * (case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
					isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end))
				else
					--MultiLevel:  Pulls from the component without conversion
					(case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
					isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end)
				end),
				@crdGLAcctPST = comp.GLAcct, @crdRetgGLAcctPST = comp.RetgGLAcct
			FROM dbo.bHQTX base with(nolock)
				full outer join dbo.bHQTL l with(nolock)on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
				full outer join dbo.bHQTX comp with(nolock)on comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
			WHERE base.TaxGroup = @taxgroup and base.TaxCode = @taxcode and comp.GST = 'N'
			GROUP BY comp.GLAcct, comp.RetgGLAcct			

			/* Determine Tax Rate */
			SELECT @taxrate = sum(case comp.InclGSTinPST when 'Y'
				then
   					--MultiLevel (GST included in PST):  Pulls from the component taxcode and performs conversion
					((1.0 + @gstrate) * (case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
					isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end))
				else
					--MultiLevel:  Pulls from the component without conversion
					(case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
					isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end)
				end)
			FROM dbo.bHQTX base with(nolock)
				full outer join dbo.bHQTL l with(nolock)on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
				full outer join dbo.bHQTX comp with(nolock)on comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
			WHERE base.TaxGroup = @taxgroup and base.TaxCode = @taxcode
			GROUP BY base.TaxCode, base.MultiLevel
			END
		END   

vspExit:
   	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspHQTaxRateGet] TO [public]
GO
