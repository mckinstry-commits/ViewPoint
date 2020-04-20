SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lane Gresham
-- Create date: 02-04-11
-- Description:	Validation for Scope Priority
-- =============================================
CREATE PROCEDURE [dbo].[vspSMScopePriorityVal]
	@PriorityName varchar(10), @msg varchar(60) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @msg = [Description]
	FROM dbo.SMScopePriority
	WHERE PriorityName = @PriorityName

	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Priority doesn''t exist.'
		RETURN 1
	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMScopePriorityVal] TO [public]
GO
