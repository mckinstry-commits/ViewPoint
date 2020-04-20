SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/****** Object:  Stored Procedure dbo.vspRQLoadProcCommonInfoGet    Script Date: 7/21/2005******/
  CREATE           procedure [dbo].[vspRQLoadProcCommonInfoGet]
  /************************************************************************
  * CREATED:	DC 7/21/05    
  * MODIFIED:    DC 12/04/08 #130129  - Combine RQ and PO into a single module
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
      (@co bCompany, @auto bYN output, @matlgroup tinyint output, @jcco bCompany output,
		@emco bCompany output, @inco bCompany output, @glco bCompany output, 
		@vendorgrp bGroup output, @taxgrp bGroup output,
		@phasegrp bGroup output, @emgrp bGroup output, @msg varchar(255) output)
  
  as
  set nocount on
  
      declare @rcode int
  
      SELECT @rcode = 0
  
  	if @co is null
  		begin
  		SELECT @msg = 'Missing PO Company', @rcode = 1
  		GOTO vspexit
  		end

	--get AutoYN flag  
  	SELECT 	@auto = isnull(AutoRQ,'N')
  	FROM	POCO WITH (NOLOCK)
  	WHERE	POCo = @co
  	if @@rowcount <> 1 
  		BEGIN
  		SELECT @msg = 'Invalid PO Company', @rcode = 1
  		GOTO vspexit
  		END
  		
	--Get JC Company, EM Company, IN Company, GL Company, CM Company and CM Account from APCO
  	select 	@jcco=JCCo,
			@emco=EMCo,
			@inco=INCo,
			@glco=GLCo
  	from bAPCO with (nolock)
	where APCo=@co

	--Get Vendor Group  
    select @vendorgrp = VendorGroup, 
			@taxgrp=TaxGroup, 
			@matlgroup = MatlGroup, 
			@phasegrp=PhaseGroup, 
			@emgrp = EMGroup
    from HQCO WITH (NOLOCK)
    where @co = HQCo
    if @@rowcount = 0
       BEGIN
       select @msg = 'Not a valid HQ Company!', @rcode = 1
       goto vspexit
       END

  vspexit:
  IF @rcode<>0 
  RETURN @rcode
  
 





GO
GRANT EXECUTE ON  [dbo].[vspRQLoadProcCommonInfoGet] TO [public]
GO
