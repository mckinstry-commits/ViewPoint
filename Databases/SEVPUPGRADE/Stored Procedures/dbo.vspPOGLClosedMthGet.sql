SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPOGLClosedMthGet    Script Date: 2/27/06 ******/
   CREATE   procedure [dbo].[vspPOGLClosedMthGet]
    /******************************************************
    * Created by:	DC 02/27/06
    * Modified by:  DC 7/23/07  - added a error message to the output
    *
    * Returns the Validates that a month has been closed in GL
    *
    * pass in GL Co#
    * returns 0 if successful (month has been closed), 1 if not
    *******************************************************/
    @co bCompany, @lastclsdmth bMonth output, @errmsg varchar(255) output
   
    as
    set nocount on
   
    declare @rcode int
   
    select @rcode = 0

	--Validate the PO Company+
	IF not exists(select top 1 1 from POCO with (nolock) where POCo = @co)
		BEGIN
		select @errmsg = 'Invalid PO Company.', @rcode = 1
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
GRANT EXECUTE ON  [dbo].[vspPOGLClosedMthGet] TO [public]
GO
