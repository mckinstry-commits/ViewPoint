SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOItemValForTimeCards    Script Date: 8/28/99 9:32:44 AM ******/
CREATE   proc [dbo].[bspEMWOItemValForTimeCards]
/***********************************************************
* Created By:	JM 10/21/99
* Modified By:	JM 7/22/02 - Ref Issue 18015 - Moved return of Equip, EquipType and
*							 EquipDesc to WO validation routine.
*		JM 01-03-03 - Ref Issue 18942 Rej 1 - Return Component info only when Equip's PostCostToComp flag = 'Y' 
*		GF 01/17/2003 - issue 18942 - changed JM fix
*		TV 02/11/04 - 23061 added isnulls
*		TJL 06/05/07 - Issue #27993, Now only used in BatchSeq Val for TimeCards.  Removed ALL unnecessary Code. 
*
* USAGE: Validates an EM WorkOrder Item for an EMCo/WorkOrder and
*	     returns various info. An error is returned if any of the
*	     following occurs:
*
*   		no EMCo, WO or WOItem passed
*	    no WOItem found
*
* INPUT PARAMETERS
*   	EMCo
*   	WorkOrder
*   	WOItem to validate
*
* OUTPUT PARAMETERS
*	@comp
*	@compdesc
*	@comptypecode
*	@costcode
* 	@msg      error message if error occurs otherwise Description returned
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@emco bCompany = null, @workorder varchar(10) = null, @woitem smallint = null,
	@comp varchar(10) = null output, @compdesc varchar(30) = null output,
	@comptypecode varchar(10) = null output, @costcode bCostCode = null output,
	@msg varchar(255) output)
     
as
set nocount on
 
declare @rcode int, @equip varchar(10) 

select @rcode = 0
 
if @emco is null
 	begin
 	select @msg = 'Missing EM Company!', @rcode = 1
 	goto bspexit
 	end

if @workorder is null
 	begin
 	select @msg = 'Missing WorkOrder!', @rcode = 1
  	goto bspexit
 	end

if @woitem is null
 	begin
 	select @msg = 'Missing Workorder Item!', @rcode = 1
 	goto bspexit
 	end
     
-- Validate WOItem
select @msg = Description
from EMWI with (nolock)
where EMCo = @emco and WorkOrder = @workorder and WOItem = @woitem
if @@rowcount = 0
 	begin
 	select @msg = 'WO Item not on file!', @rcode = 1
 	goto bspexit
 	end

bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMWOItemValForTimeCards]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOItemValForTimeCards] TO [public]
GO
