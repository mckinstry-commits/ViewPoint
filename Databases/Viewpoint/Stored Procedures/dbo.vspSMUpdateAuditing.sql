SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/8/11
-- Description:	Updates auditing for a given sm company
-- Modified:
-- =============================================

CREATE PROCEDURE [dbo].[vspSMUpdateAuditing]
	@SMCo bCompany, @msg varchar(255) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @AuditFlags TABLE (AuditFlagID smallint, RelatedColumnName sysname, EnableAudit bit DEFAULT 0)

	--Retrieve all flags that pertain to SM and capture the flag's related column name
	INSERT @AuditFlags (AuditFlagID, RelatedColumnName)
	SELECT KeyID, ColumnName
	FROM dbo.vAuditFlags
		CROSS APPLY(
			SELECT CASE FlagName 
				WHEN 'SMCoSettings' THEN 'AuditCompanySettings'
				WHEN 'SMServiceCenters' THEN 'AuditServiceCenters'
				WHEN 'SMTechns' THEN 'AuditTechnicians'
				WHEN 'SMRates' THEN 'AuditRateTemplates'
				WHEN 'SMDepts' THEN 'AuditDepartments'
				WHEN 'SMWorkScopes' THEN 'AuditWorkScopes'
				WHEN 'SMStdTasks' THEN 'AuditStandardTasks'
				WHEN 'SMStdItems' THEN 'AuditStandardItems'
				WHEN 'SMCustomer' THEN 'AuditCustomers'
				WHEN 'SMWorkOrders' THEN 'AuditWorkOrders'
				WHEN 'SMAgreements' THEN 'AuditAgreements'
			END ColumnName) ColumnNames
	WHERE Module = 'SM' AND ColumnName IS NOT NULL
	
	--Update the flags based on the values set in SMCO
	UPDATE AuditFlags
	SET EnableAudit = 1
	FROM dbo.vSMCO
		UNPIVOT (EnableAuditYN FOR ColumnName IN 
			(AuditCompanySettings, AuditServiceCenters, AuditTechnicians, AuditRateTemplates, AuditDepartments, AuditWorkScopes, AuditStandardTasks, AuditStandardItems, AuditCustomers, AuditWorkOrders, AuditAgreements)) Unpvt
		INNER JOIN @AuditFlags AuditFlags ON Unpvt.ColumnName = AuditFlags.RelatedColumnName
	WHERE SMCo = @SMCo AND EnableAuditYN = 'Y'
	
	--Remove the entries needed to prevent auditing
	DELETE vAuditFlagCompany
	FROM dbo.vAuditFlagCompany
		INNER JOIN @AuditFlags AuditFlags ON vAuditFlagCompany.AuditFlagID = AuditFlags.AuditFlagID AND vAuditFlagCompany.AuditCo = @SMCo
	WHERE AuditFlags.EnableAudit = 0
	
	--Insert the entries needed to allow auditing
	INSERT dbo.vAuditFlagCompany (AuditCo, AuditFlagID)
	SELECT @SMCo, AuditFlags.AuditFlagID
	FROM @AuditFlags AuditFlags
		LEFT JOIN dbo.vAuditFlagCompany ON AuditFlags.AuditFlagID = vAuditFlagCompany.AuditFlagID AND vAuditFlagCompany.AuditCo = @SMCo
	WHERE vAuditFlagCompany.KeyID IS NULL AND AuditFlags.EnableAudit = 1

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMUpdateAuditing] TO [public]
GO
