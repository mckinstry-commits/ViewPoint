SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMFirstProject    Script Date: 12/11/2006 ******/
CREATE proc [dbo].[vspPMFirstProject]
/*************************************
 * Created By:	GF 12/11/2006 6.x
 * Modified By:
 *
 *
 * USAGE:
 * Called from PM to return the first project
 *
 *
 * INPUT PARAMETERS
 * @jcco			JC Company
 * @job				JC Job
 *
 * Success returns:
 *	The first job
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@jcco bCompany, @job bJob output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

---- check JCCo
if isnull(@jcco,'') = ''
	begin
   	select @msg = 'Missing the Job Cost Company', @rcode = 1
   	goto bspexit
	end

---- get the first job 
if isnull(@job,'') <> ''
	begin
	select @job=Job from JCJM with (nolock) where JCCo=@jcco and Job=@job
	if @@rowcount <> 0 goto bspexit
	end

if isnull(@job,'') = ''
	begin
	select top 1 @job= Job from JCJM with (nolock) where JCCo=@jcco
	order by JCCo, Job
	end


----select @job= Job
----from JCJM with (nolock) 
----where JCCo=@jcco and Job=@job
----if @@rowcount <> 1 select @job = ''
----
----if isnull(@job,'') = ''
----	begin
----		---- get the first job 
----		select top 1 @job= Job
----		from JCJM with (nolock) where JCCo=@jcco
----		order by JCCo, Job
----	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMFirstProject] TO [public]
GO
