SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Garth Theisen
-- Create Date: 04/10/2013
-- Description:	TFS 38917 Verify that inputed view is secured by a datatype(s)
--						  and validate whether the user has access to record identified
--						  by the keystring.
--
-- Modified By: 
-- Garth Theisen 11/26/2013 TFS 68127 When determining attachment access verify each specified data-type 
--									at the table level for active security (InUse = 'Y'), 
--									not just across the board (InUseState='Y') for the given table..
-- =============================================
CREATE PROCEDURE [dbo].[vspCheckUserRecordAccess]
(
	-- Add the parameters for the function here
	@viewname varchar(60),  @keystring as VARCHAR(255), @user as VARCHAR(255)
)
AS
BEGIN

	DECLARE @SecuredTypes TABLE (DataType VARCHAR(30), InstanceColumn VARCHAR(30), QualifierColumn VARCHAR(30))
	DECLARE @InstanceColumn VARCHAR(30), @QualifierColumn VARCHAR(30)
	DECLARE @InstanceValue Char(30), @QualifierValue TinyInt

	INSERT INTO @SecuredTypes
		SELECT s.Datatype, 
			   s.InstanceColumn, 
			   s.QualifierColumn 
		FROM DDSLShared s
		INNER JOIN DDDTSecurable t On s.Datatype = t.Datatype
		WHERE s.InUse = 'Y' and s.InUseState = 'Y' and t.Secure = 'Y' and SUBSTRING(s.TableName,2,len(s.TableName)) = @viewname

	-- SELECT * FROM @SecuredTypes --Debug

	DECLARE @userHasAccess TINYINT
	-- Default the user has access, but evaluate if there is secured datatypes
	SET @userHasAccess = 1
 
	WHILE (SELECT COUNT(*) FROM @SecuredTypes) > 0 And @userHasAccess = 1
	BEGIN

		DECLARE @datatype VARCHAR(30)
		-- Iterate through each datatype that secures the subject view
		SELECT TOP 1 @datatype = DataType, @InstanceColumn = InstanceColumn, @QualifierColumn = QualifierColumn 
		FROM @SecuredTypes

		DECLARE @RecordQuery as VARCHAR(MAX)
		DECLARE @RecordDetails TABLE (Instance VARCHAR(30), Qualifier TINYINT)

		-- Dynamical generate 
		SET @RecordQuery = 'SELECT  ' + @InstanceColumn + ' as Instance, ' 
							+ @QualifierColumn + ' as Qualifier FROM ' 
							+ @viewname + ' WHERE ' + @keystring

		INSERT INTO @RecordDetails 
		EXEC(@RecordQuery)

		SELECT @InstanceValue = Instance, @QualifierValue = Qualifier FROM @RecordDetails

		IF @InstanceValue IS NOT Null  
 			BEGIN
				IF @datatype <> 'bEmployee'
					BEGIN
						-- Evaluate whether user has been provided access.
						IF NOT EXISTS (SELECT TOP 1 1 FROM DDDU            
									   WHERE Datatype = @datatype AND VPUserName = @user AND
											 Qualifier = @QualifierValue and Instance =  @InstanceValue)
						BEGIN
							  SET @userHasAccess = 0
						END
					END
				ELSE	  
					BEGIN
						-- Evaluate whether user has been provided access.
						IF NOT EXISTS ( SELECT TOP 1 1 FROM DDDU 
										WHERE Datatype = @datatype AND VPUserName = @user AND
										Qualifier = @QualifierValue AND Employee = @InstanceValue)
						BEGIN
							  SET @userHasAccess = 0
						END
					END
			END
		ELSE
			-- In the case that the instance value is null and the column allows nulls, 
			-- assume user has access, unless the column is not configured as such.
			BEGIN
				IF	COLUMNPROPERTY(OBJECT_ID(@viewname),@InstanceColumn,'AllowsNull') <> 1
				BEGIN
					SET @userHasAccess = 0
				END
			END

		-- Clear RecordDetails for next datatype
		DELETE @RecordDetails

		-- @datatype processed, remove from types to evaluate
		DELETE @SecuredTypes Where DataType = @datatype

	END

	--Return 0 if user has no access, 1 if the user has access to the record.
	RETURN(@userHasAccess)
END
GO
GRANT EXECUTE ON  [dbo].[vspCheckUserRecordAccess] TO [public]
GO
