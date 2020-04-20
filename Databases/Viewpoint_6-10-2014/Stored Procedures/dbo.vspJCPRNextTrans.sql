SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspJCPRNextTrans ******/
CREATE procedure [dbo].[vspJCPRNextTrans]
/*******************************************************************************
* Created by:	GF 04/13/2010 - committed budgets
* Modified by:
*
* This SP will get the next sequence from JCPR for company and month.
* Called from JC Job Committed Budget form.
*
*
* RETURN PARAMS
* Trans			next transaction number from JCPR
*
* Returns
*      STDBTK_ERROR on Error, STDBTK_SUCCESS if Successful
*
********************************************************************************/
(@jcco bCompany = null, @mth bMonth = null, @trans bigint = 0 output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

declare @tablename varchar(20)
   
set @rcode = 0
set @trans = 0
set @tablename = 'bJCPR'

---- get maximum transaction from bJCPR
select @trans = max(ResTrans)
from dbo.bJCPR with (nolock)
where JCCo=@jcco and Mth=@mth
if @@rowcount = 0 set @trans = 0
if @trans is null set @trans = 0

set @trans = @trans

---- update bHQTC
Update dbo.bHQTC Set LastTrans = @trans
where TableName = @tablename and Co = @jcco and Mth = @mth


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPRNextTrans] TO [public]
GO
