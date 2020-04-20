SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARCashReceiptsGridFill    Script Date: 8/28/99 9:34:10 AM ******/
CREATE proc [dbo].[vspEMLocXferBatchListViewFill]
/****************************************************************************
* CREATED BY:	TJL 01/25/07	- Issue #28024, 6x Recode EMLocXferBatch
* MODIFIED BY:	chs 01/23/08	- issue #126813 add PRCo & Operator.
*				CHS 06/25/2008	- issue #128262
*
* USAGE:
* 	Fills ListView in EM Mass Location Transfer Form
*
* INPUT PARAMETERS:
*	
*
* OUTPUT PARAMETERS:
*	
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@emco bCompany, @mth bMonth, @batchid bBatchID, @jcco bCompany = null, @job bJob = null, 
	@loc bLoc = null, @category bCat = null, @dept bDept = null, @shop varchar(20) = null,
	@prco bCompany = null, @operator bEmployee = null, @includeDownEquipment bYN = 'N')
as
set nocount on
declare @rcode integer

select @rcode = 0

select distinct(Equipment), Description
from bEMEM with (nolock)
where EMCo = @emco 
	and isnull(JCCo, 0) = case when @jcco is null then isnull(JCCo, 0) else @jcco end 
	and isnull(Job, '') = case when @job is null then isnull(Job, '') else @job end
	and isnull(Location, '') = case when @loc is null then isnull(Location, '') else @loc end
	and isnull(Category, '') = case when @category is null then isnull(Category, '') else @category end
	and isnull(Department, '') = case when @dept is null then isnull(Department, '') else @dept end
	and isnull(Shop, '') = case when @shop is null then isnull(Shop, '') else @shop end
	and isnull(PRCo, '') = case when @prco is null then isnull(PRCo, '') else @prco end
	and isnull(Operator, '') = case when @operator is null then isnull(Operator, '') else @operator end
	and Type = 'E' 
--	and Status = 'A' -- #128262
	and ((@includeDownEquipment = 'N' and Status = 'A') or (@includeDownEquipment = 'Y' and Status in ('A', 'D')))
	and AttachToEquip is null
	and not exists(select 1 from bEMLB with (nolock) where Co = @emco and Mth = @mth and BatchId = @batchid
		and bEMLB.Equipment = bEMEM.Equipment)
order by Equipment
 
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMLocXferBatchListViewFill] TO [public]
GO
