SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspIMUpdateIMWEDetail]
     /*******************************************************************************
     * Created By:   CC 03/31/2008 Issue #122980
     * Modified By:  
     *				 
     * This SP updates work table IMWE and IMWENotes
     ********************************************************************************/
     
	(@importid VARCHAR(20), @recordtype VARCHAR(30), @recseq int, @identifier int, 
		@isnote bYN, @uploadval VARCHAR(MAX))
     
	AS
	SET NOCOUNT ON

	IF @isnote = 'N'
		UPDATE IMWE SET UploadVal = LEFT(@uploadval, 60) WHERE ImportId = @importid and RecordType = @recordtype and RecordSeq = @recseq and Identifier = @identifier
	ELSE
		UPDATE IMWENotes SET UploadVal = @uploadval WHERE ImportId = @importid and RecordType = @recordtype and RecordSeq = @recseq and Identifier = @identifier

GO
GRANT EXECUTE ON  [dbo].[vspIMUpdateIMWEDetail] TO [public]
GO
