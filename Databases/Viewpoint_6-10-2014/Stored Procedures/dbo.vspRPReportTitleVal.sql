SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspRPReportTitleVal]   
  (@title varchar(60) , @msg varchar(255) output)
  AS
  /* Validates All Reports in RPRTShared used in AP Company
 
  * pass ReportID
  * 
  * returns error message if error */
  set nocount on
  declare @rcode int
  select @rcode=0
  
 if @title =null
begin
  	select @msg='Title cannot be null.',@rcode=1
  	goto vspexit
end

begin
  	select @msg=Title From dbo.RPRTShared where Title=@title
	If @@rowcount = 0
	Begin
	select @msg='Report title not found. ',@rcode=1 
	end
	goto vspexit
end

vspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspRPReportTitleVal] TO [public]
GO
