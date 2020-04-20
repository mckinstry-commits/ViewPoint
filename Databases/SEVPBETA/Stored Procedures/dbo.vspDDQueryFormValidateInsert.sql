SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 08/22/2008
-- Description:	Checks if the given DD Queryable Form already exists in DDFHShared.
-- =============================================
CREATE PROCEDURE [dbo].[vspDDQueryFormValidateInsert]
	(@form varchar(30), @returnMessage varchar(255) = '' output)
AS

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @returnCode int
	select @returnCode = 0

	-- Don't allow Query Forms to start with 'ud'. This will avoid possible future conflicts with custom UD forms.
	if substring(@form, 1, 2) = 'ud'
	begin
		select @returnMessage = 'DD Queryable Forms can not start with lower case ''ud''. Please choose a different name.'
		select @returnCode = 1
	    goto vspExit
	end

	-- Make sure the form name does not already exist in DDFHShared.
    if exists(select top 1 1 from DDFHShared where Form = @form)
    begin
		select @returnMessage = @form + ' already exists in DDFHShared. Please use the DDFH Form to edit ' + @form + ' or choose a different form name to use here.'
		select @returnCode = 1
	    goto vspExit
    end
       
vspExit:
	return @returnCode

GO
GRANT EXECUTE ON  [dbo].[vspDDQueryFormValidateInsert] TO [public]
GO
