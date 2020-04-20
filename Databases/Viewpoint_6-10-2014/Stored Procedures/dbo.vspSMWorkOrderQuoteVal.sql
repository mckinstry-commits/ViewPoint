SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspSMWorkOrderQuoteVal]
-- =============================================
-- Author:		Scott Alvey (plagerized from Jacob Van Houten)
-- Create date: 02/21/13
-- Modified:    
-- Description:	SM Work Order Quote validation
-- =============================================
	@SMCo bCompany
	, @WorkOrderQuote varchar(15)
	, @WorkOrderQuoteStatus char(1) = NULL OUTPUT
	, @WorkOrderQuoteSite varchar(20) = NULL OUTPUT
	, @HasQuoteScopeTasks bYN = NULL OUTPUT
	, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company!'
		RETURN 1
	END
	
	IF @WorkOrderQuote IS NULL
	BEGIN
		SET @msg = 'Missing SM Work Order Quote!'
		RETURN 1
	END
	
	-- Set Work order quote info. 
	SELECT @msg = [Description]
	FROM dbo.SMWorkOrderQuote
	WHERE SMWorkOrderQuote.SMCo = @SMCo AND SMWorkOrderQuote.WorkOrderQuote = @WorkOrderQuote

	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Work Order Quote has not been setup.'
		RETURN 1
	END

	SELECT 
		@WorkOrderQuoteStatus = [Status]
		, @WorkOrderQuoteSite = ServiceSite
	FROM dbo.SMWorkOrderQuoteExt
	WHERE SMCo = @SMCo AND WorkOrderQuote = @WorkOrderQuote

	SELECT 
		Top 1 1
	FROM
		SMWorkOrderQuote q
	JOIN
		SMServiceItems s on
			q.SMCo = s.SMCo
			and q.ServiceSite = s.ServiceSite
	JOIN
		SMEntity e on
			q.SMCo = e.SMCo
			and q.WorkOrderQuote = e.WorkOrderQuote
	WHERE
		q.SMCo = @SMCo
		and q.WorkOrderQuote = @WorkOrderQuote
		and q.ServiceSite = @WorkOrderQuoteSite
		and s.ServiceItem in (select ServiceItem from SMRequiredTasks where SMCo = @SMCo and EntitySeq = e.EntitySeq)
		
	IF @@rowcount = 1
    BEGIN
		SET @HasQuoteScopeTasks = 'Y'
    END
	ELSE
	BEGIN
		SET @HasQuoteScopeTasks = 'N'
	END

    RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderQuoteVal] TO [public]
GO
