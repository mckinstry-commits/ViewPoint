SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE       View [dbo].[RQReviewerDistinct]
/***********************************************
*	Created:	DC 04/13/05
*   	Modified:	DC 02/28/06
*
*	Notes:
*    	RQReviewerDistinct is used in RQ Reviewer form
*		to provide a list of reviewers in RQRR and RQQR 
*		that can be reviewed by the user logged in or
*		all reviewers if the user logged in is ViewpointCS
*
*
***************************************************/
as

SELECT DISTINCT r.RQCo, r.Reviewer, v.Name, v.RevEmail
FROM dbo.RQRR r WITH (NOLOCK)
LEFT JOIN dbo.HQRV v WITH (NOLOCK) on v.Reviewer = r.Reviewer
LEFT JOIN dbo.HQRP h WITH (NOLOCK) ON h.Reviewer = r.Reviewer
WHERE h.VPUserName in (SELECT VPUserName FROM dbo.DDUP WITH (NOLOCK) WHERE VPUserName = SUSER_SNAME())
UNION
SELECT DISTINCT q.RQCo, q.Reviewer, v.Name, v.RevEmail
FROM dbo.RQQR q WITH (NOLOCK)
LEFT JOIN dbo.HQRV v WITH (NOLOCK) on v.Reviewer = q.Reviewer
LEFT JOIN dbo.HQRP h WITH (NOLOCK) ON h.Reviewer = q.Reviewer
WHERE h.VPUserName in (SELECT VPUserName FROM dbo.DDUP WITH (NOLOCK) WHERE VPUserName = SUSER_SNAME())
UNION
SELECT DISTINCT r.RQCo, r.Reviewer, h.Name, h.RevEmail
FROM dbo.RQRR r WITH (NOLOCK)
LEFT JOIN dbo.HQRV h WITH (NOLOCK) on h.Reviewer = r.Reviewer
WHERE SUSER_SNAME() = 'viewpointcs'
UNION
SELECT DISTINCT r.RQCo, r.Reviewer, h.Name, h.RevEmail
FROM dbo.RQQR r WITH (NOLOCK)
LEFT JOIN dbo.HQRV h WITH (NOLOCK) on h.Reviewer = r.Reviewer
WHERE SUSER_SNAME() = 'viewpointcs'







GO
GRANT SELECT ON  [dbo].[RQReviewerDistinct] TO [public]
GRANT INSERT ON  [dbo].[RQReviewerDistinct] TO [public]
GRANT DELETE ON  [dbo].[RQReviewerDistinct] TO [public]
GRANT UPDATE ON  [dbo].[RQReviewerDistinct] TO [public]
GRANT SELECT ON  [dbo].[RQReviewerDistinct] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RQReviewerDistinct] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RQReviewerDistinct] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RQReviewerDistinct] TO [Viewpoint]
GO
