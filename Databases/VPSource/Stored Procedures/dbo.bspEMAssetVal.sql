SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMAssetVal    Script Date: 8/28/99 9:32:39 AM ******/
   CREATE   procedure [dbo].[bspEMAssetVal]
   
   /***********************************************************
    * CREATED BY: JM 2/9/99
    * MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    * USAGE:
    *	Validates an Asset vs bEMDP and vs bEMEM for a specified
    *	Equipment.
    *
    * INPUT PARAMETERS
    *	@emco			EM Company to be validated against
    *	@asset			Asset to be validated
    *	@equipment		Equipment to be validated against in EMEM
    *
    * OUTPUT PARAMETERS
    *	@msg 			Error or Description of Component
    *	@comptypecode		ComponentTypeCode for Component if
    *				valid
    *
    * RETURN VALUE
    *	0 Success
    *	1 Error
    ***********************************************************/
   
   (@emco bCompany = null,
   @asset varchar(20) = null,
   @equipment bEquip = null,
   @msg varchar(255) output)
   
   
   as
   
   set nocount on
   declare @rcode int, @numrows int
   select @rcode = 0
   
   if @emco is null
   	begin
   	select @msg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @asset is null
   	begin
   	select @msg = 'Missing Asset!', @rcode = 1
   	goto bspexit
   	end
   if @equipment is null
   	begin
   	select @msg = 'Missing Equipment for Asset!', @rcode = 1
   	goto bspexit
   	end
   
   /* Basic validation of Asset vs EMDP. */
   select @msg= Description
   from EMDP
   where EMCo = @emco and Asset = @asset and Equipment = @equipment
   select @numrows = @@rowcount
   if @numrows = 0
    	begin
    	select @msg = 'Invalid Asset!', @rcode = 1
    	goto bspexit
    	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMAssetVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMAssetVal] TO [public]
GO
