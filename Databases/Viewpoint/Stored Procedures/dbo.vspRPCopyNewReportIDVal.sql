SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [dbo].[vspRPCopyNewReportIDVal] 
  /*Created - Terrylis 06/14/2006, */
  (@ReportID int =0 ,   @msg varchar(255) output)
  AS
  /* Validates All Reports in vRPRTC used on RP Report Copy 
  *
  *  
  *
  *
  * pass ReportID
  * 
  * returns error message if error */
  set nocount on
  declare @rcode int
  select @rcode=0
  
 if @ReportID =  0
	begin
  		select @msg=isnull(@ReportID,'') + ' invalid Report ID.',@rcode=1
  		goto vspexit
	end

--Copy New report
If @ReportID >= 10000 
BEGIN
	--Check RPRTc
	select @msg=Title From dbo.vRPRTc where ReportID = @ReportID
	If @@rowcount=1 
		Begin
			select @msg='Report ID: '+convert(varchar,isnull(@ReportID,0)) + ' already exists in table RPRTc. ',@rcode=1 
			goto vspexit
		end
	
	--Check RPRPc
	select *  From dbo.vRPRPc where ReportID = @ReportID
	If @@rowcount>=1
		Begin
			select @msg='Report ID: '+convert(varchar,isnull(@ReportID,0)) + ' already has Parameter recrods in table RPRPc.',@rcode=1 
			goto vspexit
		end

	--Check RPPLc
	select * From dbo.vRPPLc where ReportID = @ReportID
	If @@rowcount>=1
		Begin
			select @msg='Report ID: '+convert(varchar,isnull(@ReportID,0)) + ' already has Parameter Lookup recocrds in table RPPLc.',@rcode=1 
			goto vspexit
		end

	--Check RPFRc
	select * From dbo.vRPFRc where ReportID = @ReportID
	If @@rowcount>=1
		Begin
			select @msg='Report ID: '+convert(varchar,isnull(@ReportID,0)) + ' already has Form Report records in table RPFRc.',@rcode=1 
			goto vspexit
		end

	--Check RPFDc
	select * From dbo.vRPFDc where ReportID = @ReportID
	If @@rowcount>=1
		Begin
			select @msg='Report ID: '+convert(varchar,isnull(@ReportID,0)) + ' already has Form Report Parameter Defaults records in table RPFDc.',@rcode=1 
			goto vspexit
		end

	--Check RPRMc
	select * From dbo.vRPRMc where ReportID = @ReportID
	If @@rowcount>=1
		Begin
			select @msg='Report ID: '+convert(varchar,isnull(@ReportID,0)) + ' already has Assigned Module records in table RPRMc.',@rcode=1 
			goto vspexit
		end

	--Check RPRS
	select * From dbo.vRPRS where ReportID = @ReportID
	If @@rowcount>=1
		Begin
			select @msg='Report ID: '+convert(varchar,isnull(@ReportID,0)) + ' already has Report Security records in table RPRS.',@rcode=1 
			goto vspexit
		end
END
 vspexit:
  	return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspRPCopyNewReportIDVal] TO [public]
GO
