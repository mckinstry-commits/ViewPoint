SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

-- =============================================
-- Author:		Scott Alvey
-- Create date: 04/18/2013
-- Modified:
-- Description:	Validates an SM Required Task
-- Modified:	06/11/13 - LDG - Added @ServiceableItem as an output.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMRequiredTaskVal]
	@SMCo bCompany, 
	@EntitySeq int, 
	@Task int, 
	@MustExist bYN,
	@ServiceSite varchar(20) = null OUTPUT,
	@ServiceableItem varchar(20) = null OUTPUT,
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN

	SET NOCOUNT ON
	
	SELECT @msg = 
	CASE 
		WHEN @SMCo IS NULL THEN 'Missing SM Company!'
		WHEN @EntitySeq IS NULL THEN 'Missing Entity Seq!'
		WHEN @Task IS NULL THEN 'Missing Required Task!'
	END
	
	IF @msg IS NOT NULL
	BEGIN
		RETURN 1
	END
	ELSE
	BEGIN

		SELECT @ServiceSite = e.EntityServiceSite, @ServiceableItem = t.ServiceItem, @msg = t.[Name]			
		FROM dbo.SMEntityExt e
		LEFT OUTER JOIN dbo.SMRequiredTasks t ON t.SMCo = e.SMCo
			AND t.EntitySeq = e.EntitySeq
			AND t.Task = @Task
		WHERE e.SMCo = @SMCo
			AND e.EntitySeq = @EntitySeq

	END
	
	IF @MustExist = 'Y' and @msg is null
	BEGIN
		SET @msg = 'Task has not been setup in SM Required Tasks.'
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMRequiredTaskVal] TO [public]
GO
