SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
	Created by: JonathanP - This view is a union between DDQueryableViews and DDFH
	Modified by: RickM - Added AttachmentFormName
*/

CREATE VIEW [dbo].[DDQueryableViewsShared]
AS 

select Form, Title, QueryView, AllowAttachments, 'DD Form Header' as [Form Type], CoColumn as AttachmentCompanyColumn, Form as AttachmentFormName
from DDFHShared
where isnull(QueryView, '') <> '' 

union 

select Form, Title, QueryView, AllowAttachments, 'DD Queryable View' as [Form Type], AttachmentCompanyColumn, isnull(AttachmentFormName, Form) as AttachmentFormName
from DDQueryableViews







GO
GRANT SELECT ON  [dbo].[DDQueryableViewsShared] TO [public]
GRANT INSERT ON  [dbo].[DDQueryableViewsShared] TO [public]
GRANT DELETE ON  [dbo].[DDQueryableViewsShared] TO [public]
GRANT UPDATE ON  [dbo].[DDQueryableViewsShared] TO [public]
GRANT SELECT ON  [dbo].[DDQueryableViewsShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDQueryableViewsShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDQueryableViewsShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDQueryableViewsShared] TO [Viewpoint]
GO
