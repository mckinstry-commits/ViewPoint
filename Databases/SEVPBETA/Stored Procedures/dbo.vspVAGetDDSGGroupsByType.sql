SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL, vspVAGetDDSGGroupsByType
-- Create date: 7/25/08
-- Description:	returns DDSG users depending on type
-- =============================================
CREATE PROCEDURE [dbo].[vspVAGetDDSGGroupsByType] 
	-- Add the parameters for the stored procedure here
	@grouptype tinyint 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    if @grouptype <> 0
		begin
		SELECT Name, SecurityGroup FROM DDSG (nolock)
		where GroupType = @grouptype
		order by Name
		end
	else
		begin
		SELECT Name, SecurityGroup FROM DDSG (nolock)
		order by Name
		end
		
END

GO
GRANT EXECUTE ON  [dbo].[vspVAGetDDSGGroupsByType] TO [public]
GO
