SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPOTaxCodeVal    Script Date: 8/28/99 9:35:27 AM ******/
   CREATE procedure [dbo].[bspPOTaxCodeVal]
   /***********************************************************
    * CREATED BY: SE   4/30/97
    * MODIFIED By : SE 1/28/98
	*				DC 06/24/08 - #128435  Added Tax Type 3-VAT
    *
    * USAGE:
    * Validates PO TaxCode and TaxType Combination
    *
    * This is used in PORBVal, POCBVal and POHBVal to validate
    * Also in APHBVal
    * Tax Code information.
    * 
    * TaxCode must be in HQTX, and TaxType must be 1 or 2, but if
    * TaxCode is null then TaxType must be null
    *
    * PASS IN
    *   TaxGroup     TaxGroup
    *   TaxCode      Taxcode to validate
   
    *   TaxType      TaxType To validate
    * 
    * OUTPUT PARAMETERS
    *   TaxPhase     Tax phase setup for this tax, null if none
    *   TaxCT	  Tax Cost type setup for this tax, null if none
    *   ERRMSG       if error then message about error
    *
    * RETURNS
    *   0 on SUCCESS, 
    *   1 on FAILURE, see MSG for failure
    *
    *****************************************************/ 
   
    @taxgroup bGroup, @taxcode bTaxCode, @taxtype tinyint, @taxphase bPhase output,
    @taxct bJCCType output, @errmsg varchar(255) output 
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode=0, @errmsg='Valid'
   
   if isnull(@taxcode,'') <> '' 
   	begin
       select @taxphase=Phase, @taxct=JCCostType 
   	from bHQTX where @taxgroup=TaxGroup and @taxcode=TaxCode
       if @@rowcount = 0
   		begin
           select @errmsg = 'Tax Code ' + @taxcode + ' is invalid!', @rcode=1
           goto bspexit
   		end
   
   	-- tax type only exists if there is a tax code
       if @taxtype <> 1 and @taxtype <> 2 and @taxtype <> 3
   		begin
   		select @errmsg = 'Tax type must be either 1 or 2 or 3!', @rcode=1
           goto bspexit
   		end
   	end
   else
   	begin
   	-- if no tax code then null out taxphase and taxtc
   	select @taxphase=null, @taxct=null
   	if @taxtype is not null
   		begin
   		select @errmsg = 'Tax type is only valid if there is a tax code!', @rcode=1
   		goto bspexit
   		end
   	end		       			         
   
   
   
   bspexit:
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOTaxCodeVal] TO [public]
GO
