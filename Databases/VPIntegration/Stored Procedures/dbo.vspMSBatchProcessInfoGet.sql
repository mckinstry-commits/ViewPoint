SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************************/
CREATE    proc [dbo].[vspMSBatchProcessInfoGet]
/***********************************************************
 * Created By:  GF 02/10/2006
 * Modified By: 
 *
 *
 *
 * USAGE:
 * Gets MS batch process info.
 *
 *  Returns success, or error
 *
 * INPUT PARAMETERS
 *   msco - MS Company
 *
 * OUTPUT PARAMETERS
 *	@glco				GL Co#
 *	@autoapplycash		Auto Apply Payments to Cash Invoices
 *
 *
 *	@errmsg				Error message
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *
 *****************************************************/
(@msco bCompany = 0, @glco bCompany output, @autoapply bYN output, @jclevel tinyint output,
 @emlevel tinyint output, @inlevel tinyint output, @inprodlevel tinyint output,
 @glinvlevel tinyint output, @glticlevel tinyint output, @arlevel tinyint output,
 @msjrnldesc bDesc output,@attachbatchreports bYN output, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @msjrnl bJrnl
   
select @rcode = 0, @jclevel = 0, @emlevel = 0, @inlevel = 0, @inprodlevel = 0,
       @glticlevel = 0, @glinvlevel = 0, @arlevel = 0, @msjrnldesc = ''


---- missing MS company
if @msco is null
	begin
   	select @errmsg = 'Missing MS Company!', @rcode = 1
   	goto bspexit
   	end


---- validate and get MS company info
---- get MSCo data
select @glco=GLCo, @autoapply=AutoApplyCash, @jclevel=JCInterfaceLvl, @emlevel=EMInterfaceLvl,
       @inlevel=INInterfaceLvl, @inprodlevel=INProdInterfaceLvl, @glticlevel=GLTicLvl,
	   @glinvlevel=GLInvLvl, @arlevel=ARInterfaceLvl, @msjrnl=Jrnl,
	   @attachbatchreports = IsNull(AttachBatchReportsYN,'N')
from dbo.MSCO with (nolock) where MSCo=@msco
if @@rowcount <> 1
	begin
	select @errmsg = 'MS Company ' + convert(varchar(3), @msco) + ' is not setup!', @rcode = 1
	goto bspexit
	end


---- get GL Journal Descriptions
select @msjrnldesc=Description from dbo.GLJR with (nolock) where GLCo=@glco and Jrnl=@msjrnl






bspexit:
	if @rcode<> 0 select @errmsg = @errmsg
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSBatchProcessInfoGet] TO [public]
GO
