SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************/
CREATE PROCEDURE [dbo].[vspPMPCOContractTypeVal] 
/*****************************************************************
* Created By:	GF 02/21/2011 TK-01735
* Modified By:	GP 03/12/2011 - V1# B03061 removed validation for fixed amount PCO Items, now done at form level
*
*
*
*	Usage: Used to validate that contract amounts are 0 for a pending
*	change order when the CONTRACT type is 'N' unchecked. 
*
*
*	Pass in: 
*	@pmco 		- PM Company
*	@project 	- PM Project
*	@pcotype	- PCO type
*	@pco		- PCO
*	@ContractType	- Contract Type
*
*	output:
*
*	returns:
*		@rcode
*
*****************************************************************/
(@pmco bCompany = null, @project bJob = null, @pcotype bDocType = null, @pco bPCO = null,
 @ContractType char(1) = NULL, @errmsg varchar(255) output)
as
set nocount on
   
declare @rcode int

set @rcode = 0
   
---- flag must not be null
if @ContractType is null
	begin
	select @errmsg = 'Contract Type flag may not be null.', @rcode = 1
	goto bspexit
	end

IF @ContractType = 'Y' GOTO bspexit



bspexit:
	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOContractTypeVal] TO [public]
GO
