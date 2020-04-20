SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVAWDJBGetEventQuery]
/**************************************************
* Created: HH 10/15/2012
* MODIFIED:	
*
* This procedure returns the flag whether or not a query is marked as event query.
*
* Inputs:
*	@QueryName		The name of the Query.
*	@QueryType		The query type
*	
*
* Output:
*	
*
* Return code:
*
****************************************************/

(@QueryName VARCHAR(50), @QueryType INT, @msg varchar(60) = null output)

AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @rcode int
	SET @rcode = 0 
	
	IF @QueryType NOT IN (SELECT DatabaseValue FROM DDCI WHERE ComboType = 'WFJBQueryType')
	BEGIN
	SET @rcode=1
	SET @msg = 'Invalid Query Type'
	RETURN @rcode
	END
	
	IF @QueryType = 0 AND @QueryName in (SELECT QueryName FROM WDQF)
	BEGIN
		SELECT TableColumn as 'ColumnName', IsKeyField as IsNotifierKeyField 
		FROM WDQF
		WHERE QueryName = @QueryName AND IsKeyField = 'Y';

		SELECT IsEventQuery 
		FROM WDQY
		WHERE QueryName = @QueryName;
	END
	ELSE IF @QueryType = 1 AND @QueryName in (SELECT QueryName FROM VPGridQueries)
	BEGIN
		
		SELECT ColumnName, IsNotifierKeyField 
		from VPGridColumns 
		where QueryName = @QueryName
		and IsNotifierKeyField = 'Y';
		
		IF @@rowcount = 0
			SELECT 'N' AS IsEventQuery
		ELSE
			SELECT 'Y' AS IsEventQuery
	END
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVAWDJBGetEventQuery] TO [public]
GO
