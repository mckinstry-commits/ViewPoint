SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJCProjGridFill]
/*****************************************
* Created By:	CHS 10/27/2008
* Modfied By:
*
* View of JC Projection Batch Calculations.
* This was created for 6.x and is used in JCProjections. 
*
*****************************************/
(@jcco bCompany, @job bJob, @gridfilter varchar(max), @orderby varchar(max), @errmsg varchar(256) output)
as
set nocount on

declare @rcode int, @query varchar(max)

select @rcode = 0

select @query = 'select * from JCPBCalc with (nolock) where '
if isnull(@gridfilter,'') = ''
	begin
	select @query = @query + '1=2'
	end
else
	begin
	select @query = @query + @gridfilter
	end

select @query = @query + 'Order By ' + @orderby


exec (@query)



vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCProjGridFill] TO [public]
GO
