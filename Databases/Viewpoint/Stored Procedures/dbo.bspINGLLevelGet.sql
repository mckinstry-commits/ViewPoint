SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspINGLLevelGet]
   /*******************************************
    * Created: GG 03/04/00
    * Modified: GG 03/12/02 - Added GL and JC interface levels for Material Orders
    *			TRL 02/20/08 - Issue 21452
    * Called by IN Batch Process form to retrieve GL Interface levels
    * for varoius Inventory batches.
    *
    * Inputs:
    *	@inco		IN Company
    *
    * Outputs:
    *	@gladjlvl		GL Interface level for Adjustments
    *	@gltrnsfrlvl	GL Interface level for Transfers
    *	@glprodlvl		GL Interface level for Production
    *	@glmolvl		GL Interface level for Material Orders
    *	@jcmolvl		JC Interface level for Material Orders
    *	@msg			Error message
    *
    * Return:
    *	@rcode		0 = success, 1 = error
    *
    ****************************************************/
   
   	(@inco bCompany = null, @gladjlvl tinyint = null output, @gltrnsfrlvl tinyint = null output,
   	 @glprodlvl tinyint = null output, @glmolvl tinyint = null output, @jcmolvl tinyint = null output,
   	 @glco tinyint = 0 output, @attachbatchreports bYN output, @msg varchar(255) = null output)
   as
   
   declare @rcode int
   
   set nocount on
   
   select @rcode = 0
   
   --get category based on material and matl group
   select @gladjlvl = GLAdjInterfaceLvl, @gltrnsfrlvl = GLTrnsfrInterfaceLvl, @glprodlvl = GLProdInterfaceLvl,
   	@glmolvl = GLMOInterfaceLvl, @jcmolvl = JCMOInterfaceLvl, @glco=GLCo,
	@attachbatchreports = IsNull(AttachBatchReportsYN,'N')
   from dbo.INCO with(nolock)
   where INCo = @inco
   if @@rowcount=0
   	begin
   	select @msg = 'Invalid IN Company #.', @rcode = 1
   	goto bspexit
       	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINGLLevelGet] TO [public]
GO
