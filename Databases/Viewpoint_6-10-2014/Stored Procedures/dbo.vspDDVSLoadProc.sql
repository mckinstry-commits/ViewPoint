SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDVSLoadProc]
/************************************************************************
* CREATED BY:    Jonathan Paullin 02/07/07
* MODIFIED BY:   JRK 01/08/07 Added LogOnMessage and LogOnMessageActive.
*				 CC 10/21/2008 - Issue # 128631 - Added My Viewpoint setting
*				 RM 08/06/09 - Added Recording Framework columns	
*				 CC 05/19/2011 - Added number of work center tabs
*				 PW 09/21/2012 - Removed Recording Framwork columns
*				 CC 05/14/2013 - Added 4Projects integration fields
*				 CC 06/18/2013 - Added SendViaSmtp column
*
* Purpose of Stored Procedure:
*
*	Load Procedure for DDVS
*           
* Notes about Stored Procedure:
* 
*	The DDVS view comes from the vDDVS table. This table has no keys/indexes.
*	The table has only 1 record, so this stored proc will load that single
*	record's values.
*
* Paramters:
*
*	All the parameters are output parameters and they will be set after this
*   procedure is called. 
*
*	@LicenseLevel - Will hold the license level
*	@Version - Will hold the version number.
*	@UseAppRole - Will hold 'Y' or 'N' denoting if application security is enabled.
*	@MaxLookupRows - Will hold the max number of rows to return during a lookup.
*	@MaxFilterRows - Will hold the max number of rows to return during a normal record request.
*	@DaysToKeepLogHistory - Will hold the current number of days to keep the log history.
*	@LogOnMessage - Message text that can be displayed at logon.
*	@LogOnMessageActive - bYN indicating whether the LogOnMessage will be displayed at logon.
*	@ShowMyViewpoint - bYN indicating whether to show the My Viewpoint tab.
*	@SendViaSmtp - bYN indicating whether to show send mail via smtp.
*	@ErrorMessage - Will hold an error message if an error occurs.
*
* Returns:
*	0 if successful.
*	1 and an error message if failed.
*
*************************************************************************/

    (@LicenseLevel varchar(60) = NULL output, @Version varchar(20) = NULL output, 
	 @UseAppRole char(1) = NULL output, @MaxLookupRows int = NULL output, 
	 @MaxFilterRows int = NULL output, @DaysToKeepLogHistory smallint = NULL output, 
	 @LogOnMessage varchar(1024) =null output, @LogOnMessageActive bYN = 'N' output,
	 @ShowMyViewpoint bYN = 'Y' output, @NumberOfWorkCenterTabs int = 6 OUTPUT,
	 @SendViaSmtp bYN = 'N' OUTPUT,
	 @4PUserName nvarchar(128) = NULL OUTPUT, @4PPassword nvarchar(128) = NULL OUTPUT, 
	 @4PEnterprise nvarchar(128) = NULL OUTPUT, @4PEnterpriseId uniqueidentifier = NULL OUTPUT,
	 @ErrorMessage varchar(80) = '' output)

AS
SET NOCOUNT ON
	
	--Create the return code and set it to zero.
    declare @ReturnCode INT;
    select @ReturnCode = 0;

	--Get the single record in DDVS and assign it's values to the passed in parameters.
	select @LicenseLevel = LicenseLevel, @Version = Version, @UseAppRole = UseAppRole,
		   @DaysToKeepLogHistory = DaysToKeepLogHistory, @MaxLookupRows = MaxLookupRows, 
		   @MaxFilterRows = MaxFilterRows, @MaxFilterRows = MaxFilterRows,
		   @LogOnMessage = LoginMessage, @LogOnMessageActive = LoginMessageActive,
		   @ShowMyViewpoint = ShowMyViewpoint, @NumberOfWorkCenterTabs = NumberOfWorkCenterTabs,
		   @SendViaSmtp = SendViaSmtp,
		   @4PUserName = FourProjectsUserName, @4PPassword = FourProjectsPassword, 
		   @4PEnterprise = FourProjectsEnterpriseName, @4PEnterpriseId = FourProjectsEnterpriseId
	from dbo.vDDVS with (nolock);

	--If there is not exactly 1 record in DDVS, then the correct record may not have been used.
	if @@rowcount <> 1
	begin
		select @ErrorMessage = 'Error: DDVS information could not be retrieved.', @ReturnCode = 1;
		goto ExitLabel;
	end

ExitLabel:
     return @ReturnCode;
GO
GRANT EXECUTE ON  [dbo].[vspDDVSLoadProc] TO [public]
GO
