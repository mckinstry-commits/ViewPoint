SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/14/09
-- Description:	This procedure will return a result set containing all the IDs
--				of those attachments that have passed their retention time.
--
-- Inputs: @attachmentTypeID = The Attachment Type ID to filter on. Pass -1 for all Types.
--		   @returnMessage = The error message.
-- 
-- =============================================
CREATE PROCEDURE [dbo].[vspDMAttachmentsPastRetentionTime]
	@attachmentTypeID int, @rowCount int = 0 output, @returnMessage varchar(512) = '' output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @returnCode int
	SET @returnCode = 0
		
	-- This temp table will hold the attachment types to check. This makes the select query below faster and more readable.
	CREATE TABLE ##AttachmentTypesToCheck (AttachmentTypeID INT)			
		
	if @attachmentTypeID is null
	begin
		set @returnMessage = 'Attachment Type ID can not be null.'
		set @returnCode = 1
		goto vspExit
	end					
	
	-- Insert the attachment types into a temp table.
	if (@attachmentTypeID = -1)
	begin
		insert ##AttachmentTypesToCheck 
			select AttachmentTypeID from DMAttachmentTypesShared where MonthsToRetain is not null and MonthsToRetain > 0
	end
	else
	begin
		insert ##AttachmentTypesToCheck (AttachmentTypeID) values (@attachmentTypeID)
	end
										
	if not exists(select top 1 1 from ##AttachmentTypesToCheck)
	begin
		set @returnMessage = 'No Attachment Types exist. Please contact your system administrator.'
		set @returnCode = 1
		goto vspExit
	end
		
	-- Optimization: Store the current data time into a variable.	
	declare @currentDateTime datetime		
	set @currentDateTime = CAST(CONVERT(CHAR(11),GETDATE(),113) AS datetime)				

	select AttachmentID, OrigFileName
		from dbo.bHQAT a 
		
		-- Join the tables on the attachment type
		join dbo.DMAttachmentTypesShared t on a.AttachmentTypeID = t.AttachmentTypeID	 
		
		-- Filter on Attachment Type
		join ##AttachmentTypesToCheck c on t.AttachmentTypeID = c.AttachmentTypeID		 
		
		-- Make sure there is a valid value for the number of months to retain
		where (t.MonthsToRetain is not null and t.MonthsToRetain <> 0) and	
			  
			  --Look at today's date at midnight and subtract the number of months to retain, 
			  --then make sure that's greater than the attachment added date.			  
			  a.AddDate < dateadd(month, -t.MonthsToRetain, @currentDateTime) 			  		  	

	select @rowCount = @@rowcount 

				
vspExit:	
	drop table ##AttachmentTypesToCheck	

	return @returnCode
	
END

GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentsPastRetentionTime] TO [public]
GO
