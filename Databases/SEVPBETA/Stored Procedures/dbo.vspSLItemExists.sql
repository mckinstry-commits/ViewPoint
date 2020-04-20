SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspSLItemExists    Script Date: 8/28/99 9:35:46 AM ******/
   CREATE   proc [dbo].[vspSLItemExists]
   /***********************************************************
    * CREATED:  DC	3/24/10 
    * MODIFIED: GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
    *
    *
    * Used by SL Change Order form to validate SL Items existence.
    *
    * INPUT PARAMETERS
    *    @slco        SL Co#
    *    @sl          SL to validate
    *    @slitem      Item to validate
    *
    * OUTPUT PARAMETERS
    *	 @SLItemExist		   SL Item Exists (Y/N)
    *    @msg                  Item description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/   
       (@slco bCompany = null, @sl VARCHAR(30) = null, @slitem bItem = null, @slitemexist bYN output, 
		@msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   SELECT @rcode = 0, @slitemexist = 'Y'
   
   IF @slco is null
     	BEGIN
     	SELECT @msg = 'Missing SL Company!', @rcode = 1
     	goto vspexit
     	END
   IF @sl is null
     	BEGIN
     	SELECT @msg = 'Missing SL!', @rcode = 1
     	goto vspexit
     	END
   IF @slitem is null
     	BEGIN
     	SELECT @msg = 'Missing SL Item#!', @rcode = 1
     	goto vspexit
     	END
     	
   -- validate SL Item and get info
   SELECT top 1 1 FROM dbo.bSLIT WHERE SLCo = @slco and SL = @sl and SLItem = @slitem
   IF @@rowcount = 0
     	BEGIN
     	SELECT @msg = 'SL Item does not exist!', @rcode = 0, @slitemexist = 'N'
     	goto vspexit
     	END
     	

vspexit:   
return @rcode
     	
     	
GO
GRANT EXECUTE ON  [dbo].[vspSLItemExists] TO [public]
GO
