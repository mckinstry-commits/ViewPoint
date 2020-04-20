SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatlGrpGet    Script Date: 8/28/99 9:34:52 AM ******/
   CREATE    proc [dbo].[bspHQMatlGrpGet]
   /********************************************************
   * CREATED BY: 	SE 2/6/97
   * MODIFIED BY:
    *				RM 02/13/04 = #23061, Add isnulls to all concatenated strings
   *
   * USAGE:
   * 	Retrieves the Material Group from bHQCO
   *
   * INPUT PARAMETERS:
   *	HQ Company number
   *
   * OUTPUT PARAMETERS:
   *	Material Group from bHQCO
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
   	(@hqco bCompany = 0, @MatlGroup tinyint output, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   
   if @hqco = 0
   	begin
   	select @msg = 'Missing HQ Company#', @rcode = 1
   	goto bspexit
   	end
   
   select @MatlGroup = MatlGroup from bHQCO with (nolock) where HQCo = @hqco
   if @@rowcount = 1 
      select @rcode=0
   else
      select @msg = 'HQ company does not exist.', @rcode=1, @MatlGroup=0
   
   if @MatlGroup is Null 
      select @msg = 'Material group not setup for company ' + isnull(convert(varchar(3),@hqco),'') , @rcode=1, @MatlGroup=0
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMatlGrpGet] TO [public]
GO
