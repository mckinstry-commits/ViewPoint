SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspSLGLClosedMthGet    Script Date: 2/27/06 ******/
   CREATE   procedure [dbo].[vspSLGLClosedMthGet]
    /******************************************************
    * Created by:	DC 07/24/07
    * Modified by:  
	*
    * Returns the Last Mth Sub Closed from GLCO that a month has been closed in GL
    *
    * pass in GL Co#
    * returns 0 if successful (month has been closed), 1 if not
    *******************************************************/
    @co bCompany, @lastclsdmth bMonth output, @errmsg varchar(255) output
   
    as
    set nocount on
   
    declare @rcode int
   
    select @rcode = 0

	--Validate the SL Company
	IF not exists(select top 1 1 from SLCO with (nolock) where SLCo = @co)
		BEGIN
		select @errmsg = 'Invalid SL Company.', @rcode = 1
		goto vspexit
		end

	--Get the last Mth closed from GLCO
	Select @lastclsdmth = LastMthSubClsd 
	FROM GLCO
	JOIN APCO on APCO.GLCo = GLCO.GLCo
	where APCO.APCo = @co
    if @@rowcount = 0
       begin
       select @errmsg = 'Invalid Company.', @rcode = 1
       goto vspexit
       end   
   
    vspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLGLClosedMthGet] TO [public]
GO
