SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOValWithInfo    Script Date: 8/28/99 9:34:37 AM ******/
  CREATE  proc [dbo].[vspEMWorkOrderValPartsInit]
   /***********************************************************
    * CREATED BY: TRL 10/17/07
    * MODIFIED By : 
    * USAGE: Used on EM Work Order Parts Init
    * 	Validates EM WorkOrder in bEMWH and returns WO Desc
    *	and number of parts on WO from bEMWP; and 
    *	number of parts in a batch in EMBF with source EMParts, transtype A,C and 
    *	min Parts Code status for wo from EMBF
    *
    * 	Error returned if any of the following occurs:
    * 		No EMCo passed
    *		No WorkOrder passed
    *		WorkOrder not found in EMWH
    *
    * INPUT PARAMETERS:
    *	EMCo   		EMCo to validate against
    * 	WorkOrder 	WorkOrder to validate
    *
    * OUTPUT PARAMETERS:
    *	 @partscount
    *	@partsinitialized	
    *	@hourreading		

    * RETURN VALUE:
    *	0		success
    *	1		Failure
    *****************************************************/
   
   (@emco bCompany = null,
   @workorder bWO = null,
   @partscount smallint = null output,
   @partsinitialized smallint = null output,
   @partsstatuscode varchar(10) = null output,
   @msg varchar(255) output)
   
   as
   set nocount on
   
declare @rcode int--, @department bDept
select @rcode = 0
   
if @emco is null
begin
  	select @msg = 'Missing EM Company!', @rcode = 1
   	goto vspexit
end

if @workorder is null
begin
	select @msg = 'Missing Work Order!', @rcode = 1
	goto vspexit
end

--Validate Work Order   
select @msg = Description
from dbo.EMWH with (nolock)
where EMCo = @emco and WorkOrder = @workorder
if @@rowcount = 0
begin
	select @msg = 'Work Order not on file!', @rcode = 1
   	goto vspexit
end
   
--Total Parts On Work Order
select @partscount = count(*)
from dbo.EMWP with (nolock)
where EMCo = @emco and WorkOrder = @workorder
Group by EMCo,WorkOrder

--Total parts in WO Parts Posting Batch
select @partsinitialized = count(*), @partsstatuscode = Isnull(min(PartsStatusCode),'')
from dbo.EMBF with (nolock)
where Co = @emco and WorkOrder = @workorder and Source = 'EMParts' and BatchTransType In ('A','C')
Group by Co,WorkOrder
   
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMWorkOrderValPartsInit] TO [public]
GO
