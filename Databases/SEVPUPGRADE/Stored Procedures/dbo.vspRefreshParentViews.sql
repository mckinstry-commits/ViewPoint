SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jonathan Paullin
-- Create date: 05/05/2008
--
-- Modified: JonathanP 05/21/2008 - See issue #127092. Changed ['%' + so.name + '%'] to ['% ' + so.name + ' %'] 
--			 JonathanP 08/07/2008 - See issue #129075. Changed join clause to (sc.text like '% dbo.' + so.name + ' %' or sc.text like '% ' + so.name + ' %')
--									from (sc.text like '% ' + so.name + ' %')
--			 JonathanP 08/26/2008 - Optimized the join clause a little bit. The old join is commented out.
--			 JonathanP 08/28/2008 - Did further optimization with George and Rick to make this faster
--
-- Description:	Given a view, this procedure will refresh all the views that the given
--				view inherited from. In other words, all of the view's parent/ancestor 
--				views will be refreshed.
-- =============================================
CREATE PROCEDURE [dbo].[vspRefreshParentViews]	
	@viewToRefresh varchar(50)	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @count int

	
	select @count = COUNT(*) from sys.sysobjects so with (nolock)
			join sys.syscomments sc with (nolock) on charindex(' dbo.' + so.name + ' ', sc.text) > 0 
			or charindex(' ' + so.name + ' ', sc.text) > 0
			where object_name(sc.id) = @viewToRefresh and so.xtype = 'V' and so.name <> @viewToRefresh
			
		if (@count = 0)
		BEGIN
		   RETURN
		END	


	-- Get a cursor for the views that @viewToRefresh inherits from. Some of the views 
	-- in this list may not pertain to this view, but it is okay to refresh them as well.    
	DECLARE parentViewCursor CURSOR LOCAL FAST_FORWARD FOR
		select so.name from sys.sysobjects so with (nolock)
			join sys.syscomments sc with (nolock) on charindex(' dbo.' + so.name + ' ', sc.text) > 0 or charindex(' ' + so.name + ' ', sc.text) > 0
			--join sys.syscomments sc on (sc.text like '% dbo.' + so.name + ' %' or sc.text like '% ' + so.name + ' %')
			where object_name(sc.id) = @viewToRefresh and so.xtype = 'V' and so.name <> @viewToRefresh
	
	declare @parentViewToRefresh varchar(50)
	
	OPEN parentViewCursor
		-- Get the first parent view to fresh.
		FETCH NEXT FROM parentViewCursor INTO @parentViewToRefresh
	
		WHILE @@FETCH_STATUS = 0
			BEGIN				
				-- Refresh this parent view's parents.
				EXEC vspRefreshParentViews @parentViewToRefresh			
				--BEGIN TRY																		
				-- Refresh this parent view.
				EXEC sp_refreshview @parentViewToRefresh						
				
				PRINT 'Refreshed Parent: ' + @parentViewToRefresh								
				--END TRY
				--BEGIN CATCH
				--	RETURN @parentViewToRefresh
				--END CATCH
				-- Get the next parent view to refresh.
				FETCH NEXT FROM parentViewCursor INTO @parentViewToRefresh
			END				
			
	CLOSE parentViewCursor
	DEALLOCATE parentViewCursor
END



GO
GRANT EXECUTE ON  [dbo].[vspRefreshParentViews] TO [public]
GO
