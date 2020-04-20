SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARPostingLevelsGet    Script Date: 8/28/99 9:32:36 AM ************
*
*  Modified by: kb 3/11/2 - issue #16591
*		TJL 08/13/02 - Issue #17871, The fix above broke the intended use of this procedure. To Resolve,
*					   this procedure has been repaired and now dedicated to ARBatchUpdate only.  JB has its own.
*		TJL 07/24/07 - Add check for Menu Company (HQCo) in AR Module Company Master	
*		TRL 02/20/08 - Issue 21452
***********************************************************************************************************/
   
CREATE  proc [dbo].[bspARPostingLevelsGet]

(@arco bCompany = 0, @GL tinyint output, @CM tinyint output, @JC tinyint output,
	@GLPayLev tinyint output, @GLCo bCompany output,
	@attachbatchreports bYN output,  @msg varchar(60) output)

as
set nocount on
   
declare @rcode int

select @rcode = 0

if @arco = 0
	begin
	select @msg = 'Missing AR Company#.', @rcode = 1
	goto bspexit
	end
else
	begin
	select top 1 1 
	from dbo.ARCO with (nolock)
	where ARCo = @arco
	if @@rowcount = 0
		begin
		select @msg = 'Company# ' + convert(varchar,@arco) + ' not setup in AR.', @rcode = 1
		goto bspexit
		end
	end
   
/* Get ARCo Interface levels for this ARCo */
select @GLCo=GLCo, @GL = GLInvLev, @CM = CMInterface, @JC = JCInterface,
      @GLPayLev=GLPayLev,@attachbatchreports = IsNull(AttachBatchReportsYN,'N')
from ARCO with (nolock)
where ARCo = @arco
if @@rowcount = 0
	begin
	select @msg = 'Error getting AR Company information.', @rcode = 1
	end

bspexit:
if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspARPostingLevelsGet]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARPostingLevelsGet] TO [public]
GO
