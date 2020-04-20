SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQMatlCategoryDistinct    Script Date: 8/20/2004 2:45:45 PM ******/
     CREATE    proc [dbo].[bspHQMatlCategoryDistinct]
     /*************************************
     *  Created by:  DC  8/20/04
     *
     * validates HQ Material Category regardless of Material Group
     *
     * Pass:
     *	HQ Category
     *
     * Success returns:
     *	0 and Description from bHQMC
     *
     * Error returns:
     *	1 and error message
     **************************************/
     	(@co bCompany, @category varchar(10) = null, @msg varchar(60) output)
     as 
     	set nocount on
     	declare @rcode int
     	select @rcode = 0
     	
     if @category is null
     	begin
     	select @msg = 'Missing Material Category', @rcode = 1
     	goto bspexit
     	end
     
     SELECT top 1 @msg = m.Description
     FROM HQMC m
   	JOIN HQCO c on c.MatlGroup = m.MatlGroup
     WHERE m.Category = @category
   	AND c.HQCo = isnull(@co,c.HQCo)
     IF @@rowcount = 0
     		begin
     		select @msg = 'Not a valid Material Category', @rcode = 1
     		end 
   
     bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQMatlCategoryDistinct] TO [public]
GO
