SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[SMWorkCompletedAllCurrent]
AS
	SELECT *
	FROM dbo.SMWorkCompletedAll --It is important to put a space after the view name or else refreshing the view won't work correctly
	WHERE IsSession = 0 --This view will only ever show the records that aren't backups. That way we never end up showing a work completed record twice. This view should only ever show the KeyID once.
GO
GRANT SELECT ON  [dbo].[SMWorkCompletedAllCurrent] TO [public]
GRANT INSERT ON  [dbo].[SMWorkCompletedAllCurrent] TO [public]
GRANT DELETE ON  [dbo].[SMWorkCompletedAllCurrent] TO [public]
GRANT UPDATE ON  [dbo].[SMWorkCompletedAllCurrent] TO [public]
GO
