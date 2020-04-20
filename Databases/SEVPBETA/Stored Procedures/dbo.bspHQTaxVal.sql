SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQTaxVal    Script Date: 8/28/99 9:32:49 AM ******/
   CREATE  proc [dbo].[bspHQTaxVal]
   /***********************************************************
    * CREATED BY: SE   10/2/96
    * MODIFIED By : GG 04/29/97
    *
    * USAGE:
    * validates HQ Tax Code
    * an error is returned if any of the following occurs
    * no tax code passed, or tax code doesn't exist in HQTX
    *
    * INPUT PARAMETERS
    *   @taxgroup		TaxGroup assigned in bHQCO
    *   @taxcode		TaxCode to validate
    *
    * OUTPUT PARAMETERS
    *   @msg      		Tax code description or error message 
    *
    * RETURN VALUE
    *   @rcode			0 = success, 1 = error
    *   
    *****************************************************/ 
   
   	(@taxgroup bGroup = null, @taxcode bTaxCode = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   select @msg = Description
   from bHQTX
   where TaxGroup = @taxgroup and TaxCode = @taxcode
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Tax code not setup in HQ!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQTaxVal] TO [public]
GO
