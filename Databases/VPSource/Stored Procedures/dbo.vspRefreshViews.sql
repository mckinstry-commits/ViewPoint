SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************
* Create Date:	05/05/2008
* Created By:	Jonathan Paullin
* Modified By:	AR - TK-06542 - 7/19/2011 - making a call in 2008 to the DM functions to refresh
                ChrisC - TK-07156 - 2011-07-28 - Added temp table creation and teardown to avoid 
                    infinite recursion in vspRefreshChildViews
				GarthT - TK-09063 - 2011-10-17 - Run additional refresh against target view to
					catch parent view refresh updates.
*		     
* Description: This procedure will refresh the given view after refreshing all of its
				parent views. Once the parent views are refreshed and the given view is
				refreshed, the child views of the given will be refreshed.
*
* Inputs: 
*
* Outputs:
*
*************************************************/

CREATE PROCEDURE [dbo].[vspRefreshViews]	
	@viewToRefresh varchar(50)	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @DBVer SMALLINT,
			@DBVerString VARCHAR(128)
	SELECT @DBVerString = CONVERT(VARCHAR(128),SERVERPROPERTY('ProductVersion'))
	SELECT @DBVer = LEFT(@DBVerString,CHARINDEX('.',@DBVerString)-1)
	-- Refresh the view.
	EXEC sys.sp_refreshview @viewToRefresh
	
	--2011-12-14 ChrisC - Commented out until we can fix this in 6.4.6
	--IF @DBVer >= 10
	--BEGIN
	--	EXEC dbo.vspRefreshViews2008 @viewToRefresh
	--END 
	--ELSE
	--BEGIN
		CREATE Table #tempChildViewsToRefresh ( viewName VARCHAR (128) )
		
		-- Refresh the view's parent views.
		EXEC dbo.vspRefreshParentViews @viewToRefresh
		
		-- Refresh the target view, catch possible changes from parent view refresh.
		EXEC sys.sp_refreshview @viewToRefresh
		
		-- Refresh the view's child views.
		EXEC dbo.vspRefreshChildViews @viewToRefresh
		
		DROP Table #tempChildViewsToRefresh
	--END
END


GO
GRANT EXECUTE ON  [dbo].[vspRefreshViews] TO [public]
GO
