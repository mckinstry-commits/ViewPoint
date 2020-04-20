SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRQCoVal    Script Date: 3/18/2004 9:45:44 AM ******/
     CREATE      proc [dbo].[bspRQCoVal]
     /************************************************
      * Created By: DC  3/18/2004
      * Modified by: DC 4/12/2007  - Added EMGroup to the return parameters
      *
      * 
      *
      * USED IN
      *    RQ Entry
      *    
      *
      * PASS IN
      *   Company#
      *   RQType
      *
      * RETURN PARAMETERS
      *   MatGrp   		Material group for this company
      *   PhaseGrp 		if Type is Job then Phase Group for JobCostCompany
      *	  TaxGrp		from HQCO
      *   EM Cost Code	from EMCO
      *   EM Cost Type	from EMCO
	  *	  EM Group		from EMCO
      *   msg     Company Description from HQCO
      *
      *
      * RETURNS
      *   0 on Success
      *   1 on ERROR and places error message in msg
     
      **********************************************************/
     	(@co bCompany = 0, @rqtype tinyint,@matlgroup bGroup output,
     	  @phasegrp bGroup output, @taxgrp bGroup output, @emcostcodechg bYN output, 
			@emcosttype bEMCType output, @emgroup bGroup = null output, @msg varchar(255) output)
     as
     	set nocount on
     
     	declare @rcode int
     
     select @rcode = 0, @phasegrp=null, @taxgrp=null
     
     select @msg = Name, @taxgrp=TaxGroup, @matlgroup=MatlGroup, @phasegrp=PhaseGroup
     from HQCO WITH (NOLOCK)
     where @co = HQCo
     if @@rowcount = 0
        begin
        select @msg = 'Not a valid HQ Company!', @rcode = 1
        goto bspexit
        end
     
     if @rqtype = 1 /*job type */
        begin
        select top 1 1 from JCCO WITH (NOLOCK) where @co=JCCo
        if @@rowcount = 0
          begin
     	 select @msg = 'Not a valid Job Cost Company!', @rcode = 1
          goto bspexit
          end
        end
     
     if @rqtype = 2 /*inventory type */
       begin
       select top 1 1 from INCO WITH (NOLOCK) where @co=INCo
       if @@rowcount = 0
         begin
         select @msg = 'Not a valid Inventory Company!', @rcode = 1
         goto bspexit
         end
       end
     
     if @rqtype = 4 or @rqtype = 5 /*Equipment or Work Order type */
       begin
    	SELECT	@emcostcodechg = WOCostCodeChg, 
    			@emcosttype = PartsCT ,
				@emgroup = EMGroup
    	FROM EMCO WITH (NOLOCK)
    	WHERE @co=EMCo
       if @@rowcount = 0
         begin
         select @msg = 'Not a valid Equipment Company!', @rcode = 1
         goto bspexit
         end
       end
     
     
     bspexit:
    IF @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspRQCoVal]'
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQCoVal] TO [public]
GO
