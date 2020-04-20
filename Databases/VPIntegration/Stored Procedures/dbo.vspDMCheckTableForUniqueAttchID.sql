SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP 
-- Modified:	Jacob VH - 10/19/2010 - #141299 Changed @tableName to varchar(128)
-- Create date: 04/28/09
-- Description:	127603 - This procedure will check if any records in a given table contain the given unique attachment id.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMCheckTableForUniqueAttchID]
	-- Add the parameters for the stored procedure here
	@tableName varchar(128), @uniqueAttachmentID varchar(60), @rowCount int output, @returnMessage varchar(255) = '' output	

WITH EXECUTE AS 'viewpointcs'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    declare @returnCode int
    set @returnCode = 0
               
    declare @rowCountTemp int
            
    declare @sql nvarchar(max)
    select @sql = N'select @rowCountTemp = count(*) from ' + @tableName + 
				  ' where UniqueAttchID is not null and UniqueAttchID = ''' + @uniqueAttachmentID + ''''
           
    declare @parmDefinition nvarchar(500) 
    set @parmDefinition = N'@rowCountTemp int output'
                    
    exec sp_executesql @sql, @parmDefinition, @rowCountTemp = @rowCount output
        
    return @returnCode
    
END

GO
GRANT EXECUTE ON  [dbo].[vspDMCheckTableForUniqueAttchID] TO [public]
GO
