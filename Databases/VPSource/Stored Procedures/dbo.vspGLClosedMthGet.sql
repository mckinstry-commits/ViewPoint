SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspGLClosedMthGet    Script Date: 2/27/06 ******/
   CREATE   procedure dbo.vspGLClosedMthGet
    /******************************************************
    * Created by:	DC 02/27/06
    * Modified by:
    *
    * Returns the Validates that a month has been closed in GL
    *
    * pass in GL Co#
    * returns 0 if successful (month has been closed), 1 if not
    *******************************************************/
    @co bCompany, @lastclsdmth bMonth output
   
    as
    set nocount on
   
    declare @rcode int
   
    select @rcode = 0

	--Get the last Mth closed from GLCO
	Select @lastclsdmth = LastMthSubClsd 
	FROM GLCO
	LEFT OUTER JOIN APCO on APCO.GLCo = GLCO.GLCo
	where APCO.APCo = @co
    if @@rowcount = 0
       begin
       select @rcode = 1
       goto bspexit
       end   
   
    bspexit:
    	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspGLClosedMthGet] TO [public]
GO
