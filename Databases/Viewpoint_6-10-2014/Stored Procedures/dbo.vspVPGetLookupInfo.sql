SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************
* Created: Chris G 3/17/11 (TK-02695)
* Modified: 
*
* Gets the lookup info for GridPartConfiguration;s
*
* Inputs:
*	@lookup		Lookup name from DDLH
*
* Outputs: 
*	Data from DDLH
*
* Return code:
*	0 = success, 1 = failure
*
**************************************/
CREATE PROCEDURE [dbo].[vspVPGetLookupInfo] 
	@lookup varchar(30)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT Seq, ColumnName, ColumnHeading, Datatype, InputType, InputLength, InputMask, Prec 
	FROM DDLDShared
	WHERE Lookup = @lookup
	ORDER BY Seq
	
    -- Insert statements for procedure here
	SELECT FromClause, WhereClause, JoinClause, OrderByColumn, GroupByClause 
	FROM DDLHShared 
	WHERE Lookup = @lookup
END

GO
GRANT EXECUTE ON  [dbo].[vspVPGetLookupInfo] TO [public]
GO
