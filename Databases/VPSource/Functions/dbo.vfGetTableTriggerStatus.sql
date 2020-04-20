SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Gil Fox
-- Create date: 08/31/2010
-- Description:	Returns the status of triggers on
-- the table parameter passed in. 
-- =============================================
CREATE FUNCTION [dbo].[vfGetTableTriggerStatus] 
(	
	-- Add the parameters for the function here
	@tcTableName NVARCHAR(128)
)
RETURNS TABLE
AS
RETURN
(
	SELECT
		name,
		status = CASE WHEN OBJECTPROPERTY (id, 'ExecIsTriggerDisabled') = 0
			THEN 'Enabled' ELSE 'Disabled' END,
		owner = OBJECT_NAME (parent_obj)
	FROM
		sysobjects
	WHERE
		type = 'TR' AND
		parent_obj = OBJECT_ID (@tcTableName)
	)



	------ Check if a table name has been passed
	----IF (@tcTableName IS NOT NULL)
	----BEGIN
	----	INSERT @result
	----		SELECT
	----			name,
	----			status = CASE WHEN OBJECTPROPERTY (id, 'ExecIsTriggerDisabled') = 0
	----				THEN 'Enabled' ELSE 'Disabled' END,
	----			owner = OBJECT_NAME (parent_obj)
	----		FROM
	----			sysobjects
	----		WHERE
	----			type = 'TR' AND
	----			parent_obj = OBJECT_ID (@tcTableName)
	----END
	----RETURN




GO
GRANT SELECT ON  [dbo].[vfGetTableTriggerStatus] TO [public]
GO
