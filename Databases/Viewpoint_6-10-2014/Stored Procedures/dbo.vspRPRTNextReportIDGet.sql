SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPRTNextReportIDGet] 
  /*Created - Terrylis 10/30/2006, */
  (@vcsuser varchar(1)='N' , @nextreportid int = 0 output, @msg varchar(255) output)
  AS
  /* Get's next report id in frmRPRT based on vcsuser
  *
  *  @vcsuser
  *  @nextreportid
  *
  * pass net ReportID
  * 
  * returns error message if error */
  set nocount on
  declare @rcode int
  select @rcode=0
  
 if @vcsuser = null
begin
  	select @msg= 'VCS User type cannot be null',@rcode=1
  	goto vspexit
end

If @vcsuser = 'Y' or suser_name() = 'viewpointcs'
BEGIN
	select  @nextreportid = IsNull(Max(ReportID),0)+1 From  dbo.RPRT  Where ReportID <= 9999
	If @nextreportid >9999 
		BEGIN
  			select @msg = 'Next Report ID has exceded 9,999.', @rcode = 1  
			goto vspexit
		END
 END

If @vcsuser = 'N' or suser_name() <> 'viewpointcs'
BEGIN
	select  @nextreportid=IsNull(Max(ReportID),9999)+1  From  dbo.RPRTc  Where ReportID >= 10000
	if @@rowcount = 0
		Begin
  			select @msg = 'Error getting next Report ID', @rcode = 1
			goto vspexit
		End
	If @nextreportid >99999
		Begin
  			select @msg = 'Next Report ID has exceded 99,999.', @rcode = 1  
			goto vspexit
		End
END

 vspexit:
	if @rcode <> 0 
	select @msg = @msg + char(13) + char(10) + ' [vspRPRTNextReportIDGet]'
  	return @rcode
  
 



GO
GRANT EXECUTE ON  [dbo].[vspRPRTNextReportIDGet] TO [public]
GO
