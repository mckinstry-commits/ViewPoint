SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE   proc [dbo].[vspPMDocumentSubmittalRevVal]
    /*************************************
    * CREATED BY    :	GP 12/03/2012 - TK-19818
    * LAST MODIFIED :
    * Modified By   :	
    *
    *	Validates submittal and package revisions for PM Transmittal - Documents tab.
    **************************************/
   (@PMCo bCompany, @Project bProject, @DocType bDocType, @Document VARCHAR(10) = NULL,
    @Rev VARCHAR(5) = NULL, @DocumentDesc VARCHAR(60) OUTPUT, @Status VARCHAR(10) OUTPUT,
    @StatusDesc VARCHAR(30) OUTPUT, @msg VARCHAR(255) OUTPUT)
   AS
   SET NOCOUNT ON
    
   DECLARE @rcode INT, @Category VARCHAR(10)
    
   SELECT @rcode = 0
    
   IF @DocType IS NULL
   BEGIN
    	SELECT @msg = 'Missing document type!', @rcode = 1
    	GOTO bspexit
   END
    
   SELECT @Category = DocCategory FROM dbo.PMDT WHERE DocType = @DocType
   IF @@rowcount = 0
   BEGIN
    	SELECT @msg = 'PM Document type ' + isnull(@DocType,'') + ' not on file!', @rcode = 1
    	GOTO bspexit
   END
    
   SELECT @msg='Document not on file!', @rcode=1
   
	IF @Category = 'SBMTL'
	BEGIN
		IF @Rev IS NULL
		BEGIN
			SELECT @DocumentDesc = [Description], @Status = [Status], @rcode = 0
			FROM dbo.PMSubmittal
			WHERE PMCo = @PMCo AND Project = @Project AND DocumentType = @DocType AND SubmittalNumber = @Document
		END
		ELSE
		BEGIN
			SELECT @DocumentDesc = [Description], @Status = [Status], @rcode = 0
			FROM dbo.PMSubmittal
			WHERE PMCo = @PMCo AND Project = @Project AND DocumentType = @DocType AND SubmittalNumber = @Document AND SubmittalRev = @Rev
		END
	END
	
	IF @Category = 'SBMTLPCKG'
	BEGIN
		IF @Rev IS NULL
		BEGIN
			SELECT @DocumentDesc = [Description], @Status = [Status], @rcode = 0
			FROM dbo.PMSubmittalPackage
			WHERE PMCo = @PMCo AND Project = @Project AND Package = @Document
		END
		ELSE
		BEGIN
			SELECT @DocumentDesc = [Description], @Status = [Status], @rcode = 0
			FROM dbo.PMSubmittalPackage
			WHERE PMCo = @PMCo AND Project = @Project AND Package = @Document AND PackageRev = @Rev
		END
	END	
   
   -- get status description from PMSC
   -- Not always necessary to pass in the status.
   IF @Status IS NOT NULL
   BEGIN
		SELECT @StatusDesc = [Description] FROM dbo.PMSC WHERE [Status] = @Status
   END
    
   
   bspexit:
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocumentSubmittalRevVal] TO [public]
GO
