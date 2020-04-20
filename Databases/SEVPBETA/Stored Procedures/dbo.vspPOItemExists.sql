SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPOItemExists    Script Date: 8/28/99 9:35:46 AM ******/
   CREATE   proc [dbo].[vspPOItemExists]
   /***********************************************************
    * CREATED:  DC	3/24/10 
    * MODIFIED: GF 7/27/2011 - TK-07144 changed to varchar(30)
    *
    * Used by PO Change Order form to validate PO Items existence.
    *
    * INPUT PARAMETERS
    *    @poco        PO Co#
    *    @po          PO to validate
    *    @poitem      Item to validate
    *
    * OUTPUT PARAMETERS
    *	 @POItemExist		   PO Item Exists (Y/N)
    *    @msg                  Item description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/   
       (@poco bCompany = null, @po VARCHAR(30) = null, @poitem bItem = null, @poitemexist bYN output, 
		@msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   SELECT @rcode = 0, @poitemexist = 'Y'
   
   IF @poco is null
     	BEGIN
     	SELECT @msg = 'Missing PO Company!', @rcode = 1
     	goto vspexit
     	END
   IF @po is null
     	BEGIN
     	SELECT @msg = 'Missing PO!', @rcode = 1
     	goto vspexit
     	END
   IF @poitem is null
     	BEGIN
     	SELECT @msg = 'Missing po Item#!', @rcode = 1
     	goto vspexit
     	END
     	
   -- validate SL Item and get info
   SELECT top 1 1 FROM bPOIT WHERE POCo = @poco and PO = @po and POItem = @poitem
   IF @@rowcount = 0
     	BEGIN
     	SELECT @msg = 'PO Item does not exist!', @rcode = 0, @poitemexist = 'N'
     	goto vspexit
     	END
     	

vspexit:   
return @rcode
     	
     	
GO
GRANT EXECUTE ON  [dbo].[vspPOItemExists] TO [public]
GO
