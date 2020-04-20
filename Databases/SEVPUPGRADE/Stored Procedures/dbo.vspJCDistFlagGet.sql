SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    procedure [dbo].[vspJCDistFlagGet]
/***********************************************************
 * Created By:	DANF 02/28/2005
 * Modified By:	
 *
 *
 * USAGE:
 * Used by JC Batch validation to return interface status. 
 * 
 *
 * INPUT PARAMETERS
 * JCCo
 * source
 * Month
 * BatchID
 *
 * OUTPUT PARAMETERS
 * GL Close    
 * IN Distribution
 *
 * RETURN VALUE
 * 0 = success, 1 = failure
 *****************************************************/ 
(@jcco bCompany, @source bSource, @mth smalldatetime,
 @batchid bBatchID, @gldist bYN output, @indist int output, 
 @showprojection bYN output, @msg varchar(255) output)

as
set nocount on

declare @rcode int

select @rcode = 0, @msg='', @gldist = 'N', @showprojection = 'N', @indist = 0

if @jcco is null
	begin
	select @msg = 'Missing Job Cost Company!', @rcode = 1
	goto bspexit
	end

if isnull(@source,'') = ''
	begin
	select @msg = 'Missing Source!', @rcode = 1
	goto bspexit
	end

if @mth is null 
	begin
	select @msg = 'Missing Batch Month!', @rcode = 1
	goto bspexit
	end

if @batchid is null 
	begin
	select @msg = 'Missing Batch ID!', @rcode = 1
	goto bspexit
	end

If @source = 'JC RevProj' Or @source = 'JC Projctn' Or @source = 'JC Progres'
	set @gldist = 'N'	
else
	set @gldist = 'Y'

If @source = 'JC Projctn' 
 set @showprojection = 'Y'

If @source = 'JC Close'  and exists (select top 1 1 from dbo.JCCO with (nolock) where JCCo=@jcco and GLCloseLevel = 0)
	set @gldist = 'N'

If @source = 'JC MatUse'
	begin
		select @indist = isnull(sum(INCo) ,0)
		from dbo.JCCB with (nolock) 
		where Co=@jcco and BatchId=@batchid and INCo is not null
	end

bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCDistFlagGet] TO [public]
GO
