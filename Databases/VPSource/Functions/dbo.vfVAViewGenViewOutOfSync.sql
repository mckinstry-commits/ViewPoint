SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jonathan Paullin 
-- Create date: 02/17/2009
-- Description:	#129835. This function will see if the given view's definition in the database matches our
--				security settings in DDSLShared
-- =============================================
CREATE FUNCTION [dbo].[vfVAViewGenViewOutOfSync]
(
	-- Add the parameters for the function here
	@viewname varchar(60), @tablename varchar(60) = null
)
RETURNS char(1)
AS
BEGIN 
 	
declare @dynamicSqlQuery varchar(max)
select @dynamicSqlQuery = dbo.vfVAViewGenQuery(@viewname, @tablename)
 	
--Check if the view is in sync. 	 	
if exists(select top 1 1 from INFORMATION_SCHEMA.VIEWS with(nolock)
			  where TABLE_NAME = @viewname and 
				    lower(VIEW_DEFINITION) = replace(lower(@dynamicSqlQuery),'alter ','create '))
	return 'N'	
else
	return 'Y'			 	 	 	
	
return ''	
END

GO
GRANT EXECUTE ON  [dbo].[vfVAViewGenViewOutOfSync] TO [public]
GO
