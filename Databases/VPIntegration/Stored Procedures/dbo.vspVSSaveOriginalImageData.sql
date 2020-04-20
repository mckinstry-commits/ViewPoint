SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP 
-- Create date: 03/17/09
-- Description:	This procedure will save the original image data for a batch image.
-- =============================================
CREATE PROCEDURE [dbo].[vspVSSaveOriginalImageData]
	(@batchID int, @imageID int, @originalFileName varchar(512), @originalImageData varbinary(max), @returnMessage varchar(512) = null output)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    declare @returnCode int
    set @returnCode = 0
    
    if not exists (select top 1 1 from bVSBD where BatchId = @batchID and ImageID = @imageID)
    begin
		set @returnMessage = 'Could not save original image data. The image''s record does not exist.'
		set @returnCode = 1
		goto vspExit
    end
    
    -- Store the original image data.
    update bVSBD 
			set OriginalFileName = @originalFileName, OriginalImageData = @originalImageData 
			where BatchId = @batchID and ImageID = @imageID           
    
vspExit:
    return @returnCode
    
END

GO
GRANT EXECUTE ON  [dbo].[vspVSSaveOriginalImageData] TO [public]
GO
