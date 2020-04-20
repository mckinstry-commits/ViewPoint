SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspRQEntryLoadProc    Script Date: 7/21/2005******/
  CREATE           procedure [dbo].[vspRQEntryLoadProc]
  /************************************************************************
  * CREATED:	DC 7/21/05    
  * MODIFIED:    DC 6/26/09 - #130129 - Combine RQ and PO into a single module
  *
  * Purpose of Stored Procedure:
  *		Used by RQ Entry as the Load Procedure    
  *    
  * Returns
  *	AutoRQ (Y or N)  = @auto
  * Material Group   = MatlGroup from HQ Company
  * JCCo = Default JCCo from AP Company
  * EMCo = Default EMCo from AP Company
  * INCo = Default INCo from AP Company
  * GLCo = Default GLCo from AP Company
  * CMCo = Default CMCo from AP Company
  * CMAcct = Default CMAcct from AP Company
  * VendorGrp = VendorGroup from HQ Company
  *	taxgrp = tax group from HQ Company
  * phasegrp = phase group from HQ Company
  * emgrp = em group from HQ company
  *           
  * Used In:
  *	DDFH / RQEntry / Load Procedure
  * DDFH / RQEntryItems / Load Procedure
  *
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
      (@rqco bCompany, @auto bYN output, @matlgroup tinyint output, @jcco bCompany output,
		@emco bCompany output, @inco bCompany output, @glco bCompany output, @cmco bCompany output,
		@cmacct bCMAcct output, @vendorgrp bGroup output, @taxgrp bGroup output,
		@phasegrp bGroup output, @emgrp bGroup output, @msg varchar(255) output)
  
  as
  set nocount on
  
      declare @rcode int
  
      SELECT @rcode = 0
  
  	if @rqco is null
  		begin
  		SELECT @msg = 'Missing RQ Company', @rcode = 1
  		GOTO vspexit
  		end

	--get AutoYN flag  
  	SELECT 	@auto = isnull(AutoRQ,'N')
  	FROM	POCO WITH (NOLOCK)  --DC #130129
  	WHERE	POCo = @rqco  --DC #130129
  	if @@rowcount <> 1 
  		BEGIN
  		SELECT @msg = 'Invalid RQ Company', @rcode = 1
  		GOTO vspexit
  		END
  		
	--Get JC Company, EM Company, IN Company, GL Company, CM Company and CM Account from APCO
  	select 	@jcco=JCCo,
			@emco=EMCo,
			@inco=INCo,
			@glco=GLCo,
  			@cmco=CMCo,
			@cmacct = CMAcct
  	from bAPCO with (nolock)
	where APCo=@rqco

	--Get Vendor Group  
    select @vendorgrp = VendorGroup, 
			@taxgrp=TaxGroup, 
			@matlgroup = MatlGroup, 
			@phasegrp=PhaseGroup, 
			@emgrp = EMGroup
    from HQCO WITH (NOLOCK)
    where @rqco = HQCo
    if @@rowcount = 0
       BEGIN
       select @msg = 'Not a valid HQ Company!', @rcode = 1
       goto vspexit
       END

  vspexit:
  IF @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspRQEntryLoadProc]'
  RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspRQEntryLoadProc] TO [public]
GO
