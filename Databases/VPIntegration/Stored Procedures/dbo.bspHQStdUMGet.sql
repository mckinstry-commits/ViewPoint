SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQStdUMGet    Script Date: 8/28/99 9:34:54 AM ******/
   CREATE    proc [dbo].[bspHQStdUMGet]
   /********************************************************
   * CREATED BY:  kf 4/4/97
   * MODIFIED BY: GG 06/25/99
   *
   * USAGE:
   * 	Called by various procedures to retrieve a materials standard
   *   unit of measure and the factor used to convert its posted unit of measure
   *   to its standard unit of measure.  Will be 0.00 if not convertable.
   *
   * INPUT PARAMETERS:
   *   @matlgroup        Material Group
   *	@material         Material
   *	@um               Posted unit of measure
   *
   * OUTPUT PARAMETERS:
   *   @conv             Conversion factor (posted units * conversion factor = std units)
   *   @stdum            Material's standard unit of measure
   *   @msg              Error message
   *
   * RETURN VALUE:
   * 	0 	              Success
   *	1                 Failure
   *
   **********************************************************/
   
   	(@matlgroup bGroup = null, @material bMatl = null, @um bUM = null,
   	 @conv bUnitCost = null output, @stdum bUM = null output, @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @conv = 0
   
   if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group', @rcode=1
   	goto bspexit
   	end
   if not exists (select 1 from bHQGP where Grp = @matlgroup)
   	begin
   	select @msg = 'Invalid Material Group', @rcode=1
   	goto bspexit
   	end
   if @material is null
   	begin
   	select @msg = 'Missing Material', @rcode=1
   	goto bspexit
   	end
   if @um is null
       begin
       select @msg = 'Missing Unit of Measure.', @rcode = 1
       goto bspexit
       end
   
   -- get material's standard unit of measure
   select @stdum = StdUM
   from bHQMT where MatlGroup = @matlgroup and Material = @material
   if @@rowcount = 0 goto bspexit  -- no conversion available
   if @stdum = @um
   	begin
   	select @conv = 1   -- conversion factor = 1
   	goto bspexit
   	end
   -- check for non standard UM for this material
   select @conv = Conversion   -- conversion will remain 0.00 if not found in bHQMU
   from bHQMU
   where MatlGroup = @matlgroup and Material = @material and UM = @um
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQStdUMGet] TO [public]
GO
