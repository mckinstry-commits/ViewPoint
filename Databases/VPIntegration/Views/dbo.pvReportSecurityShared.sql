SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[pvReportSecurityShared] AS

SELECT ISNULL(c.ReportID, t.ReportID) AS ReportID,
	ISNULL(c.RoleID, t.RoleID) AS RoleID,
	ISNULL(c.Access, t.Access) AS Access,
	CASE 
		WHEN c.ReportID IS NULL THEN 'Standard'
		WHEN t.ReportID IS NULL THEN 'Custom'
		ELSE 'Override'
	END AS Status
FROM dbo.pReportSecurityCustom AS c
FULL OUTER JOIN dbo.pReportSecurity AS t ON t.ReportID = c.ReportID 
	AND t.RoleID = c.RoleID








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/24/09
-- Description:	Instead of trigger that manages standard and custom tables
-- =============================================
CREATE TRIGGER [dbo].[vtdReportSecurityShared]
   ON  [dbo].[pvReportSecurityShared]
   INSTEAD OF DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF suser_name() = 'viewpointcs'
	BEGIN
		DELETE dbo.pReportSecurity
        FROM dbo.pReportSecurity
			INNER JOIN DELETED ON pReportSecurity.ReportID = DELETED.ReportID
				AND pReportSecurity.RoleID = DELETED.RoleID
	END

	DELETE dbo.pReportSecurityCustom
    FROM dbo.pReportSecurityCustom
		INNER JOIN DELETED ON pReportSecurityCustom.ReportID = DELETED.ReportID
			AND pReportSecurityCustom.RoleID = DELETED.RoleID


END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/24/09
-- Description:	Instead of trigger that manages standard and custom tables
-- =============================================
CREATE TRIGGER [dbo].[vtiReportSecurityShared]
   ON  [dbo].[pvReportSecurityShared]
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF suser_name() = 'viewpointcs'
	BEGIN
		INSERT INTO dbo.pReportSecurity
           (ReportID
           ,RoleID
           ,Access)
        SELECT ReportID, RoleID, Access
        FROM INSERTED
	END
	ELSE
	BEGIN
		INSERT INTO dbo.pReportSecurityCustom
           (ReportID
           ,RoleID
           ,Access)
        SELECT ReportID, RoleID, Access
        FROM INSERTED
	END

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/24/09
-- Description:	Instead of trigger that manages standard and custom tables
-- =============================================
CREATE TRIGGER [dbo].[vtuReportSecurityShared]
   ON  [dbo].[pvReportSecurityShared]
   INSTEAD OF UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE dbo.pReportSecurityCustom
		SET ReportID = INSERTED.ReportID
		,RoleID = INSERTED.RoleID
		,Access = INSERTED.Access
	FROM pReportSecurityCustom
		INNER JOIN INSERTED ON pReportSecurityCustom.ReportID = INSERTED.ReportID
			AND pReportSecurityCustom.RoleID = INSERTED.RoleID

    IF suser_name() = 'viewpointcs'
	BEGIN
		UPDATE dbo.pReportSecurity
			SET ReportID = INSERTED.ReportID
			,RoleID = INSERTED.RoleID
			,Access = INSERTED.Access
		FROM pReportSecurity
			INNER JOIN INSERTED ON pReportSecurity.ReportID = INSERTED.ReportID
				AND pReportSecurity.RoleID = INSERTED.RoleID
	END
	ELSE
	BEGIN
		INSERT INTO dbo.pReportSecurityCustom
			(ReportID
			,RoleID
			,Access)
        SELECT ReportID, RoleID, Access
        FROM INSERTED
        WHERE NOT EXISTS (
			SELECT TOP 1 1 
			FROM pReportSecurityCustom 
			WHERE INSERTED.ReportID = pReportSecurityCustom.ReportID
				AND INSERTED.RoleID = pReportSecurityCustom.RoleID)
	END

END

GO
GRANT SELECT ON  [dbo].[pvReportSecurityShared] TO [public]
GRANT INSERT ON  [dbo].[pvReportSecurityShared] TO [public]
GRANT DELETE ON  [dbo].[pvReportSecurityShared] TO [public]
GRANT UPDATE ON  [dbo].[pvReportSecurityShared] TO [public]
GRANT SELECT ON  [dbo].[pvReportSecurityShared] TO [VCSPortal]
GO
