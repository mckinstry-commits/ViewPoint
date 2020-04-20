SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 08/25/2008
-- Description:	Checks if the given DD Queryable Form exists.
-- =============================================
CREATE PROCEDURE [dbo].[vspDDQueryFormValidate]
	(@form varchar(30), @queryView varchar(30) = '' output, @returnMessage varchar(255) = '' output)
AS
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @returnCode int
	select @returnCode = 0			

	select @queryView = QueryView from DDQueryableViewsShared where Form = @form

	-- Make sure the form name does not already exist in DDFHShared.
    if (@queryView = '')
    begin		
		select @returnMessage = @form + ' does not exist.'					
		select @returnCode = 1
	    goto vspExit
    end       
       
vspExit:
	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspDDQueryFormValidate] TO [public]
GO
