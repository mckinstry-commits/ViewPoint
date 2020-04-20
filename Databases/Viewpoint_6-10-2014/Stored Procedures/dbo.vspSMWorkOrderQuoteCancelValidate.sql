SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Scott Alvey
-- Create date: 03/26/2013
-- Description:	Cancel or Reopen a Work Order Quote
--	this proc flips the quote between two states. Either New to Canceled or Canceled to New (reopen it)
--  if the state the form thinks the record is in is the same as the state the record is really in then
--  we can move the record to the next logical step. If not, then we need to return back the current
--  record state.
--
-- Modified:	
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkOrderQuoteCancelValidate]
	@SMCo bCompany, 
	@WOQuote varchar(15),
	@Status char(1),
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result SETs from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	DECLARE @CurStatus char(1)

	SELECT 
		@CurStatus = Status
	FROM 
		SMWorkOrderQuoteExt
	WHERE 
		SMCo = @SMCo AND WorkOrderQuote = @WOQuote

	--if the record status and form status differ, or the record is approved, then we need to gracefully error out
	IF (@Status <> @CurStatus) or @CurStatus = 'A'
	BEGIN
		SET @msg = CASE
			WHEN @CurStatus = 'A' then 'Quote is Active. No change in status will be made.'
			WHEN @CurStatus = 'C' then 'Quote is already Canceled. No change in status will be made.'
			WHEN @CurStatus = 'N' then 'Quote is already Open. No change in status will be made.'
		END
	END	
	ELSE 
	BEGIN
		UPDATE SMWorkOrderQuote 
		SET DateCanceled = CASE @Status 
								WHEN 'N' THEN GetDate()
										 ELSE null 
								END
		where SMCo = @SMCo and WorkOrderQuote = @WOQuote
	END

	IF @msg IS NOT NULL
		RETURN 1

	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderQuoteCancelValidate] TO [public]
GO
