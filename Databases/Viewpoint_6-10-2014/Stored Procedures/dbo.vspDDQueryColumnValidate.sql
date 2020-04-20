SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 10/28/2008
-- Modified by:	TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
--				CG 12/09/2010 - Issue #140507 
--									1) Changed to no longer require column named "KeyID" to indicate identity column
--									2) Fixed conversion exception in when @inputType set if DOMAIN_NAME is null (last query)
-- Description:	Makes sure the specified column is queryable.
-- =============================================
CREATE PROCEDURE [dbo].[vspDDQueryColumnValidate]		
	(@queryView varchar(30), @queryColumn varchar(30), @datatype varchar(30) = '' output, 
	 @inputType tinyint output, @inputLength smallint output, @prec tinyint output, 
	 @controlType tinyint output, @comboType varchar(20) output, @returnMessage varchar(255) = '' output)
AS

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @returnCode int
	select @returnCode = 0

	if @queryColumn = ''
	begin
		select @returnMessage = 'No column specified', @returnCode = 1
		goto vspExit
	end
	
	-- Get the identity column of the table
	declare @identityColumn varchar(128)
	exec vspDDGetIdentityColumn @queryView, @identityColumn output

	if @queryColumn = @identityColumn or @queryColumn = 'UniqueAttchID'
	begin 
		select @returnMessage = @queryColumn + ' can not be specified as a column', @returnCode = 1
		goto vspExit
	end

    if not exists(select top 1 1 from sys.columns where object_id(@queryView) = [object_id] and name = @queryColumn)
    begin
		select @returnMessage = 'There is no column named ' + @queryColumn + ' in ' + @queryView, @returnCode = 1		
	    goto vspExit
    end
 
	select @datatype = case DOMAIN_NAME when 'bCompany' then 'b' + @queryColumn
										when 'bAPReference' then 'bAPRef'
										else DOMAIN_NAME end, 
		   @controlType = case DOMAIN_NAME when 'bMonth' then 10 
										   when 'bDate' then 9 
										   else 0 end,										   
		   @inputType = case when DOMAIN_NAME is null then 0 /* 0 because Don't know inputType*/
										 else null end		  	       								       
	from INFORMATION_SCHEMA.COLUMNS 		
	where TABLE_NAME = @queryView and COLUMN_NAME = @queryColumn
       
vspExit:
	return @returnCode






/****** Object:  StoredProcedure [dbo].[vspDDQueryViewValidate]    Script Date: 12/09/2010 09:45:53 ******/
SET ANSI_NULLS ON

GO
GRANT EXECUTE ON  [dbo].[vspDDQueryColumnValidate] TO [public]
GO
