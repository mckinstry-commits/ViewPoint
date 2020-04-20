SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARPostingLevelsGetForJB    Script Date: 8/28/99 9:32:36 AM ******
*
*  Modified by: kb 3/11/2 - issue #16591
*		TJL 08/13/02 - Issue #17871, The fix above broke the intended use of this procedure. To Resolve,
*					   this procedure is renamed and now dedicated to JBBatchProcess only.  AR has its own.
*		TJL 07/24/07 - Add check for Menu Company (HQCo) in JB Module Company Master
*		TRL 02/20/08 - Issue 21452
*		TRL 06/09/08 - Issue 21452 fix selecting Attach Batch Reports from JBCo
*		TJL 10/03/08 - Issue #130095, Installed (06/09/08) fix 21452 into Viewpoint. Got installed in Interim but forgot in Viewpoint
*
*  Usage:
*	Used only by JBBatchProcess form during load
*	Despite the name, this procedure is based upon JB Company and is validated as such.
*
*
***********************************************************************************************************/
   
CREATE  proc [dbo].[bspARPostingLevelsGetForJB]
   
(@jbco bCompany = 0, @GL tinyint output, @CM tinyint output, @JC tinyint output,
    @GLPayLev tinyint output, @GLCo bCompany output, @attachbatchreports bYN output, @msg varchar(60) output)
as
set nocount on

declare @rcode int, @arco bCompany

select @rcode = 0

if @jbco = 0
	begin
	select @msg = 'Missing JB Company.', @rcode = 1
	goto bspexit
	end
else
	begin
	select top 1 1 
	from dbo.JBCO with (nolock)
	where JBCo = @jbco
	if @@rowcount = 0
		begin
		select @msg = 'Company# ' + convert(varchar,@jbco) + ' not setup in JB.', @rcode = 1
		goto bspexit
		end
	end

/* Issue 21452 fix*/
select @attachbatchreports=IsNull(AttachBatchReportsYN,'N')
from dbo.JBCO with (nolock) 
where JBCo = @jbco 

/* JBCo is always same as JCCo, therefore Get ARCo from JCCo */
select @arco = ARCo
from dbo.JCCO with (nolock) 
where JCCo = @jbco
If @@rowcount = 0
	begin
	select @msg = 'Company# ' + convert(varchar,@jbco) + ' not setup in JC.'
	goto bspexit
	end

/* Get ARCo Interface levels for this JBCo */
select @GLCo=GLCo, @GL = GLInvLev, @CM = CMInterface, @JC = JCInterface,
      @GLPayLev=GLPayLev 
from dbo.ARCO with (nolock)
where ARCo = @arco
if @@rowcount = 0
	begin
	select @msg = 'Error getting AR Interface level information.', @rcode=1
	goto bspexit
	end

bspexit:
if @rcode <> 0 select @msg = @msg
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARPostingLevelsGetForJB] TO [public]
GO
