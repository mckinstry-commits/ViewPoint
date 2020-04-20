SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vfPMTablesToSearch]
/********************************************
* Created By:	GF 04/07/2011 - TK-03569
* Modified By:	GF 06/21/2011 - D-02339 use views not tables
*
* returns a result set of tables to search
* called from the PM Record Relate Key Word search procedures.
*
********************************************/

(	
	@TypeOfSearch CHAR(1) = 'G'
)

RETURNS @TablesToSearch TABLE
(
	TableName	NVARCHAR(128) 
)

AS

BEGIN

	DECLARE @FormName NVARCHAR(128), @ViewName NVARCHAR(128), @TableName NVARCHAR(128)

	---- we need to get a list of forms to find base table to search on
	SELECT @FormName = MIN(Form) FROM dbo.vDDFormRelatedInfo
	WHILE @FormName IS NOT NULL
		BEGIN
			
		---- validate from form name to DDFH and get the view name
		SELECT @ViewName = ViewName
		FROM dbo.vDDFH WHERE Form = @FormName
		IF @@rowcount <> 0
			BEGIN
			
			SET @TableName = @ViewName
			
			IF @FormName = 'PMSLHeader' SET @TableName = 'SLHD'
			IF @FormName = 'PMPOHeader' SET @TableName = 'POHD'
			IF @FormName = 'PMMOHeader' SET @TableName = 'INMO'
			IF @FormName = 'PMChangeOrderRequest' SET @TableName = 'PMChangeOrderRequest'
			IF @FormName = 'PMContractChangeOrder'	SET @TableName = 'PMContractChangeOrder'
			IF @FormName = 'PMSubcontractCO' SET @TableName = 'PMSubcontractCO'
			IF @FormName = 'PMPOCO' SET @TableName = 'PMPOCO'
			IF @FormName = 'PMContractItem'	SET @TableName = 'JCCI'
			
			------ GET table from view using information_schema
			--SET @TableName = NULL
			--SELECT @TableName = v.TABLE_NAME
			--FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE v
			--WHERE v.VIEW_NAME = @ViewName
			------AND (SUBSTRING(v.TABLE_NAME,1,1) = 'b' OR SUBSTRING(v.TABLE_NAME,1,1) = 'v')
			--AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE x
			--				WHERE x.VIEW_NAME = v.VIEW_NAME) = 1

			------ 2nd try possible that the table name is another view
			--IF @TableName IS NOT NULL AND SUBSTRING(@TableName,1,1) NOT IN ('b','v')
			--	BEGIN
			--	SET @ViewName=@TableName
			--	SELECT @TableName = v.TABLE_NAME
			--	FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE v
			--	WHERE v.VIEW_NAME = @ViewName
			--	----AND (SUBSTRING(v.TABLE_NAME,1,1) = 'b' OR SUBSTRING(v.TABLE_NAME,1,1) = 'v')
			--	AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE x
			--					WHERE x.VIEW_NAME = v.VIEW_NAME) = 1
			--	END

			------ 3rd try possible that the table name is another view
			--IF @TableName IS NOT NULL AND SUBSTRING(@TableName,1,1) NOT IN ('b','v')
			--	BEGIN
			--	SET @ViewName=@TableName
			--	SELECT @TableName = v.TABLE_NAME
			--	FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE v
			--	WHERE v.VIEW_NAME = @ViewName
			--	AND (SUBSTRING(v.TABLE_NAME,1,1) = 'b' OR SUBSTRING(v.TABLE_NAME,1,1) = 'v')
			--	AND (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEW_TABLE_USAGE x
			--					WHERE x.VIEW_NAME = v.VIEW_NAME) = 1
			--	END

			---- if we still do not have a base table then we do not
			---- want to add to the @TablesToSearch. 
			------ We can add more trys later if needed.
			--IF @TableName IS NOT NULL AND SUBSTRING(@TableName,1,1) IN ('b','v')
			--	BEGIN
				---- insert the table into the @TablesToSearch
				INSERT INTO @TablesToSearch (TableName)  VALUES (@TableName)
				--END
			END
		
		
	---- next form name
	SELECT @FormName = MIN(Form) FROM dbo.vDDFormRelatedInfo WHERE Form > @FormName
	IF @@ROWCOUNT = 0 SET @FormName = NULL
	END
     
     

RETURN

END
GO
GRANT SELECT ON  [dbo].[vfPMTablesToSearch] TO [public]
GO
