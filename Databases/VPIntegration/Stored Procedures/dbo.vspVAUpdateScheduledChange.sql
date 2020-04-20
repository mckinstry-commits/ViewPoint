SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jonathan Paullin
-- Create date: 12/03/2009
-- Description:	This procedure will update a scheduled change.
-- =============================================

CREATE PROCEDURE [dbo].[vspVAUpdateScheduledChange]
	(@keyID int, @updateStatus nvarchar(30), @updateMessage nvarchar(max), @errorMessage varchar(512) output) 
AS
BEGIN	
	SET NOCOUNT ON;   

	declare @returnCode int;
	select @returnCode = 0;		   								  
					   										   								   			
	UPDATE VAScheduledChanges 
		SET AppliedOn = GETDATE(), UpdateStatus = @updateStatus, UpdateMessage = @updateMessage 
		WHERE KeyID = @keyID;	
		
	return @returnCode;
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVAUpdateScheduledChange] TO [public]
GO
