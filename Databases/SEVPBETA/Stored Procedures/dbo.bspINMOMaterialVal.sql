SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[bspINMOMaterialVal]
    /********************************************************
     * Created: RM 02/21/02
     * Modified: GG 03/12/02 - Check for Active Material
     *
     * Usage: used in Material Order Entry to validate Material
     *
     * Inputs
     *	@co			IN Co#
     *	@location	Location
     *	@material	Material
     *	
     * Outputs
     *	@defaultphase	Default Phase for the material
     *	@defaultct		Default Cost Type for the material
     *	@defaultum		Std unit of measure
     *	@ecm			Std Cost E/C/M ??????????????????????????????
     *	@msg			Material description or error message
     *
     * Returns
     * 	@rcode			0 = success, 1 = error
     *
     *********************************************************/
    	(@co bCompany = null, @location bLoc = null, @material bMatl = null,
    	 @defaultphase bPhase = null output, @defaultct bJCCType = null output, @defaultum bUM = null output,
    	 @ecm bECM = null output, @taxable bYN = null output, @msg varchar(255) output)
    as
    
    set nocount on
    
    declare @rcode int,@jobpriceopt tinyint,@discrate bRate
    
    select @rcode=0
   
   
    -- validate Material
    select @msg = h.Description, @defaultphase = h.MatlPhase, @defaultct = h.MatlJCCostType,
    	@defaultum = h.StdUM, @ecm = i.StdECM,@taxable = h.Taxable
    from INMT i
    join HQMT h on i.MatlGroup = h.MatlGroup and i.Material = h.Material 
    where i.INCo = @co and i.Loc = @location and i.Material = @material and i.Active = 'Y'
    
    if @@rowcount = 0
    	begin
    	select @msg='Invalid or inactive Material for IN Location ' + convert(varchar(10),@location), @rcode = 1
    	goto bspexit
    	end
    
    bspexit:
    	--if @rcode=1 select @msg
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOMaterialVal] TO [public]
GO
