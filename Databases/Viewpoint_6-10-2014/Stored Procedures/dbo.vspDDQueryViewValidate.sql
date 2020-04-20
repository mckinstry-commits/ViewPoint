SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Modified by:	CG 12/09/2010 - Issue #140507 - Changed to no longer require column named "KeyID" to indicate identity column
-- Create date: 08/05/2008
-- Description:	Makes sure a identity column exists for a given view.
-- =============================================
CREATE PROCEDURE [dbo].[vspDDQueryViewValidate]	
	-- Add the parameters for the stored procedure here
	(@queryView varchar(30), @returnMessage varchar(255) = '' output)
AS

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @returnCode int
	select @returnCode = 0

	-- Get the identity column of the table
	declare @identityColumn varchar(128)
	exec vspDDGetIdentityColumn @queryView, @identityColumn output

    if @identityColumn is null
    begin
		select @returnMessage = 'An identity column does not exist for that view. Queryable views must have an identity column.'
		select @returnCode = 1
	    goto vspExit
    end
       
vspExit:
	return @returnCode





/****** Object:  Trigger [dbo].[vtDDQueryableViewsi]    Script Date: 12/09/2010 10:01:38 ******/
SET ANSI_NULLS ON

GO
GRANT EXECUTE ON  [dbo].[vspDDQueryViewValidate] TO [public]
GO
