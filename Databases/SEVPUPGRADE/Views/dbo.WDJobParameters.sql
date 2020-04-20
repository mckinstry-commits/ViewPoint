SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDJobParameters]
as 
	select	a.*, 
			b.Comparison,
			b.Operator
	from bWDJP a
	left outer join VPGridQueryParameters b on a.QueryName = b.QueryName 
											and a.Param = b.ParameterName







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************************************
* Created: HH 3/4/2014 TFS 42728 delete trigger since WDJobParameters is a joined view
* Modified: 
*
*	This trigger deletes the table bWDJP entries since its view WDJobParameters is joined
*
************************************************************************************************/
CREATE TRIGGER [dbo].[vtWDJobParametersd] 
   ON  [dbo].[WDJobParameters] 
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DELETE bWDJP
	FROM bWDJP
	INNER JOIN deleted d ON bWDJP.KeyID = d.KeyID
	where bWDJP.JobName = d.JobName
END
GO
GRANT SELECT ON  [dbo].[WDJobParameters] TO [public]
GRANT INSERT ON  [dbo].[WDJobParameters] TO [public]
GRANT DELETE ON  [dbo].[WDJobParameters] TO [public]
GRANT UPDATE ON  [dbo].[WDJobParameters] TO [public]
GO
