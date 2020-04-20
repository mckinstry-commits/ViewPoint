SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQTaxCodeValForFuelPosting    Script Date: 12/26/2001 10:40:22 AM ******/
   
   CREATE     proc [dbo].[bspHQTaxCodeValForFuelPosting]
   /********************************************************
   * CREATED BY: JM 12/11/01
   * MODIFIED BY: JM 12/26/01 - Eliminated return of TaxRate - not required for Fuel posting.
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
   *	EffectiveDate
   *	Error message
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
   (@taxgroup bGroup = null, 
   @compdate bDate = null,
   @taxcode bTaxCode = null, 
   --@taxrate bRate output, 
   @msg varchar(60)=null output)
   as
   
   set nocount on
   declare @rcode int, @type char(1), @dateyes varchar(15)
   
   select @rcode=0
   
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
   
   /*select @msg = base.Description,	 @taxrate = sum(case base.MultiLevel when 'Y'
   	      then
   		--Pulls from the local Table from more than 1 taxcode
   	       (case when @compdate < isnull(local.EffectiveDate,'12/31/2070') then
   	         isnull(local.OldRate,0) else isnull(local.NewRate,0) end)
   	      else
   		--Pulls from the base Table for only 1 tax code
   	        (case when @compdate < isnull(base.EffectiveDate,'12/31/2070') then
   	         isnull(base.OldRate,0) else isnull(base.NewRate,0) end)
   	      end)
   	from bHQTX base
   		full outer join bHQTL l on l.TaxGroup = base.TaxGroup and l.TaxCode = base.TaxCode
   		full outer join bHQTX local  on local.TaxGroup = l.TaxGroup and local.TaxCode = l.TaxLink
   	where base.TaxGroup = @taxgroup and base.TaxCode = @taxcode
   	group by base.TaxCode, base.Description, base.MultiLevel*/
   select @msg = Description
   	from bHQTX 
   	where TaxGroup = @taxgroup and TaxCode = @taxcode
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Tax Code', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQTaxCodeValForFuelPosting] TO [public]
GO
