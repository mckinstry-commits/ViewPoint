SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspINMthlyRecBatchMthUpdate]
/***********************************************************************************
* CREATED BY:  TRL 10/04/05
*				GF 02/26/2010 - issue #137438
*
*
* USAGE:
* Called from IN MthlyRec
*
*
* INPUT PARAMETERS:
*   @inco             IN Company
*  
* OUTPUT PARAMETERS
*  @mth
*   @msg         error message if something went wrong
*
* RETURN VALUE:
*   0               success
*   1               fail
**************************************************************************************/
----#137438
(@inco TINYINT = 0, @mth bMonth = null, @futuremth bMonth = NULL output,
 @inma_exists CHAR(1) = 'N' OUTPUT, @msg varchar(255) output)
as
set nocount ON

declare  @rcode int ,@checkmth smalldatetime 

set @rcode = 0
----#137438
set @inma_exists = 'N'

If IsNull(@inco,0) =0
	begin
	select @msg = 'Invalid IN Co#!', @rcode = 1
	goto vspexit
	END
	

--get last month reconciled or first month with detail for default
select @mth = max(Mth) from dbo.INMA with(nolock) where INCo= @inco
If IsNull(@mth,'')= ''
	Begin
	Select @mth=min(Mth) from dbo.INDT with(nolock) where INCo = @inco
	If @@rowcount = 0
		begin
		select @msg = 'No transactions to reconcile.', @rcode=1 
		goto vspexit
		end
	else
		begin
		Select @futuremth = DateAdd(Month,1,@mth)
		end
	End
Else
	BEGIN
	----#137438
	set @inma_exists = 'Y'
	select @futuremth  = max(Mth) from dbo.INMA with(nolock) where INCo= @inco and Mth>=IsNull(@mth, Mth)
	End



vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINMthlyRecBatchMthUpdate] TO [public]
GO
