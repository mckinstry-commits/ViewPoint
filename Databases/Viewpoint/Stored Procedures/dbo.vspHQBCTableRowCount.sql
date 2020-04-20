SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author: EN 3/17/2010 - Created for #137429
--		 
--
-- Description:	This stored procedure is called by bspHQBCExitCheck to check for rows in a batch table.  This can not
-- be done from within bspHQBCExitCheck because of a security issue with sp_executesql.  If the user does not have security 
-- clearance to the batch table entries the select count(*) will return a false 0.  By porting this funtion to a separate 
-- stored proc we can take advantage of with execute as 'viewpointcs' to expand the scope of the search.
--
-- Return Codes:
--		0 : Column exists.
--		1 : Column does not exist.
-- =============================================
CREATE PROCEDURE [dbo].[vspHQBCTableRowCount]
	(@co as bCompany, 
	 @mth as bMonth, 
	 @batchid as bBatchID,
	 @tablename as varchar(20), 
	 @c as int output, 
	 @errmsg varchar(255) output) with execute as 'viewpointcs'

AS
BEGIN	
	SET NOCOUNT ON;
	
	declare @rc as int, @sql nvarchar(300), @paramsin nvarchar(300) 
	select @rc = 0

	select @sql = 'select @c=COUNT(*)  from ' + isnull(@tablename,'') + ' with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid'

	set @paramsin = N'@co tinyint, @mth bMonth, @batchid int, @c int output '

	EXECUTE sp_executesql @sql, @paramsin, @co, @mth, @batchid, @c output

	return @rc			
END

GO
GRANT EXECUTE ON  [dbo].[vspHQBCTableRowCount] TO [public]
GO
