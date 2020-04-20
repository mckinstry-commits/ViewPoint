SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREMCompanyVal    Script Date: 8/28/99 9:33:18 AM ******/
   
    /****** Object:  Stored Procedure dbo.bspPREMCompanyVal   Script Date: 1/28/98 3:25:03 PM ******/
    CREATE  proc [dbo].[bspPREMCompanyVal]
    /*************************************
    * CREATED: kb 1/28/98
    * MODIFIED: kb 3/23/99
    * MODIFIED: EN 9/14/99 - also return labor cost type
    * MODIFIED: EN 1/3/00 - return cost code change flag from LaborCostCodeChg rather than WOCostCodeChg in bEMCO
    *           EN 2/1/00 - return EMGroup from bHQCO rather than bEMCO
    *			EN 10/8/02 - issue 18877 change double quotes to single
    *
    * validates EM Company number and returns Description and information from GLCO from EMCO
    *
    * Pass:
    *	EM Company number
    *
    * Success returns:
    *	0, Company name
    *
    * Error returns:
    *	1 and error message
    **************************************/
    	(@emco bCompany = 0, @glco bCompany output, @emgroup bGroup output, @wocostcodechg bYN output,
    	@laborct bEMCType output, @msg varchar(60) output)
    as
    set nocount on
    	declare @rcode int
    	select @rcode = 0
   
    if @emco = 0
    	begin
    	select @msg = 'Missing EM Company#', @rcode = 1
    	goto bspexit
    	end
   
    select @glco=EMCO.GLCo, @emgroup=HQCO.EMGroup, @wocostcodechg=EMCO.LaborCostCodeChg,
     @laborct = EMCO.LaborCT, @msg = HQCO.Name from EMCO
     join HQCO on HQCO.HQCo=EMCO.EMCo where EMCO.EMCo=@emco
    if @@rowcount = 0
    	begin
    	select @msg = 'Invalid EM Company', @rcode = 1
    	goto bspexit
    	end
   
   
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREMCompanyVal] TO [public]
GO
