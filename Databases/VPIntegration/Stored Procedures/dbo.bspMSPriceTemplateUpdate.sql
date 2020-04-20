SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspMSPriceTemplateUpdate]
   /************************************************************
   * CREATED:	 GG 09/16/02
   * MODIFIED:	
   *
   * USAGE:
   * Replaces all old pricing and minimum amounts in a selected Price
   * Template with new values.
   *
   * INPUT PARAMETERS
   *   @msco      		MS Company #
   *   @pricetemplate  Price Template to process
   *
   * OUTPUT PARAMETERS
   *   @errmsg     if something went wrong
   *
   * RETURN VALUE
   *   @rcode		0 = success, 1 = error
   * 
   ************************************************************/
   	@msco bCompany = null, @pricetemplate smallint = null, @errmsg varchar(255) output
   as
   set nocount on
   
   declare @rcode int
   
   -- validate MS Co#
   if not exists(select 1 from bMSCO where MSCo = @msco)
       begin
       select @errmsg = 'Invalid MS Company!', @rcode = 1
   	goto bspexit
       end
   -- validate Price Template
   if not exists(select 1 from bMSTH where MSCo = @msco and PriceTemplate = @pricetemplate)
       begin
       select @errmsg = 'Invalid Price Template!', @rcode = 1
   	goto bspexit
       end
   
   -- set old pricing and minimum amts equal to new values
   update bMSTP
   set OldRate = NewRate, OldUnitPrice = NewUnitPrice, OldECM = NewECM, OldMinAmt = NewMinAmt
   where MSCo = @msco and PriceTemplate = @pricetemplate
   
   
   bspexit:
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPriceTemplateUpdate] TO [public]
GO
