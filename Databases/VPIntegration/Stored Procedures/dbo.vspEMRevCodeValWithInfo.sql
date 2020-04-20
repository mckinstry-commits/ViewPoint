SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMRevCodeValWithInfo    Script Date: ******/
CREATE proc [dbo].[vspEMRevCodeValWithInfo]
   
/******************************************************
* Created By:  TJL  11/01/06 - Issue #27926:  6x Rewrite
* Modified By: 
*				
* Usage:
*	A standard validation for a revenue code from EMRC.
*	and returns flag and default information.
*
*
* Input Parameters
*	EMCo		Need company to retreive Allow posting override flag
* 	EMGroup		EM group for this company
*	RevCode		Revenue code to validate
*
* Output Parameters
*	@msg		The RevCode description.  Error message when appropriate.
*	Basis		Whether the rev code is based on Time or Work units.
*
* Return Value
*  0	success
*  1	failure
***************************************************/
   
(@emco bCompany, @emgroup bGroup, @revcode bRevCode,
@updatehrmeter bYN output, @basis char(1) output, @workum bUM output,
@msg varchar(60) output)
   
as
set nocount on

declare @rcode int
select @rcode = 0
select @updatehrmeter = 'Y'
   
if @emco is null
	begin
	select @msg= 'Missing Company.', @rcode = 1
	goto vspexit
	end

if @revcode is null
	begin
	select @msg= 'Missing Revenue Code.', @rcode = 1
	goto vspexit
	end
   
/* Check the Revenue Code table and make sure that the RevCode exists for this piece of equipment. */
select @msg = Description, @updatehrmeter = UpdateHourMeter, @basis = Basis, @workum = WorkUM
from EMRC with (nolock)
where EMGroup = @emgroup and RevCode = @revcode
if @@rowcount = 0
	begin
	select @msg = 'Revenue code not set up in EM Revenue Codes.', @rcode = 1
	goto vspexit
	end
   
vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMRevCodeValWithInfo] TO [public]
GO
