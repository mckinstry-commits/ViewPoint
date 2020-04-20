SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBPOItemValWithInfo]
/***********************************************************************
* CREATED BY:	TJL 01/11/08
* MODIFIED BY:  TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*	
* USAGE:
* Called by JB T&M Bill Line Seq to Validate PO Item.
* Returns POItem Material information to be used as defaults on form.
*
*
* INPUT PARAMETERS
*   POCo	PO Co to validate against - this is the same as the AP Co
*   PO		Purchase Order
*   POItem	PO Item to validate
*
***************************************************************************/
(@poco bCompany = 0, @po varchar(30) = null, @poitem bItem = null, @description bItemDesc output, 
	@um bUM output, @curunits bUnits output, @curunitcost bUnitCost output, @curecm bECM output,
	@msg varchar(60) output)
as

set nocount on

declare @rcode int
select @rcode = 0
   
if @poco is null
	begin
	select @msg = 'Missing PO Company.', @rcode = 1
	goto vspexit
	end
   
if @po is null
   	begin
   	select @msg = 'Missing PO.', @rcode = 1
   	goto vspexit
   	end
   
   
if @poitem is null
   	begin
   	select @msg = 'Missing PO Item#.', @rcode = 1
   	goto vspexit
   	end

select @description = Description, @msg = Description, @um = UM,
	@curunits = CurUnits, @curunitcost = CurUnitCost, @curecm = CurECM
from POIT with (nolock)
where POCo = @poco and PO = @po and POItem = @poitem
if @@rowcount=0
   	begin
   	select @msg = 'PO item does not exist.', @rcode=1
   	goto vspexit
   	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBPOItemValWithInfo] TO [public]
GO
