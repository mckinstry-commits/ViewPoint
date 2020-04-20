SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspHQRGVal]
   /***************************************************
   * CREATED BY    : MV 11/28/07
   *
   * Usage:
   *   Returns Reviewer Group description for display in Label Desc
   *
   * Input:
   *	@reviewergroup         
     * Output:
   *   @msg          description
   *
   * Returns:
   *   0             success
   *   1             error
   *************************************************/
   	(@reviewergroup varchar(10) = null, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
	if @reviewergroup is null
   	begin
   		goto vspexit
   	end

	begin
		select @msg = Description from HQRG where ReviewerGroup=@reviewergroup
	end   

   
   
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQRGVal] TO [public]
GO
