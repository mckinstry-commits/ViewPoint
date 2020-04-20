SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[vrptPMEstCODist] (@PMCo bCompany, @Project bProject, @ACO varchar(max))

/*****
 CREATED:  DH 5/19/2011
 MODIFIED:
 USAGE:  Used in the PM Estimate Change Order Distribution report called 
		 by PM Interface.  Returns Estimated Change Order Cost, including 
		 Change Order Addons with a phase (these later become cost in JC).
 		 
  INPUTS:  @PMCo,
		   @Project
		   @ACO:  List of ACO's selected from the PM Interface Form
		   Note:  ACO's are string values with lengths of 10 with leading spaces
		          (i.e.          1,           4,          7,)
*******/		   		 

AS

DECLARE  @ACOList varchar(100) --Variable to store string of ACO'
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
SELECT    a.PMCo
		, HQCO.Name as CompanyName
		, a.Project
		, JCJM.Description as JobDescription
		, a.ACO
		, PMOH.Description as ACODescription
		, a.ACOItem
		, a.Phase
		, JCJP.Description as JobPhaseDescription
		, a.CostType
		, a.EstUnits
		, a.UM
		, a.UnitHours
		, a.EstHours
		, a.HourCost
		, a.UnitCost
		, a.ECM,a.EstCost 
      FROM PMOL a
      INNER JOIN #ACOList aco ON
		aco.ACO = a.ACO
	  INNER JOIN HQCO ON
		HQCO.HQCo = a.PMCo
	  INNER JOIN JCJM ON
	    JCJM.JCCo = a.PMCo and
	    JCJM.Job = a.Project
	  INNER JOIN JCJP ON
		JCJP.JCCo = a.PMCo and
		JCJP.Job = a.Project and
		JCJP.PhaseGroup = a.PhaseGroup and
		JCJP.Phase = a.Phase
	  INNER JOIN PMOH ON
		PMOH.PMCo=a.PMCo and
		PMOH.Project=a.Project and
		PMOH.ACO=a.ACO
			
		  	 	
      WHERE 
			a.PMCo=@PMCo and
			a.Project=@Project and
			a.ACO is Not Null and a.SendYN = 'Y'  and a.InterfacedDate is Null 
      
      
      UNION All
      
      /*Return AddOns that become costs, which are assigned to phase/cost types in PMPA*/
      
      SELECT DISTINCT 
			  a.PMCo
			, HQCO.Name
			, a.Project
			, JCJM.Description as JobDescription
			, a.ACO
			, PMOH.Description as ACODescription
			, a.ACOItem
			, c.Phase
			, JCJP.Description as JobPhaseDescription
			, c.CostType
			, 0
			, null
			, 0
			, 0
			, 0
			, 0
			, 'Add On'
			, b.AddOnAmount
      FROM PMOI a
      INNER JOIN #ACOList aco ON
		aco.ACO = a.ACO	
      INNER JOIN PMOA b ON a.PMCo = b.PMCo and a.Project = b.Project 
      	and a.PCO = b.PCO and a.PCOItem = b.PCOItem and a.PCOType = b.PCOType
      INNER JOIN PMPA c ON b.PMCo = c.PMCo and b.Project = c.Project and b.AddOn = c.AddOn
      	and c.Phase Is not null
      INNER JOIN HQCO ON
		HQCO.HQCo = a.PMCo
	  INNER JOIN JCJM ON
	    JCJM.JCCo = a.PMCo and
	    JCJM.Job = a.Project
	  INNER JOIN JCJP ON
		JCJP.JCCo = c.PMCo and
		JCJP.Job = c.Project and
		JCJP.PhaseGroup = c.PhaseGroup and
		JCJP.Phase = c.Phase	
	  INNER JOIN PMOH ON
		PMOH.PMCo=a.PMCo and
		PMOH.Project=a.Project and
		PMOH.ACO=a.ACO	
			
      
     
     WHERE  
		a.PMCo=@PMCo and
		a.Project=@Project and
		b.Status <> 'Y' and c.Phase is not null
GO
GRANT EXECUTE ON  [dbo].[vrptPMEstCODist] TO [public]
GO
