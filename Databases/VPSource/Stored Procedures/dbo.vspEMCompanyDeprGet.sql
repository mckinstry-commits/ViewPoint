SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMGroupGet    Script Date:  ******/
CREATE proc [dbo].[vspEMCompanyDeprGet]
/********************************************************
* CREATED BY: DANF 04/04/07
* MODIFIED BY:  TRL 03/13/08 Issue 127437 When EMCO.DeprLstMnthCalc is null set to 01/01/1950
*
* USAGE:	
*
* 	Retrieves Information commonly used by EM.
*		To retrieve only GLCo & depr information
*
* INPUT PARAMETERS:
*	EM Company
*
* OUTPUT PARAMETERS:
*	GLCO from EMCO
*	DeprLastMonth from EMCO
*   DeprCostCode from EMCO
*   DeprCostType from EMCO
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/

(@emco bCompany, @emcoglco bCompany = null output, @emdeprlastmth bMonth = null output, 
 @emdeprcostcode bCostCode = null output, @emdeprcosttype bEMCType = null output,  @msg varchar(60) output) 
as 
set nocount on

declare @rcode int
select @rcode = 0

  if @emco is null
  	begin
	  	select @msg = 'Missing EM Company', @rcode = 1
  		goto vspexit
  	end
  else
	begin
		select top 1 1 
		from dbo.EMCO with (nolock)
		where EMCo = @emco
		if @@rowcount = 0
			begin
				select @msg = 'Company# ' + convert(varchar,@emco) + ' not setup in EM.', @rcode = 1
				goto vspexit
			end
	end

select	@emcoglco = e.GLCo, @emdeprlastmth = IsNull(e.DeprLstMnthCalc,'1/1/1950'), 
		@emdeprcostcode = e.DeprCostCode, @emdeprcosttype = e.DeprCostType
from dbo.EMCO e with (nolock)
where e.EMCo = @emco 
if @@rowcount = 0
	begin
	--select @msg = 'Error getting EM Common information.', @rcode = 1
	goto vspexit
	end

/*
 @batchmth bMonth, @batchid bBatchID, 
 @batchreccount int = null output,

select @batchreccount=isnull(Count(*) ,0)
from EMBF with (nolock) 
where Co = @emco and Mth = @batchmth and Source = 'EMDepr'
*/

vspexit:
--if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCompanyDeprGet] TO [public]
GO
