SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE        procedure [dbo].[vspRPCRUpdateRPTPInsert]
( @ReportID int = 0, @View varchar(30) = null,  @msg varchar(256)='' output) 
/*
   * Created:  TRL 07/11/2005'
   *
   *Used in forms:   RPReportLayout
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

 if @View is null
 begin
	  	select @msg = 'Missing View Name!', @rcode = 1
  		goto vspexit
 	end
--This line prevents trigger errors if Table used in main report exists in sub report
If (select Count(*) From RPTP Where ReportID = @ReportID and ViewName=@View)=0
Begin
	
	Insert into dbo.vRPTP (ReportID,ViewName)
	Select @ReportID, @View
	if @@rowcount = 0
	begin
		select @msg = 'Could not add Report ID:  ' + convert(varchar,@ReportID) + '  and View:  ' + @View, @rcode = 1
		goto vspexit
	end
End 


  vspexit:
  	return @rcode











GO
GRANT EXECUTE ON  [dbo].[vspRPCRUpdateRPTPInsert] TO [public]
GO
