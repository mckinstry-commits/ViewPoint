SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMTMDesc Script Date: 08/17/2005 ******/
CREATE PROC [dbo].[vspPMTransmittalAddVal]
/*************************************
 * Created By:	Dan So 06/18/2008 - Issue: 127542 - Check for en existing transmittal and attached documents
 * Modified by: 
 *
 * called from PMTransmittal to return key description.
 *
 *
 * Pass:
 * PMCo				PM Company
 * Project			PM Project
 * Transmittal		PM Transmittal
 * Document Type
 * Document
 * Revision
 *
 *
 * Returns:
 * 
 * Success returns:
 * ================
 * 0 AND
 * @TransExists - YN - does transmittal already exist?
 * @Subject - Subject of existing transmittal
 * @TransDate - Transmittal date of existing transmittal
 * @DateSent - Date sent of existing transmittal
 * @ReqRetDate - Required return date of existing transmittal
 * @RespPerson - Responsible person of existing transmittal
 * @DocAttachedYN - YN - is the document already attached to this transmittal?
 * @msg - depends if the Transmittal exists
 *
 * Error returns:
 * ==============
 * -1 AND
 * @msg - error message
 *  
 **************************************/
   (@pmco bCompany, @project bJob = null, @transmittal bDocument = null, @DocType bDocType = NULL, 
	@Document bDocument = NULL, @Revision INT = NULL,
	@TransExists bYN OUTPUT, @Subject VARCHAR(255) OUTPUT, @TransDate bDate OUTPUT, @DateSent bDate OUTPUT, 
	@ReqRetDate bDate OUTPUT, @RespPerson bEmployee OUTPUT, @DocAttachedYN bYN OUTPUT, 
	@msg VARCHAR(255) OUTPUT)

	AS
	SET NOCOUNT ON

	DECLARE @RowCnt	INT,
			@DocCat	VARCHAR(10),
			@rcode	INT

	------------------
	-- PRIME VALUES --
	------------------
	SET @TransExists = 'N'
	SET @msg = 'New Transmittal'
	SET @DocAttachedYN = 'N'
	SET @rcode = 0

	-------------------------------------
	-- CHECK FOR EXISTING TRANSMMITTAL --
	-------------------------------------
	IF @transmittal IS NOT NULL
		BEGIN
			SELECT	@Subject = Subject, 
					@TransDate = TransDate,
					@DateSent = DateSent,
					@ReqRetDate = DateDue,
					@RespPerson = ResponsiblePerson
			  FROM  PMTM WITH (NOLOCK) 
			 WHERE  PMCo = @pmco 
			   AND  Project = @project 
			   AND  Transmittal = @transmittal

			SET @RowCnt = @@ROWCOUNT
		
			IF @RowCnt > 0 
				BEGIN
					------------------------
					-- TRANSMITTAL EXISTS --
					------------------------
					SET @TransExists = 'Y'
					SET @msg = '*** Existing Transmittal ***'

					-----------------------------------
					-- IS SUBMITTAL ALREADY ATTACHED --
					-----------------------------------
					SELECT @DocCat = DocCategory
					FROM PMDT with (nolock)
					WHERE DocType=@DocType


					-- SUBMIT IS THE ONLY DOCUMENT CATEGORY THAT HAS A REVISION --
					IF @DocCat = 'SUBMIT'
						BEGIN
							IF EXISTS(SELECT TOP 1 1 FROM PMTS with (nolock)
									   WHERE PMCo = @pmco
										 AND Project = @project
										 AND Transmittal = @transmittal
										 AND DocType = @DocType
										 AND Document = @Document
										 AND Rev = @Revision)
								SET @DocAttachedYN = 'Y'
						END
					ELSE
						BEGIN
							IF EXISTS(SELECT TOP 1 1 FROM PMTS with (nolock)
									   WHERE PMCo = @pmco
										 AND Project = @project
										 AND  Transmittal = @transmittal
										 AND DocType = @DocType
										 AND Document = @Document)
								SET @DocAttachedYN = 'Y'
						END
					
				END
		END

vspExit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMTransmittalAddVal] TO [public]
GO
