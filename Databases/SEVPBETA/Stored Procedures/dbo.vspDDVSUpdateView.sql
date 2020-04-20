SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspDDVSUpdateView]
/************************************************************************
* CREATED BY: Jonathan Paullin 02/06/07
* MODIFIED BY:   JRK 01/08/07 Added LogOnMessage and LogOnMessageActive.
*				 CC 10/21/2008 - Issue #128631 Update procedure to update Show My Viewpoint tab option.
*				 RM 08/06/09 - Added Recording Framework columns
*				 CC 05/19/2011 - Added number of workcenter tabs
*				 PW 09/21/2012 - Removed Recording Framwork columns
*
* Purpose of Stored Procedure:
*
*	Update Procedure for DDVS
*           
* Notes about Stored Procedure:
* 
*	The DDVS view comes from the vDDVS table. This table has no keys/indexes and
*	it has only 1 record, so this stored procedure will update that single record's
*	values in the vDDVS.
*
* Paramters:
*
*	Pass in the parameters you want to be updated for single record in DDVS. 
*
*	@DaysToKeepLogHistory - Set to the current number of days to keep the log history.
*	@MaxLookupRows - Set to the max number of rows to return during a lookup.
*	@MaxFilterRows - Set to hold the max number of rows to return during a normal record request.
*	@LogOnMessage - Message text that can be displayed at logon.
*	@LogOnMessageActive - bYN indicating whether the LogOnMessage will be displayed at logon.
*	@ShowMyViewpoint - bYN indicating whether or not the My Viewpoint tab will be displayed.
*	@msg - Will hold an error message if an error occurs.
*
* Returns:
*	0 if successful.
*	1 and an error message if failed.
*
*************************************************************************/

    (@DaysToKeepLogHistory smallint, @MaxLookupRows int, @MaxFilterRows int, 
	 @LogOnMessage varchar(1024) = null, @LogOnMessageActive bYN = 'N', @ShowMyViewpoint bYN = 'Y',
	 @NumberOfWorkCenterTabs int = 6,
	 @ErrorMessage varchar(80) = '' output)
AS
SET NOCOUNT ON
	
	--Create the return code and set it to zero.
    DECLARE @ReturnCode int
    SET @ReturnCode = 0;

	--Do the update.
	UPDATE vDDVS SET DaysToKeepLogHistory = convert(varchar(5), @DaysToKeepLogHistory), 
				     MaxLookupRows = convert(varchar(20), @MaxLookupRows),	
					 MaxFilterRows = convert(varchar(20), @MaxFilterRows),
					 LoginMessage = @LogOnMessage, 
					 LoginMessageActive = @LogOnMessageActive, 
					 ShowMyViewpoint = @ShowMyViewpoint, 
					 NumberOfWorkCenterTabs = @NumberOfWorkCenterTabs;

	--If there is not exactly 1 record in DDVS, then the correct record may not get updated.
	IF @@rowcount <> 1
	BEGIN
		SELECT @ErrorMessage = 'Unable to update Viewpoint site settings.', @ReturnCode = 1;
		GOTO ExitLabel;
	END

ExitLabel:
	--Return 0 on success, 1 on failure.
	return @ReturnCode;
GO
GRANT EXECUTE ON  [dbo].[vspDDVSUpdateView] TO [public]
GO
