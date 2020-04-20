SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP 
-- Create date: 03/17/09
-- Description:	This procedure will get the original image data for a batch image.
-- =============================================
CREATE PROCEDURE [dbo].[vspVSGetOriginalImageData]
	(@batchID int, @imageID int, @returnMessage varchar(512) = null output)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    declare @returnCode int
    set @returnCode = 0
    
    if not exists (select top 1 1 from bVSBD where BatchId = @batchID and ImageID = @imageID)
    begin
		set @returnMessage = 'Could not get original image data. The image''s record does not exist.'
		set @returnCode = 1
		goto vspExit
    end
    
    -- Store the original image data.
    select OriginalFileName, OriginalImageData from bVSBD where BatchId = @batchID and ImageID = @imageID           
    
vspExit:
    return @returnCode
    
END

GO
GRANT EXECUTE ON  [dbo].[vspVSGetOriginalImageData] TO [public]
GO
