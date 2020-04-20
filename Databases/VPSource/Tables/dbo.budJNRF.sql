
EXEC sp_settriggerorder N'[dbo].[vtbudJNRF_Audit_Delete]', 'last', 'delete', null
GO

EXEC sp_settriggerorder N'[dbo].[vtbudJNRF_Audit_Insert]', 'last', 'insert', null
GO

EXEC sp_settriggerorder N'[dbo].[vtbudJNRF_Audit_Update]', 'last', 'update', null
GO
