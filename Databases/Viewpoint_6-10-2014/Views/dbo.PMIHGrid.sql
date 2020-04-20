SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************
 * Created By:
 * Modfied By:	GF 02/07/2007 issue #27836 6.x
 *
 * Provides a view of PM Issue History, used
 * in PM Issue History form for grid detail.
 *
 *****************************************/

CREATE view [dbo].[PMIHGrid] as
select a.*, c.MasterIssue,
	'DocCategory' = case when a.ACO is not null then 'ACO' 
						 when a.Action like '%Daily Log%' then 'DAILY'
						 when a.Action like '%Transmittal%' then 'TRANSMIT'
						 when a.Action like '%Punch%' then 'PUNCH'
						 else b.DocCategory end

from PMIH a
left join PMDT b with (nolock) ON b.DocType = a.DocType
left join PMIM c with (nolock) ON c.PMCo = a.PMCo and c.Project = a.Project and c.Issue = a.Issue


GO
GRANT SELECT ON  [dbo].[PMIHGrid] TO [public]
GRANT INSERT ON  [dbo].[PMIHGrid] TO [public]
GRANT DELETE ON  [dbo].[PMIHGrid] TO [public]
GRANT UPDATE ON  [dbo].[PMIHGrid] TO [public]
GRANT SELECT ON  [dbo].[PMIHGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMIHGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMIHGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMIHGrid] TO [Viewpoint]
GO
