SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[vf_rptPMRelatedDocs]

/*************
 Created:  DH 4/27/2011
 Modified: DH 4/27/2011.  First Document Number and Descriptions added: Project Issues (PMIM)
		   HH 5/11/2011.  Catch expression "len(@IssueNumberText)-1" if @IssueNumberText is an empty string
 Usage:  Used by report views and PM reports to show related documents, this function returns multiple 
		 Document Numbers and Document Descriptions contantenated into single fields (i.e. Issue Numbers:  1, 2, 3).
		 For instance, use the function in a PM Change Order view to show multiple related documents in a single field 
		 for one change order record.  When adding new document types to this function, place similar code within While
		 statement.  When the function is referenced in other report views, pass in the three parameters
		 (@RecTableName, @LinkTableName, @RECID), which are described below.
		 
				 
		 Function is used in the following report views:
		  
 Input Parameters:
	@RecTableName - Main document table (i.e. PMOP - Pending Change Order) from the view in which the function is used.
	@LinkTableName - Related document table (i.e. PMIM - Project Issues) for the documents to be related to the main document.
	@RECID - Key ID of the record from the main document table (i.e. Key ID from PMOP)
	

 Output:  Concatenated fields of Document Numbers and Descriptions related to the main document record.  

***************/		  	    

(
 @RecTableName varchar(30),
 @LinkTableName varchar(30),
 @RECID int
)

/*Related Document Info. Fields storing concatenated document numbers and descriptions.
  Add future document numbers for new document categories to table*/
RETURNS @RelatedDocInfo TABLE

(
 IssueNumbers varchar (200) NULL
 ,IssueAndDescription varchar(max) NULL
 )

AS

BEGIN

	DECLARE @NextRecID int,
			@IssueNumberText varchar (200), --variable storing concatenated issue numbers
			@IssueAndDescText varchar(max) --variable storing concatenated issues number+descriptions
			--Add new document numbers and description variables here

--Initialize variables so that they are not null
	Select @NextRecID = 0, @IssueNumberText = '', @IssueAndDescText=''

/**Loop through each related document and concatenate each document number and/or description into
  variables **/
  
	WHILE @NextRecID is not null
		BEGIN
			Select @NextRecID = min(LINKID) FROM PMRelateRecord 
					Where RecTableName = @RecTableName 
						  and LinkTableName = @LinkTableName
						  and RECID = @RECID
						  and LINKID > @NextRecID

            /**Concatenate Issue Numbers and Descriptions**/						  
			Select @IssueNumberText = @IssueNumberText + Cast(PMIM.Issue as varchar(10))+', ' --tack comma at end of each issue number
				   ,@IssueAndDescText = @IssueAndDescText 
										+ Cast(PMIM.Issue as varchar(10)) + ':  '
										+ isnull(PMIM.Description,'')
										+ CHAR(13) + CHAR(10) --carriage return, line feed after each description
          
					From PMIM
				Where PMIM.KeyID = @NextRecID
				
			/**Add future document info here**/
				
		END	
/**Insert concatenated Doc Numbers and Description Fields into table.  Inserts all characters
   of comma separated text up to the second to last character (when last character assumed to be a comma)
 **/  
	INSERT INTO @RelatedDocInfo (IssueNumbers, IssueAndDescription)
	VALUES (CASE WHEN len(@IssueNumberText) > 0 THEN substring(@IssueNumberText,1,len(@IssueNumberText)-1) ELSE '' END
	
			,@IssueAndDescText )
	
	RETURN

END	 		
GO
GRANT SELECT ON  [dbo].[vf_rptPMRelatedDocs] TO [public]
GO
