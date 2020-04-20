SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[bspJCRevProjContractInJCIRCheck]
/***********************************************************
* CREATED BY:   DANF 02/24/2005
* MODIFIED By : 
*
* USAGE:
* 	Checks for Current Contract in JC Revenue Projections in any JCIR Batch.
*
*
*
* INPUT PARAMETERS
*   JCCo, Contract, BatchId, Month, Actual Date, error msg
*
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Phase
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @contract bJob = null, @batch bBatchID = 0,
 @mth bMonth = null, @actualdate bDate = null, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @otherbatch bBatchID, @othermth bMonth

select @rcode = 0, @otherbatch = 0

----select @msg = convert(varchar(20),@mth) + ' , ' + convert(varchar(20),@actualdate)
----select @rcode = 1
----goto bspexit

if @jcco = 0
	begin
	select @msg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end

if @contract is null
	begin
	select @msg = 'Missing Contract!', @rcode = 1
	goto bspexit
	end

if @mth is null
	begin
	select @msg = 'Missing Month!', @rcode = 1
	goto bspexit
	end

if @actualdate is null
	begin
	select @msg = 'Missing Actual Date!', @rcode = 1
	goto bspexit
	end


if exists(select top 1 1 from dbo.bJCIR with (nolock) where Co=@jcco and Contract=@contract
				and (Mth<>@mth or (BatchId<>@batch and Mth=@mth)))
	begin
	select @otherbatch = BatchId, @othermth = Mth
	from dbo.bJCIR with (nolock) where Co=@jcco and Contract=@contract and (Mth<>@mth or (BatchId<>@batch and Mth=@mth))
	select @msg = 'Warning: Contract ' + isnull(@contract,'') + ' exists in batch ' + isnull(convert(varchar(8),@otherbatch),'') + 
				' in month of ' + isnull(convert(varchar(12),@othermth),'') + '', @rcode = 1
	goto bspexit
	end


if exists(select top 1 1 from dbo.bJCID with (nolock) where JCCo=@jcco and Contract=@contract 
			and Mth>=@mth and TransSource='JC RevProj' and JCTransType='RP'and ActualDate>=@actualdate)
	begin
	select @msg='Contract ' + isnull(@contract,'') + ' has future projections - will be deleted when batch is posted!', @rcode=2
	goto bspexit
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCRevProjContractInJCIRCheck] TO [public]
GO
