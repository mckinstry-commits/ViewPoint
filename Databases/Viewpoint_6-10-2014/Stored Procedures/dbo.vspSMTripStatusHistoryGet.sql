SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Garth Theisen
-- Create date: 5/31/2013
-- Description:	Get status history for a SM Trip
-- Modifications: 
--                
-- =============================================
CREATE PROCEDURE dbo.vspSMTripStatusHistoryGet
	@SMTripID	int,
	@msg nvarchar OUTPUT
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--DECLARE @SMTripID AS bigint = xxx

	SELECT history.StatusValue,
		   history.StatusText,
		   history.[DateTime], 
		   history.[UserName] 
	FROM
		( 
		  -- Determine when each status was set according to max datetime
		  SELECT [SMTripID],
				 [StatusValue], 
				 [StatusText], 
				 MAX([DateTime]) AS [DateTime]
		  FROM vSMTripStatusHistory 
		  WHERE [SMTripID] = @SMTripID
		  GROUP BY [SMTripID],[StatusValue], [StatusText] ) lastStatus
		   
	-- List the user that made last modification for a given status.
	INNER JOIN vSMTripStatusHistory history 
	ON history.SMTripID = lastStatus.SMTripID AND 
	   history.[StatusValue] = lastStatus.[StatusValue] AND 
	   history.[DateTime] = lastStatus.[DateTime]
	ORDER BY history.[DateTime] Desc

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTripStatusHistoryGet] TO [public]
GO
