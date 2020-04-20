SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************
  Purpose:  
	Extract craft and class hierarchy template and
	standard data.  This data will be use to report craft and class 
	processing values.
		
  Maintenance Log:
	Coder	Date	Issue#	Description of Change
	CWirtz	1/19/08	125224	New
********************************************************************/
CREATE  view [dbo].[vrvPRCraftClassTemplate] as
--** PRCC  PRTI  Craft Class Template Deductions and Liabilities
SELECT
Rectype = 'PRTD'		
,HeaderGroupName = PRCC.Craft + PRCC.Class + PRTM.Description	
,HeaderGroupTemplate = PRTM.Description  + PRCC.Craft + PRCC.Class	
,HierarchyLevel = 4		-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo	
,Company = HQCO.Name						
,Craft = PRCC.Craft							
,Class = PRCC.Class	
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description
,EEOClass = PRCC.EEOClass						
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CMOTSched = PRCM.OTSched
,CTEffectiveDate = PRCT.EffectiveDate
,OverEffectDate = PRCT.OverEffectDate
,OverOT = PRCT.OverOT
,CTOTSched = PRCT.OTSched
,RecipOpt = PRCT.RecipOpt
,JobCraft = PRCT.JobCraft
,DLType = PRDL.DLType
,DednsLiabsDescription = PRDL.Description  --Deduction Liabiltiy Description
,Method = PRDL.Method
,Template = PRTD.Template					--Template; PRTC.Template or PRCT.Template depending on level
,TemplateDescription = PRTM.Description				--Template Description
,CraftTemplate = PRTD.Template
,CraftClassTemplate = PRTD.Template
,DLCode = PRTD.DLCode						--Deduction Liability Code
,Factor = PRTD.Factor						--Factor
,OldRate = PRTD.OldRate						--OldRate
,NewRate = PRTD.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRTD (Nolock)
		ON PRCC.PRCo = PRTD.PRCo and PRCC.Craft = PRTD.Craft and PRCC.Class = PRTD.Class
Inner Join PRCT (Nolock)
		ON PRTD.PRCo = PRCT.PRCo and PRTD.Craft = PRCT.Craft and PRTD.Template = PRCT.Template
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PRDL (Nolock)
	ON PRTD.PRCo = PRDL.PRCo and PRTD.DLCode = PRDL.DLCode
Inner Join PRTM  (Nolock)
	ON PRTD.PRCo = PRTM.PRCo and PRTD.Template= PRTM.Template
Inner Join HQCO (Nolock)
	ON PRCC.PRCo = HQCO.HQCo


--** PRCC  PRTI  Craft Template Deductions and Liabilities
UNION ALL
SELECT
Rectype = 'PRTI'
,HeaderGroupName = PRCC.Craft + PRCC.Class + PRTM.Description		
,HeaderGroupTemplate = PRTM.Description	+ PRCC.Craft + PRCC.Class															
,HierarchyLevel = 3			-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo	
,Company = HQCO.Name						
,Craft = PRCC.Craft							
,Class = PRCC.Class					
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description		
,EEOClass = PRCC.EEOClass
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CMOTSched = PRCM.OTSched
,CTEffectiveDate = PRCT.EffectiveDate
,OverEffectDate = PRCT.OverEffectDate
,OverOT = PRCT.OverOT
,CTOTSched = PRCT.OTSched
,RecipOpt = PRCT.RecipOpt
,JobCraft = PRCT.JobCraft
,DLType = PRDL.DLType
,DednsLiabsDescription = PRDL.Description  --Deduction Liabiltiy Description
,Method = PRDL.Method
,Template = PRTI.Template					--Template; PRTC.Template or PRCT.Template depending on level
,TemplateDescription = PRTM.Description					--Template Description
,CraftTemplate = PRTI.Template
,CraftClassTemplate = null
,DLCode = PRTI.EDLCode						--Deduction Liability Code
,Factor = PRTI.Factor						--Factor
,OldRate = PRTI.OldRate						--OldRate
,NewRate = PRTI.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRTI (Nolock)
		ON PRCC.PRCo = PRTI.PRCo and PRCC.Craft = PRTI.Craft
Inner Join PRCT (Nolock)
		ON PRTI.PRCo = PRCT.PRCo and PRTI.Craft = PRCT.Craft and PRTI.Template = PRCT.Template
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PRDL (Nolock)
	ON PRTI.PRCo = PRDL.PRCo and PRTI.EDLCode = PRDL.DLCode
Inner Join PRTM  (Nolock)
	ON PRTI.PRCo = PRTM.PRCo and PRTI.Template= PRTM.Template
Inner Join HQCO (Nolock)
	ON PRCC.PRCo = HQCO.HQCo
Where PRTI.EDLType <> 'E'


--** PRCC  PRCD  Craft Class Deductions and Liabilities
UNION ALL
SELECT
Rectype = 'PRCD'	
,HeaderGroupName = PRCC.Craft + PRCC.Class  + ISNULL(Cast(e.Description as varchar),'')		
,HeaderGroupTemplate = ISNULL(Cast(e.Description as varchar),'')	+ PRCC.Craft + PRCC.Class						
,HierarchyLevel = 2			-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo	
,Company = HQCO.Name						
,Craft = PRCC.Craft							
,Class = PRCC.Class
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description		
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CMOTSched = PRCM.OTSched
,CTEffectiveDate = PRCT.EffectiveDate
,OverEffectDate = PRCT.OverEffectDate
,CTOverOT = PRCT.OverOT
,OTSched = PRCT.OTSched
,RecipOpt = PRCT.RecipOpt
,JobCraft = PRCT.JobCraft
,DLType = PRDL.DLType
,DednsLiabsDescription = PRDL.Description  --Deduction Liabiltiy Description
,Method = PRDL.Method
,Template = ISNULL(e.Template,0)			--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = e.Description		--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,DLCode = PRCD.DLCode						--Deduction Liability Code
,Factor = PRCD.Factor						--Factor
,OldRate = PRCD.OldRate						--OldRate
,NewRate = PRCD.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCD (Nolock)
		ON PRCC.PRCo = PRCD.PRCo and PRCC.Craft = PRCD.Craft and PRCC.Class = PRCD.Class
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PRDL (Nolock)
	ON PRCD.PRCo = PRDL.PRCo and PRCD.DLCode = PRDL.DLCode
left outer join
	(select distinct PRCT.Template, PRCT.PRCo,PRCT.Craft,PRTM.Description from PRCT (Nolock)
		Inner Join PRTM (Nolock)
			ON PRCT.PRCo = PRTM.PRCo and PRCT.Template = PRTM.Template
		group by PRCT.Template, PRCT.PRCo,PRCT.Craft,PRTM.Description ) e 
	on PRCC.PRCo = e.PRCo and PRCC.Craft = e.Craft
Left Outer Join PRCT (Nolock)
		ON PRCC.PRCo = PRCT.PRCo and PRCC.Craft = PRCT.Craft and PRCT.Template = e.Template
Inner Join HQCO (Nolock)
	ON PRCC.PRCo = HQCO.HQCo
UNION ALL

--** PRCC  PRCI  Craft Deductions and Liabilities  
--Extract all classes from PRTC to ensure overrides are reported
SELECT
Rectype = 'PRCI'
,HeaderGroupName = PRCC.Craft + PRCC.Class + ISNULL(Cast(PRTM.Description as varchar),'')
,HeaderGroupTemplate = ISNULL(Cast(PRTM.Description as varchar),'')	+ PRCC.Craft + PRCC.Class
,HierarchyLevel = 1			-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo	
,Company = HQCO.Name						
,Craft = PRCC.Craft							
,Class = PRCC.Class	
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description	
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CMOTSched = PRCM.OTSched
,CTEffectiveDate = PRCT.EffectiveDate
,OverEffectDate = PRCT.OverEffectDate
,OverOT = PRCT.OverOT
,CTOTSched = PRCT.OTSched
,RecipOpt = PRCT.RecipOpt
,JobCraft = PRCT.JobCraft
,DLType = PRDL.DLType
,DednsLiabsDescription = PRDL.Description  --Deduction Liabiltiy Description
,Method = PRDL.Method
,Template = PRTC.Template			--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = PRTM.Description					--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,DLCode = PRCI.EDLCode						--Deduction Liability Code
,Factor = PRCI.Factor						--Factor
,OldRate = PRCI.OldRate						--OldRate
,NewRate = PRCI.NewRate						--NewRate

From PRCC   (Nolock)
Inner Join PRCI (Nolock)
		ON PRCC.PRCo = PRCI.PRCo and PRCC.Craft = PRCI.Craft
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PRDL (Nolock)
	ON PRCI.PRCo = PRDL.PRCo and PRCI.EDLCode = PRDL.DLCode
Inner join
	PRTC (Nolock)
		ON PRCC.PRCo = PRTC.PRCo  and PRCC.Craft = PRTC.Craft and PRCC.Class = PRTC.Class
Inner Join PRTM (Nolock)
		ON PRTC.PRCo = PRTM.PRCo and PRTC.Template = PRTM.Template
Inner Join HQCO (Nolock)
	ON PRCC.PRCo = HQCO.HQCo
Inner Join PRCT (Nolock)
	ON PRCI.PRCo = PRCT.PRCo and PRCI.Craft = PRCT.Craft AND PRTC.Template = PRTM.Template

Where PRCI.EDLType <> 'E'

UNION ALL
--** PRCC  PRCI  Craft Deductions and Liabilities  
--Extract Craft template from PRCT when PRTC does not have an associate
--Craft Class Template for an associtated Craft Template. 
SELECT
Rectype = 'PRCICT'
,HeaderGroupName = PRCC.Craft + PRCC.Class + ISNULL(Cast(PRTM.Description as varchar),'')
,HeaderGroupTemplate = ISNULL(Cast(PRTM.Description as varchar),'')	+ PRCC.Craft + PRCC.Class
,HierarchyLevel = 1			-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo	
,Company = HQCO.Name						
,Craft = PRCC.Craft							
,Class = PRCC.Class	
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description	
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CMOTSched = PRCM.OTSched
,CTEffectiveDate = PRCT.EffectiveDate
,OverEffectDate = PRCT.OverEffectDate
,OverOT = PRCT.OverOT
,CTOTSched = PRCT.OTSched
,RecipOpt = PRCT.RecipOpt
,JobCraft = PRCT.JobCraft
,DLType = PRDL.DLType
,DednsLiabsDescription = PRDL.Description  --Deduction Liabiltiy Description
,Method = PRDL.Method
,Template = ISNULL(PRCT.Template,0)			--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = PRTM.Description					--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,DLCode = PRCI.EDLCode						--Deduction Liability Code
,Factor = PRCI.Factor						--Factor
,OldRate = PRCI.OldRate						--OldRate
,NewRate = PRCI.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCI (Nolock)
		ON PRCC.PRCo = PRCI.PRCo and PRCC.Craft = PRCI.Craft
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PRDL (Nolock)
	ON PRCI.PRCo = PRDL.PRCo and PRCI.EDLCode = PRDL.DLCode

Left Outer Join PRCT (Nolock)
		ON PRCC.PRCo = PRCT.PRCo and PRCC.Craft = PRCT.Craft 
			and PRCT.Template  Not IN (select distinct(PRTC.Template) from PRTC)
inner Join PRTM (Nolock)
	ON PRCT.PRCo = PRTM.PRCo and PRCT.Template = PRTM.Template
Inner Join HQCO (Nolock)
	ON PRCC.PRCo = HQCO.HQCo
Where PRCI.EDLType <> 'E'



UNION ALL
--Craft Class Level Only
SELECT
Rectype = 'PRCDCC'	
,HeaderGroupName = PRCC.Craft + PRCC.Class		
,HeaderGroupTemplate = PRCC.Craft + PRCC.Class						
,HierarchyLevel = 2			-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo	
,Company = HQCO.Name						
,Craft = PRCC.Craft							
,Class = PRCC.Class
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description		
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CMOTSched = PRCM.OTSched
,CTEffectiveDate = null
,OverEffectDate = null
,OverOT = null
,CTOTSched = null
,RecipOpt = null
,JobCraft = null
,DLType = PRDL.DLType
,DednsLiabsDescription = PRDL.Description  --Deduction Liabiltiy Description
,Method = PRDL.Method
,Template = 0						--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = null		--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,DLCode = PRCD.DLCode						--Deduction Liability Code
,Factor = PRCD.Factor						--Factor
,OldRate = PRCD.OldRate						--OldRate
,NewRate = PRCD.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCD (Nolock)
		ON PRCC.PRCo = PRCD.PRCo and PRCC.Craft = PRCD.Craft and PRCC.Class = PRCD.Class
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PRDL (Nolock)
	ON PRCD.PRCo = PRDL.PRCo and PRCD.DLCode = PRDL.DLCode
Inner Join HQCO (Nolock)
	ON PRCC.PRCo = HQCO.HQCo

UNION ALL
--Craft Class Level Only
SELECT
Rectype = 'PRCICC'
,HeaderGroupName = PRCC.Craft + PRCC.Class
,HeaderGroupTemplate = PRCC.Craft + PRCC.Class
,HierarchyLevel = 1			-- 4=Craft Class Template, 3=Craft Template, 2=Craft Class, 1=Craft
,PRCo = PRCC.PRCo	
,Company = HQCO.Name						
,Craft = PRCC.Craft							
,Class = PRCC.Class	
,CraftDescription = PRCM.Description
,ClassDescription = PRCC.Description	
,EEOClass = PRCC.EEOClass					
,CMEffectiveDate = PRCM.EffectiveDate	--PRCM.EffectiveDate
,CMOTSched = PRCM.OTSched
,CTEffectiveDate = null
,OverEffectDate = null
,OverOT = null
,CTOTSched = null
,RecipOpt = null
,JobCraft = null
,DLType = PRDL.DLType
,DednsLiabsDescription = PRDL.Description  --Deduction Liabiltiy Description
,Method = PRDL.Method
,Template = 0						--To prevent Crystal from dropping record return 0 rather than NULL
,TemplateDescription = null					--Template Description
,CraftTemplate = null
,CraftClassTemplate = null
,DLCode = PRCI.EDLCode						--Deduction Liability Code
,Factor = PRCI.Factor						--Factor
,OldRate = PRCI.OldRate						--OldRate
,NewRate = PRCI.NewRate						--NewRate

From PRCC   (Nolock)
Left Outer Join PRCI (Nolock)
		ON PRCC.PRCo = PRCI.PRCo and PRCC.Craft = PRCI.Craft
Inner Join PRCM (Nolock)
		ON PRCC.PRCo = PRCM.PRCo and PRCC.Craft = PRCM.Craft
Inner Join PRDL (Nolock)
	ON PRCI.PRCo = PRDL.PRCo and PRCI.EDLCode = PRDL.DLCode
Inner Join HQCO (Nolock)
	ON PRCC.PRCo = HQCO.HQCo
Where PRCI.EDLType <> 'E'

GO
GRANT SELECT ON  [dbo].[vrvPRCraftClassTemplate] TO [public]
GRANT INSERT ON  [dbo].[vrvPRCraftClassTemplate] TO [public]
GRANT DELETE ON  [dbo].[vrvPRCraftClassTemplate] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRCraftClassTemplate] TO [public]
GRANT SELECT ON  [dbo].[vrvPRCraftClassTemplate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPRCraftClassTemplate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPRCraftClassTemplate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPRCraftClassTemplate] TO [Viewpoint]
GO
