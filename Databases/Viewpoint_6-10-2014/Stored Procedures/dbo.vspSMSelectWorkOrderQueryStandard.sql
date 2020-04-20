SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 5/07/2013
-- Description:	SM trips for Dispatch
-- Modifications: 
--                5/10/13 GPT Task 49604 Added DispatchSequence to select clause.
-- =============================================
CREATE PROCEDURE dbo.vspSMSelectWorkOrderQueryStandard
	@msg				nvarchar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select	
		gridQuery.KeyID as QueryKeyID,
		gridQuery.IsStandard,
		gridQuery.Query,
		gridQuery.QueryName,
		gridQuery.QueryDescription,
		gridQuery.QueryTitle
	from
		VPGridQueries gridQuery 
			left join SMNamedDispatchBoardQuery boardQuery on boardQuery.QueryName = gridQuery.QueryName
	where gridQuery.QueryType = 3
		and IsStandard = 'Y'

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMSelectWorkOrderQueryStandard] TO [public]
GO
