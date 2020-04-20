SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[pvPMLookupRFIResponseType]
AS


select 'Reply' as [KeyField], 'Reply' as [TypeDescription]
union
select 'Forward' as [KeyField], 'Forward' as [TypeDescription]
union
select 'Final' as [KeyField], 'Final Response' as [TypeDescription]




GO
GRANT SELECT ON  [dbo].[pvPMLookupRFIResponseType] TO [public]
GRANT INSERT ON  [dbo].[pvPMLookupRFIResponseType] TO [public]
GRANT DELETE ON  [dbo].[pvPMLookupRFIResponseType] TO [public]
GRANT UPDATE ON  [dbo].[pvPMLookupRFIResponseType] TO [public]
GRANT SELECT ON  [dbo].[pvPMLookupRFIResponseType] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPMLookupRFIResponseType] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPMLookupRFIResponseType] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPMLookupRFIResponseType] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPMLookupRFIResponseType] TO [Viewpoint]
GO
