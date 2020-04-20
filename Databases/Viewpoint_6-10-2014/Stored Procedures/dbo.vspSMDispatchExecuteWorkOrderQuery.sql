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
CREATE PROCEDURE dbo.vspSMDispatchExecuteWorkOrderQuery
	@QueryKeyID			int = null,
	@Query				nvarchar(max) = null,
	@msg				nvarchar OUTPUT,

	@debug				int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	if @Query is null and @QueryKeyID is not null
	begin
		select @Query = q.Query
		from dbo.VPGridQueries q
		where q.KeyID = @QueryKeyID
	end

	if (@debug = 1)
		select @Query

	exec sp_executesql @Query

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMDispatchExecuteWorkOrderQuery] TO [public]
GO
