SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQTaxGrpGet    Script Date: 4/15/2002 3:53:22 PM ******/
   /****** Object:  Stored Procedure dbo.bspHQTaxGrpGet    Script Date: 8/28/99 9:34:55 AM ******/
   CREATE     proc [dbo].[bspHQTaxGrpGet]
   /********************************************************
   * CREATED BY: 	SE 4/30/97
   * MODIFIED BY:
   *			RM 03/26/04 - Issue# 23061 - Added IsNulls
   *			MV 1/6/04 - #26063 added '= null' to taxgroup and msg
   * USAGE:
   * 	Retrieves the Tax Group from bHQCO
   *
   * INPUT PARAMETERS:
   *	HQ Company number
   *
   * OUTPUT PARAMETERS:
   *	Tax Group from bHQCO
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
   	(@hqco bCompany = 0, @TaxGroup tinyint = null output, @msg varchar(60)= null output)
   as
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   
   Select @msg = 'Start'
   
   if @hqco = 0
   	begin
   	select @msg = 'Missing HQ Company#', @rcode = 1
   	goto bspexit
   	end
   
   select @TaxGroup = TaxGroup from bHQCO with (nolock) where HQCo = @hqco
   if @@rowcount = 1
      select @rcode=0
   else
      select @msg = 'HQ company does not exist.', @rcode=1, @TaxGroup=0
   
   if @TaxGroup is Null
      select @msg = 'Tax group not setup for company ' + isnull(convert(varchar(3),@hqco),'') , @rcode=1, @TaxGroup=0
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQTaxGrpGet] TO [public]
GO
