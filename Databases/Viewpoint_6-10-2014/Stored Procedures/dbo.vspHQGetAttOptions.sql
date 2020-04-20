SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      procedure [dbo].[vspHQGetAttOptions]

/**************************************************
*
* Created By:	RT 04/11/05 - #27049
* Modified By:	RM 09/01/05 - Changed to return a dataset rather than all output parameters.
							  Also, removed multiple row check
*				JonathanP 05/08/07 - The ScanningFileFormat column was added to HQAO and is now returned.
*				JonathanP 03/10/08 - Now returns the CreateStandAloneOnDelete, UseAuditing, ArchiveDeletedAttachmentInfo columns
*				JonathanP 03/28/08 - See #127605. Changed ArchiveDeletedAttachmentInfo to ArchiveDeletedAttachments
*				JonathanP 03/19/09 - See #126134. Now returns the pdf resolution.
*				RickM     04/16/09 - See #133065. Now returns the whether to use the Viewpoint Viewer.
*				JonathanP 01/20/10 - See #137397. Now returns database server, database name, and full text search options.
*
* USAGE:
*
* Return the data contained in HQAO.
*
* INPUT PARAMETERS
*
* RETURN PARAMETERS
*    Error Message and
*	 0 for success, or
*    1 for failure
*
*************************************************/

AS

set nocount on


declare @rcode int
select @rcode=0

select Top 1 TempDirectory, 
			 PermanentDirectory, 
			 ByCompany, 
			 ByModule,
			 ByForm,
			 ByMonth,
			 Custom,
			 CustomFormat,
			 UseJPG,
			 UseStructForAttYN,
			 SaveToDatabase,
			 ScanningFileFormat,
			 CreateStandAloneOnDelete,
			 UseAuditing,
			 ArchiveDeletedAttachments,
			 PdfResolution,
			 UseViewpointViewer,
			 AttachmentDatabaseServer,
			 AttachmentDatabaseName
from HQAO

if @@ROWCOUNT <> 1
begin
	select @rcode = 1
end

return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHQGetAttOptions] TO [public]
GO
