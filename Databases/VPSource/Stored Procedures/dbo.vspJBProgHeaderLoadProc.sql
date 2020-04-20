SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc dbo.vspJBProgHeaderLoadProc
  
    /****************************************************************************
     * CREATED BY: kb 8/3/4
     * MODIFIED By : 
     *               
     *
     * USAGE: This procedure is called to default JBIN fields and derives from 
     * VP5x stored proc vspJBProgHeaderLoadProc and bspJBCOProgressInfoGet
     *
     *
     *  INPUT PARAMETERS
     *	@jbco	    = Company
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs
     * RETURN VALUE
     *   0         success
     *   1         Failure
     ****************************************************************************/
    (@jbco bCompany, @arco bCompany output, @custgrp bGroup output, @arglco bCompany output,
     @jcglco bCompany output, @EditProgOnBothYN bYN output,
     @LastMthSubClsd bMonth output, @autoseqinv bYN output, @msg varchar(255) output)
  
    as
    set nocount on
  
    /*generic declares */
    declare @rcode int
  
    select @rcode=0
  
    select @EditProgOnBothYN = EditProgOnBothYN, @autoseqinv = AutoSeqInvYN
    from bJBCO
    where JBCo = @jbco
    if @@rowcount = 0
      begin
      select @msg = 'Invalid JB Company', @rcode = 1
      goto bspexit
      end
  
    select @jcglco = GLCo,  @arco = ARCo
    from bJCCO
    where JCCo = @jbco
    if @@rowcount = 0
      begin
      select @msg = 'JB Company not setup in JC', @rcode = 1
      goto bspexit
      end
  
    select @LastMthSubClsd = LastMthSubClsd
    from bGLCO
    where GLCo = @jcglco
    if @@rowcount = 0
      begin
      select @msg = 'Invalid JC GL Company', @rcode = 1
      goto bspexit
      end
  
    select @arglco = GLCo
    from bARCO
    where ARCo = @arco
    if @@rowcount = 0
      begin
      select @msg = 'Invalid AR Company', @rcode = 1
      goto bspexit
      end
  
    select @custgrp = CustGroup
    from bHQCO
    where HQCo = @arco
    if @@rowcount = 0
      begin
      select @msg = 'AR company not setup in HQ', @rcode = 1
      goto bspexit
      end
  
   bspexit:
    	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspJBProgHeaderLoadProc] TO [public]
GO
