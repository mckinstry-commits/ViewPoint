SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  function [dbo].[vfHQTaxRate]
(@taxgroup bGroup = null, @taxcode bTaxCode = null, @compdate bDate = null)
returns bRate
/***********************************************************
* CREATED BY:  DANF 10/31/2005
* MODIFIED BY: TJL 05/15/08 - Issue #127263, International Sales Tax	
*
* USAGE:
* 	Retrieves the tax rate from HQTX. If tax code is multi-level
*	(i.e. MultiLevel = 'Y') totals rates from linked codes in bHQTL.
*
* INPUT PARAMETERS:
*	TaxGroup  assigned in bHQCO
*	HQ Tax Code
*	Date - for comparision to Effective Date
*
* OUTPUT PARAMETERS:
*	OldRate
*	NewRate
*
*****************************************************/
as
begin

declare @taxrate bRate, @valueadd char(1), @multilevel char(1),	@gstrate bRate
select @taxrate = 0
  
if @taxgroup is null
	begin
	goto exitfunction
	end
if @taxcode is null
	begin
	goto exitfunction
	end
if @compdate is null
	/*if Compdate is null then always use New Rate */
	begin
	select @compdate='12/31/2070'
	end

/* Return base taxcode values */
select @valueadd = ValueAdd, @multilevel = MultiLevel
from dbo.bHQTX with (nolock)
where TaxGroup = @taxgroup and TaxCode = @taxcode
if @@rowcount = 0
	begin
	goto exitfunction
   	end
 
if @valueadd = 'N'
	begin
	/* Standard US - Non VAT */
	select @taxrate = sum(case base.MultiLevel when 'Y'
		then
   			--MultiLevel:  Pulls from the component taxcodes.
			(case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
			isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end)
		else
   			--SingleLevel:  Pulls from the base taxcode.
			(case when @compdate < isnull(base.EffectiveDate,'12/31/2070') then
   			isnull(base.OldRate,0) else isnull(base.NewRate,0) end)
		end)
	from dbo.bHQTX base with(nolock)
	full outer join dbo.bHQTL l with(nolock)on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
	full outer join dbo.bHQTX comp with(nolock)on comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
	where base.TaxGroup = @taxgroup and base.TaxCode = @taxcode
	group by base.TaxCode, base.MultiLevel
	end
else
	begin
	/* International - VAT */
	if @multilevel = 'N'
		begin
		--Single Level - GST only or (HST)Harmonized:  Pulls from the base taxcode.
		select @taxrate = (case when @compdate < isnull(base.EffectiveDate,'12/31/2070') then
   				isnull(base.OldRate,0) else isnull(base.NewRate,0) end)
		from dbo.bHQTX base with(nolock)
		where base.TaxGroup = @taxgroup and base.TaxCode = @taxcode
		end
	else
		begin
		--MultiLevel - GST & PST or HST(Harmonized with breakout)
		
		/* Get GST rate for conversion */
		select @gstrate = case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
   					 isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end
		from dbo.bHQTX base with(nolock)
		full outer join dbo.bHQTL l with(nolock)on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
		full outer join dbo.bHQTX comp with(nolock)on comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
		where base.TaxGroup = @taxgroup and base.TaxCode = @taxcode and comp.GST = 'Y' 

		/* Determine Tax Rate */
		select @taxrate = sum(case comp.InclGSTinPST when 'Y'
			then
   				--MultiLevel (GST included in PST):  Pulls from the component taxcode and performs conversion
				((1.0 + @gstrate) * (case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
				isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end))
			else
				--MultiLevel:  Pulls from the component without conversion
				(case when @compdate < isnull(comp.EffectiveDate,'12/31/2070') then
				isnull(comp.OldRate,0) else isnull(comp.NewRate,0) end)
			end)
		from dbo.bHQTX base with(nolock)
		full outer join dbo.bHQTL l with(nolock)on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
		full outer join dbo.bHQTX comp with(nolock)on comp.TaxGroup = l.TaxGroup and comp.TaxCode = l.TaxLink
		where base.TaxGroup = @taxgroup and base.TaxCode = @taxcode
		group by base.TaxCode, base.MultiLevel
		end
	end 
  
if @@rowcount = 0
	begin
	goto exitfunction
	end
 
exitfunction:
  			
return @taxrate
end

GO
GRANT EXECUTE ON  [dbo].[vfHQTaxRate] TO [public]
GO
