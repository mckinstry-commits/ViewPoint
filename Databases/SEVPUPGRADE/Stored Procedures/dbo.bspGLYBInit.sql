SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLYBInit    Script Date: 8/28/99 9:34:47 AM ******/
   CREATE procedure [dbo].[bspGLYBInit]
   /***********************************************************
   
    * CREATED BY:   GG  01/17/97
    * MODIFIED BY : GG  01/17/97
    *
    * USAGE:
    * Adds entries to bGLYB for all GL Accounts in bGLAC.  Used 
    * by GL Beginning Balance program to make sure that all GL Accounts                       
    * have a beginning balance entry.
    *
    * INPUT PARAMETERS
    *    glco       GL Company
    *    fyemo      Fiscal Year ending month
    *   
    * OUTPUT PARAMETERS
    *    none
    *
    *
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/ 
   
   	(@glco bCompany = 0, @fyemo bMonth, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0

   /* validate GL Company and Fiscal Year end */
   exec @rcode = bspGLFYEMOVal @glco, @fyemo, @msg
   if @rcode = 1  goto bspexit
   
   /* add an entry to bGLYB for each GL Account found in bGLAC */
   insert into bGLYB (GLCo, FYEMO, BeginBal, NetAdj, Notes, GLAcct)
   
   select @glco, @fyemo, 0, 0, null,
   	a.GLAcct from bGLAC a where a.GLCo = @glco and
   	a.GLAcct not in (select b.GLAcct from bGLYB b (nolock) where b.GLCo = @glco and b.FYEMO = @fyemo)
   
   
   bspexit:
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLYBInit] TO [public]
GO
