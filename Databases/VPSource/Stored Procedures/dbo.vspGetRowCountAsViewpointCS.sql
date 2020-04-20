SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP 
-- Create date: 04/23/09
-- Description:	This will get the row count from a select statement provided as dynamic sql. This
--				is different from bspGetRowCount because this procedure as viewpointcs access which
--				will avoid View security.
-- =============================================
CREATE PROCEDURE [dbo].[vspGetRowCountAsViewpointCS] 
	(@sqlStatement varchar(8000))	

WITH EXECUTE AS 'viewpointcs'
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    declare @returnCount int
   	       
	exec(@sqlStatement)
	select @returnCount = @@rowcount
         
vspExit:
	return(@returnCount) 
END

GO
GRANT EXECUTE ON  [dbo].[vspGetRowCountAsViewpointCS] TO [public]
GO
