SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL, 
-- Create date: 9/10/07
-- Description:	Returns the Security link data for a specific form
-- =============================================
CREATE PROCEDURE [dbo].[vspGetSecurityLink]
	-- Add the parameters for the stored procedure here
	(@form varchar(30) = NULL)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   SELECT SecurityForm, DetailFormSecurity FROM [DDFHShared]
	WHERE [Form] = @form





END

GO
GRANT EXECUTE ON  [dbo].[vspGetSecurityLink] TO [public]
GO
