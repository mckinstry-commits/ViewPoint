SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQUMValForPO    Script Date: 8/28/99 9:34:56 AM ******/
   CREATE   proc [dbo].[bspHQUMValForPO]
   /*************************************
   MODIFIED:
   			RM 03/26/04 - Issue# 23061 - Added IsNulls
   
   
   * validates HQ Unit of Measure For a PO
   * If Material exists in HQMT then UM must exist
   * in HQMU or be STD Unit Of Measure.
   *
   * If Material doesn't exist in HQMT then UM must
   * exist in HQUM
   *
   * Pass:
   *       Material Group
   *	Material
   *       Unit Of Measure to validate
   * Returns:
   *       Description from bHQUM
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   
   	(@matlgroup bGroup, @matl bMatl, @um bUM, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int, @stdum bUM
   
   select @rcode = 0
   
   select @stdum = StdUM from bHQMT
          where MatlGroup=@matlgroup and Material=@matl
   
   /*If Material exists in bHQMT then must be in HQMU or STDUM*/
   if @@rowcount > 0
      begin
       if @stdum <> @um
          if not exists (select * from bHQMU
                 where MatlGroup=@matlgroup and Material=@matl and UM = @um)
     	       begin
   	       select @msg = 'Unit of Measure not setup for material:' + isnull(@matl,''), @rcode = 1
   	       goto bspexit
   	       end
      end
   
   select @msg = Description from bHQUM where UM = @um
    if @@rowcount = 0
       begin
        select @msg = 'Unit of Measure not setup!', @rcode = 1
       end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQUMValForPO] TO [public]
GO
