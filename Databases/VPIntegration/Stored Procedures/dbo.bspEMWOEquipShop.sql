SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspEMWOEquipShop]
   /**************************************************************************
   * CREATED: 2/6/01 tv
   * MODIFIED: GG 09/20/02 - #18522 ANSI nulls
   *			TV 02/11/04 - 23061 added isnulls 
   *			TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
   *
   *USAGE:
   * returns next available shop to EMWOEdit
   *
   *   Inputs:
   *	EMCo
   *	Equipment Number
   *	Sequence stutus
   * 	Sequence option
   *	error message, if there is one
   *	
   *   Outputs:
   *	Shop
   *	
   *
   *
   *   RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *
   ***************************************************************************/
   (@emco bCompany,  @formstatus char(1), @autoopt char(1), @equipnum varchar(10),  @defaultshop varchar(10) output, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equipnum, @msg output
	If @rcode = 1
	begin
		  goto bspexit
	end


   if (select Equipment from dbo.EMEM with (nolock) where Equipment = @equipnum and EMCo = @emco) is null	-- #18522
   	begin 
   	select @msg = 'Invalid Equipment Number: ' + isnull(@equipnum,''), @rcode = 2
   	goto bspexit
   	end 
   
   if @formstatus = 'Y'
   	begin
   -- If option is to sequence by shop--
   	if @autoopt = 'C'
   		begin
   		if (select Shop from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @equipnum) is null -- #18522
   	 		begin
   				select @msg = 'No Defult Shop for this Equipment, Please select Shop.', @rcode = 1
   				goto bspexit
   			end	
	
   				select @defaultshop = (select Shop from dbo.EMEM with (nolock) where EMCo = @emco and Equipment = @equipnum)
		
   		end
   	
   end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + 'bspEMWOEquipShop'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOEquipShop] TO [public]
GO
