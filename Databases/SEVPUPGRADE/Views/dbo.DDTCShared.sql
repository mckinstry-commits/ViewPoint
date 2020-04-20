SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
	Created by: JonathanP 01/02/2008
	Description: This view will join DDTC with INFORMATION_SCHEMA.COLUMNS and return all the columns
				 for each table in DDTH. This view was created for the DD Table Columns form.		         
*/

CREATE VIEW [dbo].[DDTCShared]
AS

SELECT t.TableName,
	   s.COLUMN_NAME AS ColumnName,
	   c.Description	   
FROM INFORMATION_SCHEMA.COLUMNS s
JOIN DDTH t ON s.TABLE_NAME = t.TableName
LEFT JOIN DDTC c ON s.TABLE_NAME = c.TableName and s.COLUMN_NAME = c.ColumnName


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
	Created: JonathanP 01/02/2008
	Description: This view will handles updates to DDTC. If a record for DDTCShared is updated
				 and that row does not exist in DDTC, then the row will be added. If already 
				 exists in DDTC, that row will then be updated.
*/	

CREATE TRIGGER [dbo].[vtuDDTCShared] on [dbo].[DDTCShared] INSTEAD OF UPDATE AS

BEGIN
SET NOCOUNT ON


-- Update any records in DDTC that have changed
UPDATE DDTC SET Description = i.Description 
	FROM DDTC c
	JOIN inserted i on c.TableName = i.TableName and c.ColumnName = i.ColumnName

-- Add any records that have been changed that do not exist yet in DDTC
INSERT INTO DDTC (TableName, ColumnName, Description)
	SELECT i.TableName, i.ColumnName, i.Description 
	FROM inserted i
	WHERE NOT EXISTS	
	(SELECT * FROM DDTC c WHERE c.TableName = i.TableName and c.ColumnName = i.ColumnName)	
	
END
GO
GRANT SELECT ON  [dbo].[DDTCShared] TO [public]
GRANT INSERT ON  [dbo].[DDTCShared] TO [public]
GRANT DELETE ON  [dbo].[DDTCShared] TO [public]
GRANT UPDATE ON  [dbo].[DDTCShared] TO [public]
GO
