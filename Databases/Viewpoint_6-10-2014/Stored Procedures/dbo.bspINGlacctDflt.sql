SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINGlacctDflt    Script Date: 12/6/2004 8:26:01 AM ******/
    CREATE     proc [dbo].[bspINGlacctDflt]
     /***********************************************************
      * CREATED BY: GR 1/29/00
      * Modified by: GG 10/13/00 - changed logic to get std account if override is null
      *			GG 11/16/00 - init @rcode = 0
      *         BC 2/15/01 - corrected the check on glacct if null
      *         RM 03/30/01 - Added check for Override GL flag
      * 			RM 12/23/02 Cleanup Double Quotes
      *			DC 12/6/04 - #26184 Initialized output variables to Null at beginning of sp
      *
      * USAGE:
      * this sp takes information about an inventory posting line and returns the default
      * glacct.
      *
      * INPUT PARAMETERS
      *   @co         	Inventory Company
      *   @location   	Inventory Location
      *   @material   	Material
      *	@matlgroup	Material Group
      *
      * OUTPUT PARAMETERS
      *   @glacct        Inventory GL Account
      *   @msg           Error message
      *
      * RETURN VALUE
      *   0         success
      *   1         failure
      *****************************************************/
     	(@co bCompany = null, @location bLoc = null, @material bMatl = null,
     	 @matlgroup bGroup = null, @glacct bGLAcct output, @overridegl bYN output, @msg varchar(255) output)
    
     as
     set nocount on
    
     declare @rcode int, @category varchar(10)
    
     SELECT @rcode = 0
     SELECT @glacct = NULL		--DC 26184
    
     if @co is null
         begin
         select @msg = 'Missing IN Company', @rcode = 1
         goto bspexit
         end
     if @location is null
         begin
         select @msg = 'Missing Location', @rcode = 1
         goto bspexit
         end
     if @matlgroup is null
         begin
         select @msg = 'Missing Material Group', @rcode = 1
         goto bspexit
         end
    
     --get category based on Material and Matl Group
     select @category = Category
     from bHQMT
     where Material = @material and MatlGroup = @matlgroup
     if @@rowcount = 0
     	begin
     	select @msg = 'Material not setup in HQ!', @rcode = 1
     	goto bspexit
     	end
    
     --check for optional override Inventory GL Account based on Location and Category
     select @glacct = InvGLAcct
     from bINLO
     where INCo = @co and Loc = @location and MatlGroup = @matlgroup and Category = @category
    
     --if override is null, use Inventory GL Account from Location Master
     if isnull(@glacct, '') = ''
     	begin
          select @glacct = InvGLAcct from bINLM where INCo = @co and Loc = @location
     	if @@rowcount = 0
     		begin
     		select @msg = 'Invalid Inventory Location!', @rcode = 1
     		goto bspexit
     		end
          end
    
    --get override flag value
    select @overridegl = OverrideGL from bINCO where INCo = @co
    
     bspexit:
     	--if @rcode <> 0 select @msg
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINGlacctDflt] TO [public]
GO
