SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCProjectMgrVal    Script Date: 2/12/97 3:25:08 PM ******/
CREATE proc [dbo].[bspJCProjectMgrVal]
/***********************************************************
* CREATED BY:	SE   10/2/96
* MODIFIED By : SE 10/2/96
*               JE 7/31/97 ProjMgr changed from char(30) to int
*				TV - 23061 added isnulls
*
*
* USAGE:
* validates JC project manager.
* an error is returned if any of the following occurs
* no project manager passed, or no project manager found in JCMP
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against 
*   ProjectMgr  Project manager to validate
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise name of project manager
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@jcco bCompany = 0, @projectmgr int = null, @msg varchar(60) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @jcco is null
	begin
	select @msg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end

if @projectmgr is null
	begin
	select @msg = 'Missing Project Manager', @rcode = 1
	goto bspexit
	end

select @msg = Name from JCMP with (nolock)
where JCCo = @jcco and ProjectMgr= @projectmgr
if @@rowcount = 0
	begin
	select @msg = 'Project manager not on file!', @rcode = 1
	goto bspexit
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProjectMgrVal] TO [public]
GO
