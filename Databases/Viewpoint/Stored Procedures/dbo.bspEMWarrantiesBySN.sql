SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWarrantiesBySN    Script Date: 8/28/99 9:34:37 AM ******/
   CREATE   proc [dbo].[bspEMWarrantiesBySN]
   /********************************************************
   * CREATED BY: 	JM 9/24/98
   * MODIFIED BY:TV 02/11/04 - 23061 added isnulls 
   *
   * USAGE:
   * 	Retrieves number of warranties listed in EMWF for a SerialNo
   *	and HQMaterial
   *	
   * INPUT PARAMETERS:
   
   *	SerialNo
   *	HQMaterial
   *
   * OUTPUT PARAMETERS:
   *	Number of records found in EMWF for input params
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   **********************************************************/
   
   (@serialno char(30) = null, @hqmaterial bMatl = null, 
   @warrbysn tinyint output, @msg varchar(60) output) 
   
   as 
   
   set nocount on
   declare @rcode int, @warr tinyint
   select @rcode = 0
   
   if @serialno is null
   	begin
   	select @msg = 'Missing Serial No!', @rcode = 1
   	goto bspexit
   	end
   
   if @hqmaterial is null
   	begin
   	select @msg = 'Missing HQ Part Code!', @rcode = 1
   	goto bspexit
   	end
   
   select @warrbysn = count(*)
   from dbo.EMWF with(nolock)
   where SerialNo = @serialno and HQMaterial = @hqmaterial
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWarrantiesBySN]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWarrantiesBySN] TO [public]
GO
