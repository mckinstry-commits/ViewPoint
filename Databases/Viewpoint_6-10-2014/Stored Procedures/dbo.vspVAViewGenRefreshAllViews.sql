SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		JonathanP
-- Create date: 02/23/09
-- Description:	Refreshes all of the views in DDFHShared that allow custom fields.
-- =============================================
CREATE PROCEDURE [dbo].[vspVAViewGenRefreshAllViews]
	@returnMessage varchar(512) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @returnCode int
	set @returnCode = 0
    
    declare @dynamicSqlToRefreshView varchar(50)
    
    declare viewsToRefreshCursor cursor local fast_forward for    		
		select 'exec sp_refreshview ' + ViewName from DDFHShared d
			join INFORMATION_SCHEMA.VIEWS v on d.ViewName = v.TABLE_NAME
			where ViewName is not null and AllowCustomFields = 'Y'
    
    open viewsToRefreshCursor
    
    fetch next from viewsToRefreshCursor into @dynamicSqlToRefreshView
    
    while @@fetch_status = 0
    begin
		--print 'Executing: ' + @dynamicSqlToRefreshView
		
		exec(@dynamicSqlToRefreshView)
		
		fetch next from viewsToRefreshCursor into @dynamicSqlToRefreshView    
    end
    
    close viewsToRefreshCursor
    deallocate viewsToRefreshCursor
    
vspExit:
	return @returnCode    
    
END


GO
GRANT EXECUTE ON  [dbo].[vspVAViewGenRefreshAllViews] TO [public]
GO
