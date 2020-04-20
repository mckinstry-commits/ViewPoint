SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspHQAttachOptionsSave]
   /***********************************************
   	Created: JonathanP 05/09/07	(adapted from bspHQAttachOptionsSave)
   	
	Modified: 
			 JonathanP 05/10/07 - The UseStructForAttYN will always be set to 'N' since it is not used anymore.			 				
			 JonathanP 03/10/08 - Added CreateStandAloneOnDelete, UseAuditing, ArchiveDeletedAttachmentInfo
								  parameters since bHQAO had these columns added.
			 JonathanP 03/28/08 - See #127605. Changed ArchiveDeletedAttachmentInfo to ArchiveDeletedAttachments
			 JonathanP 03/19/09 - See #126134. Now saves the PdfResolution.
			 RickM	   04/16/09 - See #133065. Now saves whether to use the VP Viewer.
			    
   	Usage:	Used to save the Attachment options for HQ into bHQAO. There is no key on
		    this table, and it will only contain a single record, so it cannot save 
			using the standard methods.

	Notes:	In bHQAO there is a TempDirectory column, which will now not be used in 6x. 
			This column will now just be the same as the PermanentDirectory column.

   ***********************************************/
   
   (@savetodatabase bYN, @permdir varchar(255),@coYN bYN, @modYN bYN, @formYN bYN, @monthYN bYN, 
	@customYN bYN, @customstring varchar(255), @scanningfileformat varchar(30), @usejpg bYN, 
	@createStandAloneOnDelete AS CHAR, @useAuditing AS CHAR, @archiveDeletedAttachmentInfo AS CHAR,
	@pdfResolution int, @usevpviewer bYN, @msg varchar(255) output)
   as
   
   declare @rcode int
   select @rcode=0
   
   if exists(select * from bHQAO)
   		update bHQAO Set    	
   			SaveToDatabase = @savetodatabase,
			PermanentDirectory = @permdir,
			TempDirectory = @permdir,
   			ByCompany = @coYN,
   			ByModule = @modYN,
   			ByForm = @formYN,
   			ByMonth = @monthYN,
   			Custom = @customYN,
   			CustomFormat = @customstring,
			ScanningFileFormat = @scanningfileformat,
   			UseJPG = @usejpg,
   			UseStructForAttYN = 'N',
   			CreateStandAloneOnDelete = @createStandAloneOnDelete,
   			UseAuditing = @useAuditing,
   			ArchiveDeletedAttachments = @archiveDeletedAttachmentInfo,
   			PdfResolution = @pdfResolution,
   			UseViewpointViewer = @usevpviewer   			
   else
   		insert bHQAO(TempDirectory,	PermanentDirectory, ByCompany, ByModule, ByForm, ByMonth, Custom, 
   					 CustomFormat, ScanningFileFormat, UseJPG, UseStructForAttYN, CreateStandAloneOnDelete,
   					 UseAuditing, ArchiveDeletedAttachments, PdfResolution, UseViewpointViewer)
		values (@permdir, @permdir, @coYN, @modYN, @formYN, @monthYN, @customYN, @customstring, 
				@scanningfileformat, @usejpg, 'N', @createStandAloneOnDelete, @useAuditing, 
				@archiveDeletedAttachmentInfo, @pdfResolution, @usevpviewer)
	   
   if @@rowcount <> 1
   		select @msg = 'An error ocurred while saving the Attachment Settings.',@rcode = 1
      
   bspexit:
   return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHQAttachOptionsSave] TO [public]
GO
