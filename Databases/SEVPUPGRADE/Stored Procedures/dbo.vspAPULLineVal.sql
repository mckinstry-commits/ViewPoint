SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPayTypeVal    Script Date: 8/28/99 9:34:03 AM ******/
   CREATE    proc [dbo].[vspAPULLineVal]
   /***************************************************
   * CREATED BY    : MV 11/01/06
   *
   * Usage:
   *   Returns Line description for display in Line label
   *
   * Input:
   *	@co         
   *    @uimth
   *	@uiseq
   *    @line
   * Output:
   *   @msg          header description
   *
   * Returns:
   *	0             success
   *   1             error
   *************************************************/
   	(@co bCompany = null, @uimth bMonth = null, @uiseq int = null,
       @line int = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @co is null
   	begin
      	goto bspexit
   	end
 
   if @uimth is null
   	begin
   		goto bspexit
   	end

	if @uiseq is null
   	begin
   		goto bspexit
   	end

	if @line is null
   	begin
   		goto bspexit
   	end

	begin
		select @msg = Description from APUL where APCo=@co and UIMth=@uimth and UISeq=@uiseq and Line=@line
	end   

   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPULLineVal] TO [public]
GO
