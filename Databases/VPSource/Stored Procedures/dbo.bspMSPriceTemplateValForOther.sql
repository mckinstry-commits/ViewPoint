SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSPriceTemplateValForOther]
   /*************************************
   * Created By:   GF 07/27/2000
   * Modified By:
   *
   * Validates MS Price Template for other modules.
   * First validates for the current company, if not found
   * then checks all other companies.
   *
   * Pass:
   * MS Company
   * Module
   * MS Price Template to be validated
   *
   * Success returns:
   *	0 and Description from bMSTH
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@co bCompany = null, @module varchar(2) = null, @pricetemplate smallint = null,
   @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if @co is null
   	begin
   	select @msg = 'Missing Company', @rcode = 1
   	goto bspexit
   	end
   
   if @pricetemplate is null
   	begin
   	select @msg = 'Missing MS Price Template', @rcode = 1
   	goto bspexit
   	end
   
   -- validate price template for JC
   if @module = 'JC'
   BEGIN
       -- validate for current JC company
       select @msg=Description from bMSTH where MSCo=@co and PriceTemplate=@pricetemplate
       if @@rowcount <> 0
           goto bspexit
       -- validate for all other JC companies
       select @msg=min(a.Description) from bMSTH a
       where a.PriceTemplate=@pricetemplate and a.MSCo<>@co
       and exists(select * from bJCCO b where b.JCCo=a.MSCo)
       if @@rowcount = 0
           begin
           select @msg = 'Not a valid MS Price Template', @rcode = 1
           end
       goto bspexit
   END
   
   -- validate price template for AR
   if @module = 'AR'
   BEGIN
       -- validate for current AR company
       select @msg=Description from bMSTH where MSCo=@co and PriceTemplate=@pricetemplate
       if @@rowcount <> 0
           goto bspexit
       -- validate for all other AR companies
       select @msg=min(a.Description) from bMSTH a
       where a.PriceTemplate=@pricetemplate and a.MSCo<>@co
       and exists(select * from bARCO b where b.ARCo=a.MSCo)
       if @@rowcount = 0
           begin
           select @msg = 'Not a valid MS Price Template', @rcode = 1
           end
       goto bspexit
   END
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPriceTemplateValForOther] TO [public]
GO
