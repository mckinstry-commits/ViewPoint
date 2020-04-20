SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[vspRPCRUpdateRPRPDel]
( @ReportID int = 0,@ParameterName varchar (256), @msg varchar(256)='' output) 
/*
   * Created:  TRL 10/31/2006'
   *
   *Used in forms: 
   *
   *
   * INPUT PARAMETERS
   *     
   * OUTPUT PARAMETERS
   *   @errmsg      error message if error occurs
   * RETURN VALUE
   *   0         success
   *   1         Failure
*/
as
 set nocount on
  Declare @rcode int

  select @rcode = 0
  
  if @ReportID is null
 begin
  	select @msg = 'Missing Report ID!', @rcode = 1
  	goto vspexit
 end
  if @ParameterName is null
 begin
  	select @msg = 'Missing Parameter Name!', @rcode = 1
  	goto vspexit
 end

Begin
		Delete From dbo.RPPLShared Where ReportID = @ReportID and ParameterName = @ParameterName
		Delete From dbo.RPRPShared Where ReportID = @ReportID and ParameterName = @ParameterName
				
End

vspexit:

  	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspRPCRUpdateRPRPDel] TO [public]
GO
