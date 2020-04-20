SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/8/10
-- Description:	Validation Proc for SM Line Type
-- =============================================
CREATE PROCEDURE [dbo].[vspSMLineTypeVal]
	@LineType AS tinyint, @msg varchar(150) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT @msg = [Description]
    FROM dbo.SMLineType
    WHERE LineType = @LineType
    
    IF @@rowcount = 0
    BEGIN
		SET @msg = 'Line Type doesn''t exist.'
		RETURN 1
	END
    
    RETURN 0
END


GO
GRANT EXECUTE ON  [dbo].[vspSMLineTypeVal] TO [public]
GO
