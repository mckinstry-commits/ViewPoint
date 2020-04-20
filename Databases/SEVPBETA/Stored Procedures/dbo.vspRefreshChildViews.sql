SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jonathan Paullin
-- Create date: 05/05/2008
--
-- Modified: JonathanP 05/21/2008 - See issue #127092. Changed ['%' + @viewToRefresh + '%'] to ['% ' + @viewToRefresh + ' %']
--			 CC 06/09/2008 - Issue #128474 - Added additional criteria for view name in syscomments.text
--			 JonathanP 08/26/2008 - Optimized procedure a little bit. I've left the older Where clause commented out.
--			 06/28/11 AL - #143887 - Added handling for failures in refreshing child views.
--           ChrisC - TK-07156 - 2011-07-28 - Added temp table usage to avoid infinite recursion
-- Description:	This procedure will refresh the given view's child views.
-- =============================================
CREATE PROCEDURE [dbo].[vspRefreshChildViews]	
	@viewToRefresh varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @tempExists bit,
        @viewAlreadyRefreshed bit

--Check if the temp table exists and if so, check if the parameter given is already in it
IF OBJECT_ID('tempdb..#tempChildViewsToRefresh') IS NOT NULL
    BEGIN
        SET @tempExists = 1
        IF EXISTS (SELECT 1 FROM #tempChildViewsToRefresh WHERE viewName = @viewToRefresh)
            SET @viewAlreadyRefreshed = 1
        ELSE
            SET @viewAlreadyRefreshed = 0
    END
ELSE
    BEGIN
        SET @tempExists = 0
        SET @viewAlreadyRefreshed = 0
    END

IF @viewAlreadyRefreshed = 0
    BEGIN
    
        IF @tempExists = 1
            INSERT INTO #tempChildViewsToRefresh (viewName) VALUES ( @viewToRefresh )
    
        -- Get a cursor for the views that inherit from @viewToRefresh.
	    DECLARE childViewCursor CURSOR LOCAL FAST_FORWARD FOR
		    select distinct(object_name(sc.id)) from sys.syscomments sc with (nolock)
		    join sys.sysobjects so with (nolock) on so.id = sc.id		
		    where so.type = 'V' and so.name <> @viewToRefresh and (charindex(' dbo.' + @viewToRefresh + ' ', sc.text) > 0 or charindex(' ' + @viewToRefresh + ' ', sc.text) > 0)
		    --where (sc.text like '% dbo.' + @viewToRefresh + ' %' or sc.text like '% ' + @viewToRefresh + ' %') and so.type = 'V' and so.name <> @viewToRefresh
    		
	    declare @childViewToRefresh varchar(50)
	    Set @childViewToRefresh = ''
    	
	    OPEN childViewCursor
		    -- Get the first child view to fresh.
		    FETCH NEXT FROM childViewCursor INTO @childViewToRefresh
    	
		    WHILE @@FETCH_STATUS = 0
			    BEGIN			
				    -- Refresh this child view.
				    BEGIN TRY
				    EXEC sp_refreshview @childViewToRefresh			
				    END TRY
				    BEGIN CATCH
				    IF (ERROR_NUMBER() >= 50000)
					    BEGIN
					    DECLARE @err VARCHAR(MAX)
					    SET @err = ERROR_MESSAGE()
					    RAISERROR (@err,15,2)
					    RETURN
					    END
				    ELSE
					    BEGIN
					    DECLARE @ErrorMsg VARCHAR(MAX)
					    SET @ErrorMsg = ERROR_MESSAGE()
					    RAISERROR(@ErrorMsg, 15, 2)
					    RETURN
					    END	
				    END CATCH
    				
				    -- Refresh this view's children.
				    EXEC vspRefreshChildViews @childViewToRefresh	
				    -- Get the next child view to refresh.
				    FETCH NEXT FROM childViewCursor INTO @childViewToRefresh
			    END				
    			
	    CLOSE childViewCursor
	    DEALLOCATE childViewCursor

    END


END




GO
GRANT EXECUTE ON  [dbo].[vspRefreshChildViews] TO [public]
GO
