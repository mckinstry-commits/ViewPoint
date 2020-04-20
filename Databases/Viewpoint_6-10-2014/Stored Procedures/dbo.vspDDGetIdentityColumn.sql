SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ==========================================================================================
-- Author:		Chris G
-- Create date: 12/2010
--    Modified: 1/03/10 CJG - Issue 140507 (Rejection) - Add logic to check if KeyID exists before returning it.
--
-- Description:	Retrieves the identity column name of the given table or view.  Its 
--				backward compatible with the old scheme of requiring a column named "KeyID".
--				In other words, if the table/view doesn't have an identity column (or contains
--				mutliple identity columns) it sets @identityColumnName = "KeyID" if that column 
--				exists in the table/view.  If no identity column exists and no column named "KeyID" 
--				exists, sets @identityColumnName = null.
-- ==========================================================================================
CREATE PROCEDURE [dbo].[vspDDGetIdentityColumn] (@tableOrView varchar(128), @identityColumnName varchar(128) OUTPUT, @schema varchar(128) = 'dbo')
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT @identityColumnName = COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_SCHEMA = @schema
	AND TABLE_NAME = @tableOrView
	AND COLUMNPROPERTY(object_id(TABLE_NAME), COLUMN_NAME, 'IsIdentity') = 1
	
	-- There are some views that have multiple identity columns where the actual
	-- identity column in the table behind the view is aliased as 'KeyID' in the view.
	-- In that case or a case where a legacy table/view doesn't contain a true identity column
	-- return "KeyID" as that was the old way of doing things and should allow backward compatibility.
	IF @identityColumnName IS NULL 
	BEGIN
		-- Check if the "KeyID" column exists before setting @identityColumnName.  Else, leave
		-- @identityColumnName = null
		IF EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = @tableOrView AND COLUMN_NAME = 'KeyID')
		BEGIN
			SET @identityColumnName = 'KeyID'
		END
	END	
END

GO
GRANT EXECUTE ON  [dbo].[vspDDGetIdentityColumn] TO [public]
GO
