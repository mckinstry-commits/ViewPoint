SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLFYEMOClosedVal    Script Date: 8/28/99 9:34:43 AM ******/
   CREATE  procedure [dbo].[bspGLFYEMOClosedVal]
   /**************************************************************
    * Created by: ??
    * Last modified by: GG 10/15/98
    *					 MV 01/31/03 - #20246 dbl quote cleanup.
    *
    * Used by GL Prior Activity form to validate a 'closed' Fiscal Year
    * Ending Month for a given GL Co#
    *
    * Inputs:
    *			@glco		GL Company
    *			@mth		Fiscal Year ending month
    *
    * Output:
    *			@beginmth	Fiscal Year beginning month
    *
    * Return:
    *			0 			success
    *			1			error
    *
    ***************************************************************/
   	(@glco bCompany = 0, @mth bMonth = null, @beginmth bMonth output, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int, @lastglmthclsd bMonth
   select @rcode = 0
   
   if @glco = 0
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   if @mth is null
   	begin
   	select @msg = 'Missing Month!', @rcode = 1
   	goto bspexit
   	end
   select @msg = 'Valid', @beginmth = BeginMth
   from bGLFY
   where GLCo = @glco and FYEMO = @mth
   if @@rowcount = 0
   	begin
   	select @msg = 'This month is not a Fiscal Year Ending month!', @rcode = 1
   	goto bspexit
   	end
   
   select @lastglmthclsd = LastMthGLClsd
   from GLCO
   where GLCo = @glco
   
   if ((@lastglmthclsd is null) or (@lastglmthclsd is not null and @mth > @lastglmthclsd))
   	begin
   	select @msg = 'Fiscal year cannot have any open months!', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLFYEMOClosedVal] TO [public]
GO
