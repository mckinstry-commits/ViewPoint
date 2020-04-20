USE HRNET
go

GRANT SELECT ON [mnepto].[mvwActiveEmployees] TO nsproportaluser
GO
GRANT SELECT on mnepto.Personnel TO nsproportaluser
GRANT SELECT, INSERT, UPDATE, DELETE ON mnepto.TimeCardHistory TO nsproportaluser
GRANT SELECT, INSERT, UPDATE, DELETE ON mnepto.TimeCardManualEntries TO nsproportaluser
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.mvwTimeCardManualEntries TO nsproportaluser
GRANT SELECT on mnepto.AccrualSummary TO nsproportaluser
GRANT SELECT on [mnepto].[TimeCardAggregateView] TO nsproportaluser
GRANT EXECUTE ON [mnepto].[mfnEffectiveStartDate]  TO nsproportaluser
GRANT SELECT ON [mnepto].[mfnMyTeamPersonnel] TO nsproportaluser
GRANT SELECT ON [mnepto].[mfnMyTeamAccrualSummary] TO nsproportaluser
GRANT SELECT ON [mnepto].[mfnMyTeamTimeCardAggregateView] TO nsproportaluser
GRANT SELECT ON [mnepto].[mfnMyTeamTimeCardManualEntries] TO nsproportaluser
GRANT EXECUTE ON [mnepto].mspRecalculateAccruals  TO nsproportaluser
GRANT EXECUTE ON [mnepto].[mspSyncPersonnel]  TO nsproportaluser
GRANT EXECUTE ON [mnepto].[mspSyncDNNAccounts] TO nsproportaluser
GRANT SELECT ON mnepto.AccrualSettings TO nsproportaluser
GRANT SELECT ON [mnepto].[mvwActiveEmployees] TO nsproportaluser
GRANT SELECT ON dbo.JOBDETAIL TO nsproportaluser
GRANT SELECT ON dbo.POST TO nsproportaluser

GO

