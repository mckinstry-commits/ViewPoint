SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    PROCEDURE [dbo].[bspPMPCOIntExtFlagVal] 
   /*****************************************************************
    * Created By:	GF 01/12/2004
    * Modified By:	
    *
    *
    *
    *	Usage: Used to validate that contract amounts are 0 for a pending
    *	change order when the internal-external flag is 'I' for internal. 
    *
    *
    *	Pass in: 
    *	@pmco 		- PM Company
    *	@project 	- PM Project
    *	@pcotype	- PCO type
    *	@pco		- PCO
    *	@intext 	- Internal/External flag
    *
    *	output:
    *
    *	returns:
    *		@rcode
    *
    *****************************************************************/
   (@pmco bCompany = null, @project bJob = null, @pcotype bDocType = null, @pco bPCO = null,
    @intext char(1) = null, @errmsg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   -- flag must be 'I' or 'E'
   if @intext is null
   	begin
   	select @errmsg = 'Internal/External flag must be (I) or (E).', @rcode = 1
   	goto bspexit
   	end
   if @intext not in ('I','E')
   	begin
   	select @errmsg = 'Internal/External flag must be (I) or (E).', @rcode = 1
   	goto bspexit
   	end
   
   if isnull(@intext,'') = 'E' goto bspexit
   -- all pco items must be flagged as fixed
   if exists(select * from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype 
   			and PCO=@pco and (FixedAmountYN = 'N' or isnull(FixedAmount,0) <> 0))
   	begin
   	select @errmsg = ' Can only change PCO to internal when all PCO Items are flagged as fixed and fixed amount is zero.', @rcode = 1
   	goto bspexit
   	end
   
   -- -- all pco items must have zero fixed amount
   -- if exists(select * from bPMOI where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and FixedAmount <> 0)
   -- 	begin
   -- 	select @errmsg = 'Can only change PCO to internal when PCO items are flagged as fixed and fixed amount is zero.', @rcode = 1
   -- 	goto bspexit
   -- 	end
   
   
   bspexit:
   	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPCOIntExtFlagVal] TO [public]
GO
