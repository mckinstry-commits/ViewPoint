SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vrptPMContractCODist] (@PMCo bCompany, @Project bProject, @ACO varchar(max))

/*****
 CREATED:  DH 5/19/2011
 MODIFIED:
 USAGE:  Used in the PM Contract Change Order Distribution report called 
		 by PM Interface.  Returns Contract Change Order Amounts from ACO's
		 selected in PM Interface.
 		 
  INPUTS:  @PMCo
		   @Project
		   @ACO:  String of multiple ACO's separated by commas selected from the PM Interface Form.  
		          Note:  ACO's are string values with lengths of 10 with leading spaces
		          (i.e.          1,           4,          7,)
*******/		   		 

AS

DECLARE   @ACOList varchar(100) --Variable to store string of ACO's
		, @NextACO varchar(10) -- Variable storing each distinct ACO within ACOList
		, @LastPosition int -- Variable to keep track of last position in ACOList for selecting @NextACO
		, @InitLength int -- Variable storing the length of @ACO, subtract one to get length up to last comma.

CREATE TABLE #ACOList

(ACO varchar(10) NULL)

--Set InitLength = 1 so that if @ACO is blank, errors will not occur in substring function
Select @InitLength = 1

--Set InitLength to length of @ACO - 1 (strips comma off end of @ACO)
if isnull(@ACO,'')<>''
	begin
		SELECT @InitLength = len(@ACO)-1
	end	

--ACO list set to @ACO up to the second to last character, which is a comma	
SELECT @ACOList = substring(@ACO,1,@InitLength)

--Initialize last position and get first ACO in list, which is the first 10 characters.
SELECT @LastPosition = 1
SELECT @NextACO = substring(@ACOList,@LastPosition,10)

--Loop through @ACOList and insert @NextACO into #ACOList
WHILE @LastPosition<>0 
	begin
		insert into #ACOList Values (@NextACO)
		select @LastPosition = Charindex(',',@ACOList, @LastPosition+1)	
		select @NextACO = substring(@ACOList,@LastPosition+1,10) 
	end

/*Select final columns for report joined on #ACOList to limit record set */
  
SELECT	  a.PMCo
		, HQCO.Name as CompanyName
		, a.Project
		, JCJM.Description as ProjectDescription
		, a.ACO
		, PMOH.Description as ACODescription
		, a.ACOItem
		, a.Description as ACOItemDescription
		, a.ApprovedDate
		, a.UM
		, a.Units
		, a.UnitPrice
		, a.ApprovedAmt
		, a.ContractItem
		, a.ChangeDays
		     /*Subtract existing contract change amounts for ACO/ACO Items existing in JC */
		, a.ApprovedAmt - isnull(JCOI.ContractAmt,0) as InterfaceChangeAmount  
FROM PMOI a
INNER JOIN #ACOList ON
	#ACOList.ACO = a.ACO
INNER JOIN HQCO ON
	HQCO.HQCo = a.PMCo
INNER JOIN JCJM ON
	JCJM.JCCo = a.PMCo and
	JCJM.Job = a.Project
INNER JOIN PMOH ON
		PMOH.PMCo=a.PMCo and
		PMOH.Project=a.Project and
		PMOH.ACO=a.ACO
LEFT OUTER JOIN JCOI ON
		JCOI.JCCo = a.PMCo and
		JCOI.Job = a.Project and
		JCOI.ACO = a.ACO and
		JCOI.ACOItem = a.ACOItem

WHERE a.PMCo = @PMCo and a.Project=@Project
		

		
				
				
		
GO
GRANT EXECUTE ON  [dbo].[vrptPMContractCODist] TO [public]
GO
