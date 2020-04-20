SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 1/13/2014
-- Description:	Validation to prevent changes to phase after interface.
-- =============================================
CREATE PROCEDURE [dbo].[mckPhaseInterfaceVal] 
	-- Add the parameters for the stored procedure here
	@PMCo int = 0, 
	@Project VARCHAR(30) = 0
	,@Phase VARCHAR(30) = 0
	,@ReturnMessage VARCHAR(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here

	DECLARE @rcode INT
	SET @rcode = 0

	IF EXISTS(SELECT TOP 1 1 FROM JCCHPM 
	WHERE @PMCo = PMCo AND @Project = Project AND @Phase = Phase
		AND InterfaceDate IS NOT NULL)
	BEGIN
		SELECT @ReturnMessage = 'This phase; '+ @Phase +' has already been interfaced.  Contact accounting for changes.', @rcode = 1
		RETURN @rcode
	END
END
GO
