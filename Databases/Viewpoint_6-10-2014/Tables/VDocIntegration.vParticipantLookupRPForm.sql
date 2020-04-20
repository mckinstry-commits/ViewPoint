CREATE TABLE [VDocIntegration].[vParticipantLookupRPForm]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[LookupID] [int] NOT NULL,
[Seq] [int] NOT NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ReportID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [VDocIntegration].[vParticipantLookupRPForm] ADD CONSTRAINT [PK_vParticipantLookupRPForm] PRIMARY KEY CLUSTERED  ([LookupID], [Seq], [Form], [ReportID]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
ALTER TABLE [VDocIntegration].[vParticipantLookupRPForm] WITH NOCHECK ADD CONSTRAINT [FK_vParticipantBuilderRPForm_vParticipantLookup] FOREIGN KEY ([LookupID]) REFERENCES [VDocIntegration].[vParticipantLookup] ([LookupID])
GO
ALTER TABLE [VDocIntegration].[vParticipantLookupRPForm] NOCHECK CONSTRAINT [FK_vParticipantBuilderRPForm_vParticipantLookup]
GO
