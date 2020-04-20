SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspJBClosedMthChk]
/**************************************************************************************
* CREATED:  bc 09/18/00
* MODIFIED:	TJL 11/26/02 - Issue #17278, Check AR and JB for Closed month status.
*			GG 02/25/08 - #120107 - separate sub ledger close - use AR close month
*
* USAGE:  Checks to see whether the bill month is open in GLCo.
*         If it isn't then do not allow bill to be changed.
*
* INPUT PARAMETERS
*   JBCo      JB Co to validate against
*   Mth
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Contract
* RETURN VALUE
*   0         success
*   1         Failure
**************************************************************************************/
   
   (@jbco bCompany = 0, @billmth bMonth, @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int, @JCglco bCompany, @ARglco bCompany, @JCarco bCompany,
   	@JClastmthsubclsd bMonth, @ARlastmthsubclsd bMonth
   select @rcode = 0
   
   if @jbco is null
   	begin
    	select @msg = 'Missing JB Company!', @rcode = 1
    	goto bspexit
    	end
   
   /* Need Job Billings (Same as JCCo), JC GLCo and JC ARCo.GLCo */
   select @JCglco = GLCo, @JCarco = ARCo
   from bJCCO
   where JCCo = @jbco
   
   select @ARglco = GLCo
   from bARCO
   where ARCo = @JCarco
   
   /* Get JC Last subledger month closed */
   select @JClastmthsubclsd = LastMthSubClsd
   from bGLCO
   where GLCo = @JCglco
   
   /* Get AR Last month closed */
   select @ARlastmthsubclsd = LastMthARClsd	-- #120107 - use AR close month
   from bGLCO
   where GLCo = @ARglco
   
   /* Do compare and error */
   if @billmth <= @JClastmthsubclsd
   	begin
   	select @msg = 'Warning!  JC Subledger month is closed!', @rcode = 1
   	goto bspexit
   	end
   if @billmth <= @ARlastmthsubclsd
   	begin
   	select @msg = 'Warning!  AR Subledger month is closed!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:

   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBClosedMthChk] TO [public]
GO
