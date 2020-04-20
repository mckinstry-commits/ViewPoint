SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspINMOCloseMOsGet]
(@co int = 0 , @mth smalldatetime = null, @batchid int=0, @msg varchar(255) = null output) 

/********************************
* Created: TL 10/23/05  
* Modified:	
*
* Called 
*
*
* Input:
*	none
*
* Output:
*	resultset - current report type information
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
as
	
set nocount on
	
declare @rcode int
	
select @rcode = 0
  
  if @co is null
  	begin
  	select @msg = 'Missing IN Co#!', @rcode = 1
  	goto vspexit
  	end
  
  if  @mth is null
  	begin
  	select @msg = 'Missing Batch Month!', @rcode = 1
  	goto vspexit
  	end
  
  if  @batchid is null
  	begin
  	select @msg = 'Missing Batch ID#!', @rcode = 1
  	goto vspexit
  	end
  

-- resultset of current Report Types --
select b.JCCo as [JC Co], b.Job as [Job], j.Description as [Job Desc], b.MO as [Matl Order], b.Description as [Matl Order Desc], b.RemainCost as [Remaining Cost]
from dbo.INXB b with(nolock)
left join dbo.JCJM j with(nolock)on j.JCCo=b.JCCo and j.Job=b.Job
where b.Co = @co  and Mth =  @mth and BatchId = @batchid 
 order by b.JCCo, b.Job


vspexit:
--If @rcode <> 0 
--	select @msg = @msg + Char(13) + Char(10) + '[vspINMOCloseMOsGet]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINMOCloseMOsGet] TO [public]
GO
