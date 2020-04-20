SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPayTypeVal    Script Date: 8/28/99 9:34:03 AM ******/
   CREATE    proc [dbo].[vspAPTLLineCount]
   /***************************************************
   * CREATED BY    : MV 05/05/09
   *
   * Usage:
   *   Returns count of APTL lines for a given transaction
   *
   * Input:
   *	@apco         
   *    @mth
   *	@aptrans      
   * Output:
   *	@count
   *   @msg          
   *
   * Returns:
   *	0             success
   *   1             error
   *************************************************/
   	(@apco bCompany , @mth bMonth , @aptrans int, 
       @count int output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @count=0
   
   	begin
		select @count = count(*) from APTL where APCo=@apco and Mth=@mth and APTrans=@aptrans
	end
   
	if @count is null select @count= 0
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPTLLineCount] TO [public]
GO
