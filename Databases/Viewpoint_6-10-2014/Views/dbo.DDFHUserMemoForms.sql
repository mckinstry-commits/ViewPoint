SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************************
* Created: ??	
* Modified: DANF 02/23/2005
*			GF 10/18/2006 - issue #122737 added PMIssueHist to excluded forms.
*			JRK 10/18/06 - Radically simplified to utilize new DDFH field AllowCustomFields.
*			JRK 10/10/07 - Restrict UD forms from the view.
*			CC	07/02/09 - #129922 - Added link for form header to culture text
*
*
*	View for the VA UserMemoAdd form.
*
********************************************************/
   
CREATE View [dbo].[DDFHUserMemoForms]
as
SELECT Form, Title, ViewName, TitleID
FROM dbo.DDFHShared (nolock)
WHERE AllowCustomFields = 'Y' 
 and Title is not null 
 and substring(Lower(Form),1,2) <> 'ud'



GO
GRANT SELECT ON  [dbo].[DDFHUserMemoForms] TO [public]
GRANT INSERT ON  [dbo].[DDFHUserMemoForms] TO [public]
GRANT DELETE ON  [dbo].[DDFHUserMemoForms] TO [public]
GRANT UPDATE ON  [dbo].[DDFHUserMemoForms] TO [public]
GRANT SELECT ON  [dbo].[DDFHUserMemoForms] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFHUserMemoForms] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFHUserMemoForms] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFHUserMemoForms] TO [Viewpoint]
GO
