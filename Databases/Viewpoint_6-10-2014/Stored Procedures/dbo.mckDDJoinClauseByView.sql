SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Eric Shafer
-- Create date: 5/14/2014
-- Description:	Get join clauses for a selected view/form combination.  Get valid combinations from the VP interface
--  or from DDFH.
-- =============================================
CREATE PROCEDURE [dbo].[mckDDJoinClauseByView] 
	-- Add the parameters for the stored procedure here
	@View Nvarchar(128) = 0, 
	@Form NVARCHAR(128)
	,@IncludeWHERE BIT
	,@IncludeORDERBY BIT
	,@Execute int = 0
	, @MaxRows BIGINT
	,@ReturnMessage VARCHAR(MAX)='' OUT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--DECLARE @View nvarchar(128), @Execute INT,@Form nVARCHAR(128)
	--SELECT @View = 'JBIN', @Execute = 1, @Form = 'JBTMBills'
	DECLARE @sql NVARCHAR(MAX), @rcode INT=0
	
	IF @View IS NULL OR @View=''
	BEGIN
		SELECT @ReturnMessage='Not a valid form/view combination',@rcode=1
		GOTO spexit
	END

	IF @Form IS NULL OR @Form =''
	BEGIN
		SELECT @ReturnMessage='Not a valid form/view combination',@rcode=1
		GOTO spexit
	END

	IF @MaxRows = 0 OR @MaxRows IS NULL
	BEGIN
		SET @MaxRows = 1000
	END

	IF NOT EXISTS(SELECT 1 FROM dbo.DDFHShared WHERE ViewName=@View AND Form= @Form)
	BEGIN
		SELECT @ReturnMessage='Not a valid form/view combination',@rcode=1
		GOTO spexit
	END
	--ELSE
	--BEGIN
	--	SET @ReturnMessage='Success'
	--	SET @rcode=0
	--END

	SELECT @sql=N'SELECT TOP '+CONVERT(NVARCHAR(MAX),@MaxRows)+' * FROM '+@View+N' '+ISNULL(JoinClause,'')
	FROM dbo.DDFHShared
	WHERE ViewName = @View AND Form = @Form
	--SELECT @sql

	IF @IncludeWHERE =1 AND @Execute = 0
	BEGIN
		SELECT @sql = @sql +' WHERE '+ ISNULL(WhereClause,'')
		FROM dbo.DDFHShared
		WHERE ViewName = @View AND Form = @Form
	END

	IF @IncludeORDERBY =1
	BEGIN
		SELECT @sql = @sql +' ORDER BY '+ ISNULL(OrderByClause,'')
		FROM dbo.DDFHShared
		WHERE ViewName = @View AND Form = @Form
	END
	
	--SELECT * FROM dbo.DDFHShared WHERE ViewName='PMSL'

	IF @rcode=0
	SET @ReturnMessage = @sql

	IF @Execute = 0
	BEGIN
		SELECT @sql AS [Query]
	END
	ELSE
	BEGIN
		EXECUTE sp_executesql @sql
	END
	spexit:
	--RETURN @rcode
	--IF @rcode = 1
	--BEGIN
	--	SELECT @ReturnMessage
	--	RETURN
	--END
	--ELSE
	--BEGIN
	--	SELECT @ReturnMessage
	--END
	
END

GO
