SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 08/25/2008
-- Modified date: 
--		12/03/2010 Issue 140507 CJG - Changed to no longer require column named "KeyID" to indicate identity column
-- Description:	Gets the query result set for the DM After The Fact Attachments form.
-- =============================================
CREATE PROCEDURE [dbo].[vspDMGetQueryResultSet]
	-- Add the parameters for the stored procedure here
	@DDFHForm varchar(30), @whereClause varchar(512), @maxNumberOfRows int, @returnMessage varchar(512) output
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    -- Get the view to query.
    declare @queryView varchar(30)
    select @queryView = QueryView from DDQueryableViewsShared where Form = @DDFHForm and AllowAttachments = 'Y'   	    
    	       	   
	declare @selectColumns varchar(max)
	set @selectColumns = ''
	
	-- Build a string that contains all the columns to return. Example: 'APCo as [APCo], VendorGroup as [Vendor Group]'. The join
	-- on DDTCShared is used to make the column names more descriptive.
	select @selectColumns = @selectColumns + case when @selectColumns <> '' then ', ' else '' end + d.QueryColumnName + ' as [' + isnull(c.Description, d.QueryColumnName) + ']'
		from DDQueryableColumnsShared d
		JOIN DDTCShared c ON c.TableName = @queryView and c.ColumnName = d.QueryColumnName
		where d.Form = @DDFHForm and d.ShowInQueryResultSet = 'Y'	
	
	if @selectColumns <> ''
	begin
		set @selectColumns = ',' + @selectColumns
	end
	
	-- Get the identity column of the view
	declare @identityColumn varchar(128)
	exec vspDDGetIdentityColumn @queryView, @identityColumn output
	
	set @selectColumns = 'Case when UniqueAttchID is null then ''N'' else ''Y'' end as [Attachments]' + @selectColumns + 
				', UniqueAttchID, ' + @identityColumn + ', ''' + @identityColumn + ''' AS IdentityColumnName'
		
	declare @sqlString varchar(max)
	select @sqlString = 'Select top ' + CAST(@maxNumberOfRows as varchar(20)) + ' ' + @selectColumns + ' From ' + @queryView + ' ' + case when @whereClause <> '' then 'Where ' else '' end + @whereClause
	set @returnMessage = @sqlString	

	exec (@sqlString)

END






/****** Object:  StoredProcedure [dbo].[vspVACompanyCopyTableCopy]    Script Date: 12/02/2010 07:58:03 ******/
SET ANSI_NULLS ON

GO
GRANT EXECUTE ON  [dbo].[vspDMGetQueryResultSet] TO [public]
GO
